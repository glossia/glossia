defmodule Glossia.LinguisticReviews do
  @moduledoc """
  Durable translation questions and explicitly reusable repository guidance.

  A question never keeps a runner alive. Independent items finish, then the
  session waits without a job. The final answer queues one continuation with a
  new launcher identity, retaining the publication branch and validated files.
  Answers are reused only for the identical source and resolved context hash.
  """
  import Ecto.Query

  alias Glossia.{Accounts, Authz, Repo, TranslationSessions}
  alias Glossia.Accounts.{Organization, OrganizationMembership, Project, User}
  alias Glossia.LinguisticReviews.{Participant, Review}
  alias Glossia.Toki
  alias Glossia.Toki.{Conversation, Message}
  alias Glossia.TranslationSessions.{Progress, TranslationSession, TranslateWorker}
  alias Glossia.Translations.Checkpoints

  @locale_scripts Map.new(Cldr.Locale.likely_subtags(), fn {name, tag} ->
                    {String.downcase(to_string(name)),
                     String.downcase(to_string(tag.script || ""))}
                  end)

  def list(user, project, session_id, opts \\ []) do
    with :ok <- authorize(:translation_read, user, project, opts),
         %TranslationSession{} <- TranslationSessions.get_project_session(project, session_id) do
      {:ok,
       Repo.all(
         from r in Review,
           where: r.translation_session_id == ^session_id,
           order_by: [asc: fragment("? != 'open'", r.status), asc: r.inserted_at, asc: r.id],
           preload: [:conversation, :participants, :answered_by],
           limit: 500
       )}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def open_for_session?(session_id),
    do:
      Repo.exists?(
        from r in Review, where: r.translation_session_id == ^session_id and r.status == "open"
      )

  def authorize(action, user, project, opts \\ []) do
    with :ok <- Authz.authorize(action, user, project.account, opts),
         :ok <- Authz.authorize(:project_read, user, project.account) do
      :ok
    end
  end

  def request_on(target, session_id, item, fingerprint, detail) when target != node(),
    do: :erpc.call(target, __MODULE__, :request, [session_id, item, fingerprint, detail], 15_000)

  def request_on(_target, session_id, item, fingerprint, detail),
    do: request(session_id, item, fingerprint, detail)

  def request(session_id, item, fingerprint, detail) do
    Repo.transaction(fn ->
      session = lock_session(session_id)
      if session.status != "running", do: Repo.rollback(:not_active)

      key = [
        translation_session_id: session.id,
        output_path: item.output_path,
        locale: item.locale,
        fingerprint: fingerprint
      ]

      review =
        Repo.get_by(Review, key) ||
          Repo.insert!(%Review{
            translation_session_id: session.id,
            source_path: item.source_path,
            output_path: item.output_path,
            locale: item.locale,
            fingerprint: fingerprint,
            reason: detail.reason,
            question: detail.question,
            source_excerpt: excerpt(detail.source),
            translation_excerpt: excerpt(detail.translation),
            context_targets: item.context_targets
          })

      Toki.ensure_review_conversation(review, session.project_id)
      invite_reviewers(review, Repo.preload(session, project: :account).project)
      review
    end)
  end

  def serialize(review) do
    review = Repo.preload(review, [:conversation, :participants, :answered_by])

    review
    |> Map.take(~w(id translation_session_id status source_path output_path locale question
      source_excerpt translation_excerpt answer guidance context_path resumed_session_id
      resolution_message_id inserted_at)a)
    |> Map.put(:conversation_id, review.conversation && review.conversation.id)
    |> Map.put(:participants, Enum.map(review.participants, &Map.take(&1, [:id, :name])))
    |> Map.put(:answered_by, review.answered_by && Map.take(review.answered_by, [:id, :name]))
  end

  def answer(user, project, session_id, review_id, attrs, opts \\ []) do
    with :ok <- authorize(:translation_write, user, project, opts),
         :ok <- authorize(:translation_read, user, project, opts),
         {:ok, session_id} <- Ecto.UUID.cast(session_id),
         {:ok, review_id} <- Ecto.UUID.cast(review_id) do
      Repo.transaction(fn ->
        Repo.one!(from p in Project, where: p.id == ^project.id, lock: "FOR UPDATE")
        session = lock_session(session_id)

        if is_nil(session) or session.project_id != project.id or
             session.account_id != project.account_id,
           do: Repo.rollback(:not_found)

        review = Repo.get_by(Review, id: review_id, translation_session_id: session.id)
        if is_nil(review), do: Repo.rollback(:not_found)
        changeset = Review.answer_changeset(review, attrs)
        if not changeset.valid?, do: Repo.rollback(changeset)
        {path, digest} = context_target(review, attrs, changeset)
        answer = Ecto.Changeset.get_field(changeset, :answer)
        guidance = Ecto.Changeset.get_field(changeset, :guidance)

        cond do
          review.status == "answered" ->
            if review.answer != answer or review.guidance != guidance or
                 review.context_path != path or
                 review.resolution_message_id != attrs["resolution_message_id"],
               do: Repo.rollback(:already_answered)

            review

          review.status != "open" or session.status not in ["running", "awaiting_input"] ->
            Repo.rollback(:stale)

          true ->
            resolution_message_id = validate_resolution!(review, attrs)

            review =
              changeset
              |> Ecto.Changeset.change(
                status: "answered",
                answered_by_id: user.id,
                context_path: path,
                context_digest: digest,
                resolution_message_id: resolution_message_id
              )
              |> Repo.update!()

            maybe_resume(session)
            Repo.get!(Review, review.id)
        end
      end)
      |> notify_answer(session_id)
    else
      :error -> {:error, :not_found}
      error -> error
    end
  end

  defp validate_resolution!(review, attrs) do
    conversation =
      Repo.one!(
        from c in Conversation, where: c.linguistic_review_id == ^review.id, lock: "FOR UPDATE"
      )

    if conversation.status in ["queued", "running"], do: Repo.rollback(:conversation_busy)

    latest =
      Repo.one(
        from m in Message,
          where: m.conversation_id == ^conversation.id,
          order_by: [desc: m.inserted_at, desc: m.id],
          limit: 1
      )

    case {Ecto.UUID.cast(attrs["resolution_message_id"]), latest} do
      {{:ok, id}, %Message{id: id, role: "assistant", status: "completed", reply_to_id: turn}}
      when not is_nil(turn) ->
        id

      _ ->
        Repo.rollback(:resolution_outdated)
    end
  end

  defp context_target(review, attrs, changeset) do
    if Ecto.Changeset.get_field(changeset, :guidance) do
      case review.context_targets[attrs["context_scope"] || "locale"] do
        %{"path" => path, "digest" => digest} -> {path, digest}
        _ -> Repo.rollback(:invalid_context_scope)
      end
    else
      {nil, nil}
    end
  end

  def pause(session_id) do
    Repo.transaction(fn ->
      session = TranslationSessions.get_session!(session_id)
      Repo.one!(from p in Project, where: p.id == ^session.project_id, lock: "FOR UPDATE")
      session = lock_session(session_id)
      if session.status != "running", do: Repo.rollback(:not_active)
      summary = session.id |> TranslationSessions.session_progress() |> Progress.summary()

      session =
        Repo.update!(
          Ecto.Changeset.change(session,
            status: "awaiting_input",
            translated_content_count: summary.done,
            content_hit_count: summary.skipped
          )
        )

      if open_for_session?(session.id), do: notify_reviewers(session.id)
      maybe_resume(session)
      Repo.get!(TranslationSession, session.id)
    end)
    |> case do
      {:ok, session} ->
        TranslationSessions.broadcast_session_status(session, session.status)
        {:ok, session}

      error ->
        error
    end
  end

  defp maybe_resume(%{status: "awaiting_input"} = session) do
    if not open_for_session?(session.id) do
      existing =
        Repo.one(
          from s in TranslationSession,
            where: s.continued_from_session_id == ^session.id,
            limit: 1
        )

      if is_nil(existing) do
        fields =
          Map.take(session, [
            :account_id,
            :project_id,
            :commit_sha,
            :commit_message,
            :source_language,
            :target_languages,
            :publication_branch,
            :publication_commit_sha,
            :pull_request_url,
            :pull_request_number
          ])

        continuation =
          struct(
            TranslationSession,
            Map.put(fields, :continued_from_session_id, session.id)
          )
          |> Repo.insert!()

        %{session_id: continuation.id} |> TranslateWorker.new() |> Oban.insert!()

        from(r in Review,
          where: r.translation_session_id == ^session.id and r.status == "answered"
        )
        |> Repo.update_all(set: [resumed_session_id: continuation.id])
      end
    end
  end

  defp maybe_resume(_session), do: :ok

  defp notify_answer({:ok, _} = result, session_id) do
    session = TranslationSessions.get_session!(session_id)
    TranslationSessions.broadcast_session_status(session, session.status)
    result
  end

  defp notify_answer(error, _), do: error

  def inputs_on(target, session_id) when target != node(),
    do: :erpc.call(target, __MODULE__, :inputs, [session_id], 15_000)

  def inputs_on(_, session_id), do: inputs(session_id)

  def inputs(session_id), do: lineage_inputs(session_id, 0)
  defp lineage_inputs(_id, 20), do: []
  defp lineage_inputs(nil, _depth), do: []

  defp lineage_inputs(id, depth) do
    case Repo.get(TranslationSession, id) do
      nil ->
        []

      session ->
        reviews =
          Repo.all(
            from r in Review,
              where: r.translation_session_id == ^id and r.status == "answered",
              order_by: [desc: r.updated_at, desc: r.id],
              select:
                map(r, [
                  :id,
                  :output_path,
                  :locale,
                  :fingerprint,
                  :answer,
                  :guidance,
                  :context_path,
                  :context_digest
                ])
          )

        reviews ++ lineage_inputs(session.continued_from_session_id, depth + 1)
    end
  end

  def context_targets(root, item) do
    Map.new(item.context_paths, fn {scope, path} ->
      digest =
        case File.read(Path.join(root, path)) do
          {:ok, content} -> :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
          {:error, :enoent} -> nil
        end

      {scope, %{"path" => path, "digest" => digest}}
    end)
  end

  def fingerprint(hash_state),
    do:
      Checkpoints.key(
        {"linguistic-review-v1", Map.get(hash_state, :review_hash, hash_state.hash)}
      )

  def notify_reviewers(session_id) do
    session = TranslationSessions.get_session!(session_id)
    project = Repo.preload(session.project, :account)

    Repo.all(
      from r in Review, where: r.translation_session_id == ^session.id and r.status == "open"
    )
    |> Enum.each(fn review ->
      invite_reviewers(review, project)

      Enum.each(notification_recipients(review.id), fn user_id ->
        Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
          translation_session_id: session.id,
          review_id: review.id
        })
      end)
    end)

    :ok
  end

  def notification_recipients(review_id) do
    case Repo.get(Review, review_id) do
      %Review{status: "open"} = review ->
        session = TranslationSessions.get_session!(review.translation_session_id)
        project = Repo.preload(session.project, :account)
        review = Repo.preload(review, :participants)

        review.participants
        |> Enum.filter(&eligible?(&1, project, review.locale))
        |> Enum.map(& &1.id)

      _ ->
        []
    end
  end

  def invited?(user, review), do: user.id in notification_recipients(review.id)

  def fluent?(languages, locale) do
    {language, script} = language_parts(locale)

    Enum.any?(languages || [], fn fluent ->
      {known_language, known_script} = language_parts(fluent)

      language == known_language and
        (is_nil(script) or is_nil(known_script) or script == known_script)
    end)
  end

  defp language_parts(locale) do
    locale = locale |> String.replace("_", "-") |> String.downcase()
    [language | subtags] = String.split(locale, "-")
    script = Enum.find(subtags, &(String.length(&1) == 4))

    # A regional declaration (zh-TW) carries its customary script. A broad
    # language declaration (zh) deliberately remains broad rather than silently
    # assigning the default region/script to a person's fluency.
    script =
      script ||
        if(subtags != [],
          do: Map.get(@locale_scripts, locale) || Map.get(@locale_scripts, language)
        )

    {language, script}
  end

  defp eligible?(user, project, locale) do
    fluent?(user.fluent_languages, locale) and
      authorize(:translation_read, user, project) == :ok and
      Toki.authorize_project(:toki_read, user, project) == :ok and
      Toki.authorize_project(:toki_write, user, project) == :ok
  end

  defp invite_reviewers(review, project) do
    session = TranslationSessions.get_session!(review.translation_session_id)
    organization = Repo.get_by(Organization, account_id: session.account_id)

    users =
      if organization do
        Repo.all(
          from m in OrganizationMembership,
            where: m.organization_id == ^organization.id,
            select: m.user_id
        )
      else
        Repo.all(from u in User, where: u.account_id == ^session.account_id, select: u.id)
      end

    Enum.each(users, fn id ->
      user = Accounts.get_user(id)

      if eligible?(user, project, review.locale) do
        now = DateTime.utc_now()

        Repo.insert_all(
          Participant,
          [
            %{
              linguistic_review_id: review.id,
              user_id: id,
              inserted_at: now,
              updated_at: now
            }
          ],
          on_conflict: :nothing
        )
      end
    end)

    :ok
  end

  defp lock_session(id),
    do: Repo.one(from s in TranslationSession, where: s.id == ^id, lock: "FOR UPDATE")

  defp excerpt(text), do: text |> String.to_charlist() |> Enum.take(4_000) |> List.to_string()
end
