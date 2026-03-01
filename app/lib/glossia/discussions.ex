defmodule Glossia.Discussions do
  @moduledoc """
  Context for managing discussions and discussion comments.
  """

  require OpenTelemetry.Tracer, as: Tracer

  import Ecto.Query

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

  def create_discussion(%Account{} = account, %User{} = user, attrs) do
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
          {:ok, discussion}

        {:error, {:validation, changeset}} ->
          {:error, changeset}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def close_discussion(%Discussion{} = discussion, %User{} = user) do
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
    end
  end

  def reopen_discussion(%Discussion{} = discussion) do
    Tracer.with_span "glossia.discussions.reopen_discussion" do
      Tracer.set_attributes([{"glossia.discussion.id", to_string(discussion.id)}])

      discussion
      |> Ecto.Changeset.change(%{
        status: "open",
        closed_at: nil,
        closed_by_id: nil
      })
      |> Repo.update()
    end
  end

  # --- Comments ---

  def add_comment(%Discussion{} = discussion, %User{} = user, attrs) do
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
    end
  end

  def change_discussion(attrs \\ %{}) do
    Discussion.changeset(%Discussion{}, attrs)
  end

  def change_comment(attrs \\ %{}) do
    DiscussionComment.changeset(%DiscussionComment{}, attrs)
  end
end
