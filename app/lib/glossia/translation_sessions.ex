defmodule Glossia.TranslationSessions do
  @moduledoc """
  Context for managing translation sessions.
  """

  import Ecto.Query

  require Logger

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

  def get_session!(%Account{id: account_id}, %Project{id: project_id}, id) do
    Repo.one!(
      from(s in TranslationSession,
        where:
          s.id == ^id and s.account_id == ^account_id and
            s.project_id == ^project_id,
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
    now = DateTime.utc_now()

    changes =
      case status do
        "pending" ->
          %{
            status: status,
            started_at: nil,
            completed_at: nil,
            error: nil,
            summary: nil
          }

        "running" ->
          %{
            status: status,
            started_at: now,
            completed_at: nil,
            error: nil,
            summary: nil
          }

        "completed" ->
          %{status: status, completed_at: now, error: nil}

        "failed" ->
          %{status: status, completed_at: now, summary: nil}

        "cancelled" ->
          %{status: status, completed_at: now, error: nil, summary: nil}

        _ ->
          %{status: status}
      end

    changes =
      if Keyword.has_key?(opts, :error),
        do: Map.put(changes, :error, opts[:error]),
        else: changes

    changes =
      if Keyword.has_key?(opts, :summary),
        do: Map.put(changes, :summary, opts[:summary]),
        else: changes

    session
    |> Ecto.Changeset.change(changes)
    |> Repo.update()
    |> case do
      {:ok, updated_session} ->
        broadcast_session_status(updated_session, status)
        {:ok, updated_session}

      error ->
        error
    end
  end

  def cancel_session(%TranslationSession{status: status} = session)
      when status in ["pending", "running"] do
    session_id = to_string(session.id)

    jobs =
      from(job in Oban.Job,
        where: job.worker == ^to_string(Glossia.TranslationSessions.TranslateWorker),
        where: job.state in ["available", "scheduled", "executing", "retryable"],
        where: fragment("?->>'session_id' = ?", job.args, ^session_id)
      )

    with {:ok, _count} <- Oban.cancel_all_jobs(jobs) do
      update_session_status(session, "cancelled")
    end
  end

  def cancel_session(%TranslationSession{}), do: {:error, :not_cancellable}

  def update_session_publication(%TranslationSession{} = session, attrs) do
    session
    |> Ecto.Changeset.change(
      Map.take(attrs, [:publication_branch, :publication_commit_sha, :pull_request_url])
    )
    |> Repo.update()
    |> case do
      {:ok, updated_session} ->
        Phoenix.PubSub.broadcast(
          Glossia.PubSub,
          "translation_session:#{updated_session.id}",
          {:translation_session_publication, updated_session}
        )

        {:ok, updated_session}

      error ->
        error
    end
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

  def broadcast_session_event(%TranslationSession{} = session, event, target_node)
      when is_atom(target_node) do
    case :rpc.call(
           target_node,
           __MODULE__,
           :broadcast_session_event,
           [session, event],
           5_000
         ) do
      :ok ->
        :ok

      {:badrpc, reason} ->
        Logger.warning("Could not relay translation progress to the parent node",
          translation_session_id: session.id,
          reason: inspect(reason)
        )

        :ok
    end
  end

  def broadcast_session_status(%TranslationSession{id: id}, status) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translation_session:#{id}",
      {:translation_session_status, status}
    )
  end
end
