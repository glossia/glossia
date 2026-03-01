defmodule Glossia.TranslationSessions do
  @moduledoc """
  Context for managing translation sessions.
  """

  import Ecto.Query

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, Project}
  alias Glossia.TranslationSessions.TranslationSession

  def list_project_sessions(%Project{} = project, params \\ %{}) do
    from(s in TranslationSession, where: s.project_id == ^project.id)
    |> Flop.validate_and_run(params, for: TranslationSession)
  end

  def sessions_by_commit_sha(%Project{} = project) do
    from(s in TranslationSession,
      where: s.project_id == ^project.id,
      where: not is_nil(s.commit_sha),
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.commit_sha)
  end

  def get_session!(id) do
    Repo.one!(
      from(s in TranslationSession,
        where: s.id == ^id,
        preload: [:project, :account]
      )
    )
  end

  def get_session(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, cast_id} ->
        Repo.one(
          from(s in TranslationSession,
            where: s.id == ^cast_id,
            preload: [:project, :account]
          )
        )

      :error ->
        nil
    end
  end

  def get_session(_), do: nil

  def create_session(%Account{} = account, %Project{} = project, attrs) do
    %TranslationSession{account_id: account.id, project_id: project.id}
    |> TranslationSession.changeset(attrs)
    |> Repo.insert()
  end

  def update_session_status(%TranslationSession{} = session, status, opts \\ []) do
    changes = %{status: status}

    changes =
      if status == "running",
        do: Map.put(changes, :started_at, DateTime.utc_now()),
        else: changes

    changes =
      if status in ["completed", "failed"],
        do: Map.put(changes, :completed_at, DateTime.utc_now()),
        else: changes

    changes =
      if opts[:error],
        do: Map.put(changes, :error, opts[:error]),
        else: changes

    changes =
      if opts[:summary],
        do: Map.put(changes, :summary, opts[:summary]),
        else: changes

    session
    |> Ecto.Changeset.change(changes)
    |> Repo.update()
  end

  def subscribe_session_events(%TranslationSession{id: id}) do
    Phoenix.PubSub.subscribe(Glossia.PubSub, "translation_session:#{id}")
  end

  def broadcast_session_event(%TranslationSession{id: id}, event) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translation_session:#{id}",
      {:translation_session_event, event}
    )
  end
end
