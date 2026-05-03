defmodule Glossia.Discussions do
  @moduledoc """
  Context for managing discussions and discussion comments.
  """

  require OpenTelemetry.Tracer, as: Tracer

  import Ecto.Query

  alias Glossia.Events
  alias Glossia.Repo
  alias Glossia.Accounts.{Account, Project, User}
  alias Glossia.Discussions.{Discussion, DiscussionComment}

  @discussion_preloads [
    [user: :account],
    :account,
    :project,
    :closed_by,
    comments: [user: :account]
  ]

  # --- Discussions ---

  def list_discussions(%Account{} = account, params \\ %{}) do
    query =
      from t in Discussion,
        where: t.account_id == ^account.id,
        preload: [user: :account]

    Flop.validate_and_run(query, params, for: Discussion)
  end

  def list_discussions(%Account{} = account, %Project{} = project, params) do
    query =
      from t in Discussion,
        where: t.account_id == ^account.id and t.project_id == ^project.id,
        preload: [user: :account]

    Flop.validate_and_run(query, params, for: Discussion)
  end

  def list_all_discussions(params \\ %{}) do
    query =
      from t in Discussion,
        preload: [:account, user: :account]

    Flop.validate_and_run(query, params, for: Discussion)
  end

  def get_discussion!(id) do
    Repo.one!(
      from t in Discussion,
        where: t.id == ^id,
        preload: ^@discussion_preloads
    )
  end

  def get_discussion(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, cast_id} ->
        Repo.one(
          from t in Discussion,
            where: t.id == ^cast_id,
            preload: ^@discussion_preloads
        )

      :error ->
        nil
    end
  end

  def get_discussion(_id), do: nil

  def get_discussion!(id, account_id) do
    Repo.one!(
      from t in Discussion,
        where: t.id == ^id and t.account_id == ^account_id,
        preload: ^@discussion_preloads
    )
  end

  def get_discussion_by_number!(number, account_id) do
    Repo.one!(
      from t in Discussion,
        where: t.number == ^number and t.account_id == ^account_id,
        preload: ^@discussion_preloads
    )
  end

  def create_discussion(%Account{} = account, %User{} = user, attrs, opts \\ []) do
    Tracer.with_span "glossia.discussions.create_discussion" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.user.id", to_string(user.id)}
      ])

      Repo.transaction(fn ->
        # Serialize discussion-number assignment per account to avoid duplicate numbers
        # under concurrent discussion creation.
        Repo.one!(
          from a in Account,
            where: a.id == ^account.id,
            select: a.id,
            lock: "FOR UPDATE"
        )

        next_number =
          (Repo.one(
             from t in Discussion, where: t.account_id == ^account.id, select: max(t.number)
           ) ||
             0) + 1

        %Discussion{}
        |> Discussion.changeset(attrs)
        |> Ecto.Changeset.put_change(:account_id, account.id)
        |> Ecto.Changeset.put_change(:user_id, user.id)
        |> Ecto.Changeset.put_change(:number, next_number)
        |> Repo.insert()
        |> case do
          {:ok, discussion} ->
            discussion

          {:error, changeset} ->
            Repo.rollback({:validation, changeset})
        end
      end)
      |> case do
        {:ok, discussion} ->
          Tracer.set_attributes([{"glossia.discussion.number", discussion.number}])

          {event_name, summary} = discussion_event_metadata(discussion, attrs)

          Events.emit(event_name, account, user,
            resource_type: "discussion",
            resource_id: to_string(discussion.id),
            resource_path: "/#{account.handle}/-/discussions/#{discussion.number}",
            summary: summary,
            via: Keyword.get(opts, :via)
          )

          {:ok, discussion}

        {:error, {:validation, changeset}} ->
          {:error, changeset}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def close_discussion(%Discussion{} = discussion, %User{} = user, opts \\ []) do
    Tracer.with_span "glossia.discussions.close_discussion" do
      Tracer.set_attributes([
        {"glossia.discussion.id", to_string(discussion.id)},
        {"glossia.user.id", to_string(user.id)}
      ])

      discussion
      |> Ecto.Changeset.change(%{
        status: "closed",
        closed_at: DateTime.utc_now(),
        closed_by_id: user.id
      })
      |> Repo.update()
      |> case do
        {:ok, updated} = ok ->
          account = discussion_account(updated)

          Events.emit("discussion.closed", account, user,
            resource_type: "discussion",
            resource_id: to_string(updated.id),
            resource_path: "/#{account.handle}/-/discussions/#{updated.number}",
            summary: "Closed discussion \"#{updated.title}\"",
            via: Keyword.get(opts, :via)
          )

          ok

        other ->
          other
      end
    end
  end

  def reopen_discussion(%Discussion{} = discussion, %User{} = user, opts \\ []) do
    Tracer.with_span "glossia.discussions.reopen_discussion" do
      Tracer.set_attributes([{"glossia.discussion.id", to_string(discussion.id)}])

      discussion
      |> Ecto.Changeset.change(%{
        status: "open",
        closed_at: nil,
        closed_by_id: nil
      })
      |> Repo.update()
      |> case do
        {:ok, updated} = ok ->
          account = discussion_account(updated)

          Events.emit("discussion.reopened", account, user,
            resource_type: "discussion",
            resource_id: to_string(updated.id),
            resource_path: "/#{account.handle}/-/discussions/#{updated.number}",
            summary: "Reopened discussion \"#{updated.title}\"",
            via: Keyword.get(opts, :via)
          )

          ok

        other ->
          other
      end
    end
  end

  # --- Comments ---

  def add_comment(%Discussion{} = discussion, %User{} = user, attrs, opts \\ []) do
    Tracer.with_span "glossia.discussions.add_comment" do
      Tracer.set_attributes([
        {"glossia.discussion.id", to_string(discussion.id)},
        {"glossia.user.id", to_string(user.id)}
      ])

      %DiscussionComment{}
      |> DiscussionComment.changeset(attrs)
      |> Ecto.Changeset.put_change(:discussion_id, discussion.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Repo.insert()
      |> case do
        {:ok, _comment} = ok ->
          account = discussion_account(discussion)

          Events.emit("discussion.commented", account, user,
            resource_type: "discussion",
            resource_id: to_string(discussion.id),
            resource_path: "/#{account.handle}/-/discussions/#{discussion.number}",
            summary: "Commented on discussion \"#{discussion.title}\"",
            via: Keyword.get(opts, :via)
          )

          ok

        other ->
          other
      end
    end
  end

  def mark_suggestion_applied(
        %Discussion{} = discussion,
        %User{} = user,
        kind,
        version,
        opts \\ []
      )
      when kind in [:voice, :glossary] do
    account = discussion_account(discussion)

    maybe_close_discussion(discussion, user, opts)

    _ =
      add_comment(discussion, user, %{body: applied_comment(kind, version)},
        via: Keyword.get(opts, :via)
      )

    Events.emit("#{kind}.suggestion.applied", account, user,
      resource_type: "discussion",
      resource_id: to_string(discussion.id),
      resource_path: "/#{account.handle}/-/discussions/#{discussion.number}",
      summary: "Applied #{kind} suggestion ##{discussion.number} as version ##{version}",
      via: Keyword.get(opts, :via)
    )

    :ok
  end

  defp discussion_event_metadata(discussion, attrs) do
    case attrs[:kind] || attrs["kind"] do
      "voice_suggestion" ->
        {"voice.suggested", attrs[:title] || attrs["title"] || discussion.title}

      "glossary_suggestion" ->
        metadata = attrs[:metadata] || attrs["metadata"] || %{}

        {"glossary.suggested",
         metadata["change_note"] || attrs[:title] || attrs["title"] || discussion.title}

      _ ->
        {"discussion.created", "Created discussion \"#{discussion.title}\""}
    end
  end

  defp discussion_account(%Discussion{account: %Account{} = account}), do: account
  defp discussion_account(%Discussion{account_id: account_id}), do: Repo.get!(Account, account_id)

  defp maybe_close_discussion(%{status: "open"} = discussion, user, opts) do
    _ = close_discussion(discussion, user, opts)
    :ok
  end

  defp maybe_close_discussion(_discussion, _user, _opts), do: :ok

  defp applied_comment(:voice, version),
    do:
      Gettext.gettext(GlossiaWeb.Gettext, "Applied this suggestion as voice version #%{version}.",
        version: version
      )

  defp applied_comment(:glossary, version),
    do:
      Gettext.gettext(
        GlossiaWeb.Gettext,
        "Applied this suggestion as glossary version #%{version}.",
        version: version
      )

  def change_discussion(attrs \\ %{}) do
    Discussion.changeset(%Discussion{}, attrs)
  end

  def change_comment(attrs \\ %{}) do
    DiscussionComment.changeset(%DiscussionComment{}, attrs)
  end
end
