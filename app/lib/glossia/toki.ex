defmodule Glossia.Toki do
  @moduledoc """
  Private companion chats and shared, goal-driven linguistic conversations.
  Requests only persist work;
  Oban performs inference. A durable message claim permits at most one model
  attempt, including after client retries or job redelivery. Interrupted work
  fails rather than risking a second billable inference.
  """
  import Ecto.Query

  alias Glossia.Accounts.User
  alias Glossia.Authz
  alias Glossia.LinguisticReviews
  alias Glossia.LinguisticReviews.Review
  alias Glossia.Repo
  alias Glossia.Toki.{Conversation, Message, ReplyWorker}
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession

  def authorize_project(action, user, project, opts \\ []) do
    with :ok <- Authz.authorize(action, user, project.account, opts),
         :ok <- Authz.authorize(:project_read, user, project.account) do
      :ok
    end
  end

  def list_conversations(user, project, params \\ %{}, opts \\ []) do
    with :ok <- authorize_project(:toki_read, user, project, opts) do
      scoped_conversations(user, project)
      |> visible_sources(user, project, opts)
      |> Flop.validate_and_run(params, for: Conversation)
    end
  end

  def get_conversation(user, project, id, opts \\ []) do
    with :ok <- authorize_project(:toki_read, user, project, opts),
         {:ok, id} <- cast_id(id),
         %Conversation{} = conversation <- Repo.get(scoped_conversations(user, project), id),
         {:ok, _source} <- conversation_source(user, project, conversation, opts) do
      {:ok, detail(conversation)}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def create_conversation(user, project, attrs, opts \\ []) do
    with :ok <- authorize_project(:toki_write, user, project, opts),
         {:ok, id} <- cast_id(attrs["id"]),
         {:ok, origin_id} <- cast_origin_id(attrs["translation_session_id"]) do
      Repo.transaction(fn ->
        lock_user(user)

        case Repo.get(Conversation, id) do
          %Conversation{user_id: user_id, project_id: project_id} = conversation
          when user_id == user.id and project_id == project.id ->
            if conversation.translation_session_id != origin_id,
              do: Repo.rollback(:id_conflict)

            source_or_rollback(user, project, conversation, opts)
            detail(conversation)

          nil ->
            private = where(scoped_conversations(user, project), [c], c.user_id == ^user.id)

            if Repo.aggregate(private, :count) >= 100,
              do: Repo.rollback(:conversation_limit)

            conversation = %Conversation{
              user_id: user.id,
              project_id: project.id,
              translation_session_id: origin_id
            }

            source_or_rollback(user, project, conversation, opts)

            conversation
            |> Conversation.changeset(%{"id" => id})
            |> insert_or_rollback()
            |> detail()

          _ ->
            Repo.rollback(:id_conflict)
        end
      end)
    end
  end

  def send_message(user, project, conversation_id, attrs, opts \\ []) do
    with :ok <- authorize_project(:toki_write, user, project, opts),
         {:ok, conversation_id} <- cast_id(conversation_id),
         {:ok, message_id} <- cast_id(attrs["id"]) do
      Repo.transaction(fn ->
        # Serializes limits across all of a user's conversations, then locks
        # the conversation so two distinct requests cannot start parallel turns.
        lock_user(user)

        conversation =
          scoped_conversations(user, project)
          |> where(id: ^conversation_id)
          |> lock("FOR UPDATE")
          |> Repo.one()

        if is_nil(conversation), do: Repo.rollback(:not_found)
        source_or_rollback(user, project, conversation, opts)

        changeset =
          Message.changeset(
            %Message{
              conversation_id: conversation.id,
              user_id: user.id,
              role: "user",
              status: "queued"
            },
            Map.put(attrs, "id", message_id)
          )

        if not changeset.valid?, do: Repo.rollback(changeset)

        case Repo.get(Message, message_id) do
          %Message{conversation_id: id, user_id: author, role: "user", content: content}
          when id == conversation.id and (author == user.id or is_nil(author)) ->
            if content != Ecto.Changeset.get_field(changeset, :content),
              do: Repo.rollback(:id_conflict)

            detail(conversation)

          nil ->
            if not open?(conversation), do: Repo.rollback(:goal_closed)
            enqueue_message(user, conversation, changeset, opts)

          _ ->
            Repo.rollback(:id_conflict)
        end
      end)
    end
  end

  @doc """
  Resolves summary-level provenance, never segment text. Source-linked histories
  fail closed without current translation and project read authorization, even
  on retries, because earlier assistant messages may contain source material.
  """
  def conversation_source(user, project, conversation, opts \\ []) do
    shared = not is_nil(conversation.linguistic_review_id)

    accessible =
      if shared,
        do: authorize_project(:toki_write, user, project) == :ok,
        else: conversation.user_id == user.id

    if accessible and conversation.project_id == project.id do
      case conversation.translation_session_id do
        nil ->
          {:ok, nil}

        id ->
          with :ok <- authorize_project(:translation_read, user, project, opts) do
            case TranslationSessions.get_project_session(project, id) do
              nil ->
                {:error, :not_found}

              session ->
                if not shared or
                     Repo.exists?(
                       from r in Review,
                         where:
                           r.id == ^conversation.linguistic_review_id and
                             r.translation_session_id == ^session.id
                     ),
                   do: {:ok, session},
                   else: {:error, :not_found}
            end
          end
      end
    else
      {:error, :not_found}
    end
  end

  defp source_or_rollback(user, project, conversation, opts) do
    case conversation_source(user, project, conversation, opts) do
      {:ok, _source} -> :ok
      {:error, :insufficient_scope, scope} -> Repo.rollback({:insufficient_scope, scope})
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp visible_sources(query, user, project, opts) do
    query =
      if authorize_project(:toki_write, user, project) == :ok,
        do: query,
        else: where(query, [c], is_nil(c.linguistic_review_id))

    if authorize_project(:translation_read, user, project, opts) == :ok do
      from c in query,
        left_join: s in TranslationSession,
        on:
          s.id == c.translation_session_id and s.project_id == ^project.id and
            s.account_id == ^project.account_id,
        where: is_nil(c.translation_session_id) or not is_nil(s.id)
    else
      where(query, [c], is_nil(c.translation_session_id))
    end
  end

  def detail(conversation) do
    messages =
      Message
      |> where(conversation_id: ^conversation.id)
      |> order_by([m], asc: m.inserted_at, asc: m.id)
      |> limit(100)
      |> preload(:user)
      |> Repo.all()

    conversation = Repo.preload(conversation, linguistic_review: [:conversation, :participants])
    %{conversation: conversation, messages: messages}
  end

  def ensure_review_conversation(review, project_id) do
    Repo.get_by(Conversation, linguistic_review_id: review.id) ||
      then(
        Repo.insert!(%Conversation{
          project_id: project_id,
          linguistic_review_id: review.id,
          translation_session_id: review.translation_session_id,
          title: String.slice(review.question, 0, 80)
        }),
        fn conversation ->
          Repo.insert!(%Message{
            conversation_id: conversation.id,
            role: "assistant",
            status: "completed",
            content: review.question
          })

          conversation
        end
      )
  end

  def open?(%Conversation{linguistic_review_id: nil}), do: true

  def open?(conversation),
    do:
      Repo.exists?(
        from r in Review, where: r.id == ^conversation.linguistic_review_id and r.status == "open"
      )

  def expire_interrupted_replies do
    now = DateTime.utc_now()
    running_cutoff = DateTime.add(now, -120, :second)
    queued_cutoff = DateTime.add(now, -900, :second)

    Message
    |> where(
      [m],
      (m.status == "running" and m.updated_at < ^running_cutoff) or
        (m.status == "queued" and m.updated_at < ^queued_cutoff)
    )
    |> order_by(asc: :updated_at, asc: :id)
    |> limit(100)
    |> Repo.all()
    |> Enum.each(fn message ->
      Repo.transaction(fn ->
        conversation =
          Repo.one!(
            from c in Conversation, where: c.id == ^message.conversation_id, lock: "FOR UPDATE"
          )

        # A queued job may have claimed its message since the recovery query.
        # Recheck under the same lock as claim/finish before expiring it.
        message = Repo.get!(Message, message.id)

        interrupted? =
          (message.status == "running" and
             DateTime.compare(message.updated_at, running_cutoff) == :lt) or
            (message.status == "queued" and
               DateTime.compare(message.updated_at, queued_cutoff) == :lt)

        if interrupted? do
          Repo.update!(Ecto.Changeset.change(message, status: "failed"))

          Repo.update!(
            Ecto.Changeset.change(conversation, status: "failed", error: "inference_interrupted")
          )
        end
      end)
    end)

    :ok
  end

  def claim(message_id) do
    Repo.transaction(fn ->
      message = Repo.get!(Message, message_id)
      conversation = Repo.get!(Conversation, message.conversation_id)
      Repo.one!(from c in Conversation, where: c.id == ^conversation.id, lock: "FOR UPDATE")
      message = Repo.get!(Message, message_id)

      if message.status != "queued", do: Repo.rollback(:already_claimed)

      Repo.update!(Ecto.Changeset.change(conversation, status: "running"))
      Repo.update!(Ecto.Changeset.change(message, status: "running"))
    end)
  end

  def finish(message, result) do
    Repo.transaction(fn ->
      conversation =
        Repo.one!(
          from c in Conversation, where: c.id == ^message.conversation_id, lock: "FOR UPDATE"
        )

      message = Repo.get!(Message, message.id)
      if message.status != "running", do: Repo.rollback(:already_finished)

      {status, error} =
        case result do
          {:ok, text} ->
            %Message{
              conversation_id: conversation.id,
              reply_to_id: message.id,
              role: "assistant",
              content: text,
              status: "completed"
            }
            |> Repo.insert!()

            {"completed", nil}

          {:error, error} ->
            {"failed", error}
        end

      Repo.update!(Ecto.Changeset.change(message, status: status))
      updated = Repo.update!(Ecto.Changeset.change(conversation, status: status, error: error))

      if status == "completed" do
        recipients =
          if conversation.linguistic_review_id,
            do: LinguisticReviews.notification_recipients(conversation.linguistic_review_id),
            else: [conversation.user_id]

        Enum.each(recipients, fn user_id ->
          Glossia.Push.notify_user(user_id, "toki_completed", %{
            conversation_id: conversation.id,
            message_id: message.id
          })
        end)
      end

      updated
    end)
  end

  defp enqueue_message(user, conversation, changeset, opts) do
    if conversation.status in ["queued", "running"], do: Repo.rollback(:conversation_busy)

    count =
      Repo.aggregate(from(m in Message, where: m.conversation_id == ^conversation.id), :count)

    if count >= 99, do: Repo.rollback(:message_limit)

    active =
      Repo.aggregate(
        from(m in Message,
          join: c in Conversation,
          on: c.id == m.conversation_id,
          where:
            m.role == "user" and m.status in ["queued", "running"] and
              (m.user_id == ^user.id or c.user_id == ^user.id)
        ),
        :count
      )

    if active >= 5, do: Repo.rollback(:too_many_pending)

    case Glossia.RateLimiter.hit("toki:user:#{user.id}", :timer.hours(1), 30) do
      {:allow, _} -> :ok
      {:deny, _} -> Repo.rollback(:rate_limited)
    end

    message = insert_or_rollback(changeset)

    title =
      if count == 0,
        do: String.slice(message.content, 0, 80),
        else: conversation.title

    conversation =
      Repo.update!(
        Ecto.Changeset.change(conversation, status: "queued", error: nil, title: title)
      )

    %{
      "message_id" => message.id,
      "scopes" => Keyword.get(opts, :scopes, Authz.available_scopes())
    }
    |> ReplyWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, _job} -> detail(conversation)
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp scoped_conversations(user, project),
    do:
      from(c in Conversation,
        where:
          c.project_id == ^project.id and
            (c.user_id == ^user.id or not is_nil(c.linguistic_review_id)),
        preload: [linguistic_review: [:conversation, :participants]]
      )

  defp lock_user(user),
    do: Repo.one!(from u in User, where: u.id == ^user.id, lock: "FOR UPDATE")

  defp insert_or_rollback(changeset) do
    case Repo.insert(changeset) do
      {:ok, record} -> record
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp cast_id(value) do
    case Ecto.UUID.cast(value) do
      {:ok, id} when not is_nil(id) -> {:ok, id}
      _ -> {:error, :invalid_id}
    end
  end

  defp cast_origin_id(nil), do: {:ok, nil}
  defp cast_origin_id(value), do: cast_id(value)
end
