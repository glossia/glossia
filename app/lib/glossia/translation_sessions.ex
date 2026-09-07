defmodule Glossia.TranslationSessions do
  @moduledoc """
  Context for managing translation sessions.
  """

  import Ecto.Query

  require Logger

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, Project}
  alias Glossia.TranslationSessions.Progress
  alias Glossia.TranslationSessions.ProgressEvent
  alias Glossia.TranslationSessions.Translate
  alias Glossia.TranslationSessions.TranslationSession

  # A translation heartbeats after each file, and one file on a reasoning model
  # can take several minutes, so the running cutoff has to clear the slowest
  # single file by a wide margin. A pending session is waiting for its Job's pod
  # to be scheduled, pull the image and boot, which is normally a minute or two
  # but can be much longer when the cluster is short on capacity — the cutoff is
  # generous enough that reaping one means something is genuinely wrong.
  @stale_running_session_seconds 45 * 60
  @stale_pending_session_seconds 30 * 60

  def list_project_sessions(%Project{} = project, params \\ %{}) do
    from(s in TranslationSession, where: s.project_id == ^project.id)
    |> Flop.validate_and_run(params, for: TranslationSession)
  end

  def list_project_sessions(%Project{} = project, search, params) do
    pattern = "%#{escape_like_pattern(search)}%"

    query =
      from(s in TranslationSession,
        where: s.project_id == ^project.id,
        where:
          ilike(s.commit_sha, ^pattern) or
            ilike(s.commit_message, ^pattern)
      )

    Flop.validate_and_run(query, params, for: TranslationSession)
  end

  def project_overview(%Project{} = project, days \\ 14) do
    today = Date.utc_today()
    first_day = Date.add(today, -(days - 1))
    first_moment = DateTime.new!(first_day, ~T[00:00:00], "Etc/UTC")

    totals =
      from(s in TranslationSession,
        where: s.project_id == ^project.id and s.inserted_at >= ^first_moment,
        select: %{
          runs: count(s.id),
          content_misses: coalesce(sum(s.translated_content_count), 0),
          content_hits: coalesce(sum(s.content_hit_count), 0)
        }
      )
      |> Repo.one!()

    daily_content =
      from(s in TranslationSession,
        where: s.project_id == ^project.id and s.inserted_at >= ^first_moment,
        group_by: fragment("date(?)", s.inserted_at),
        select:
          {fragment("date(?)", s.inserted_at),
           %{
             hits: coalesce(sum(s.content_hit_count), 0),
             misses: coalesce(sum(s.translated_content_count), 0)
           }}
      )
      |> Repo.all()
      |> Map.new()

    days =
      for offset <- 0..(days - 1) do
        date = Date.add(first_day, offset)
        Map.merge(%{date: date, hits: 0, misses: 0}, Map.get(daily_content, date, %{}))
      end

    checked_content = totals.content_hits + totals.content_misses

    hit_rate =
      if checked_content == 0,
        do: 0.0,
        else: Float.round(totals.content_hits * 100 / checked_content, 1)

    totals
    |> Map.put(:hit_rate, hit_rate)
    |> Map.put(:days, days)
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
    |> case do
      {:ok, session} ->
        notify_project_sessions_changed(session)
        {:ok, session}

      error ->
        error
    end
  end

  @doc """
  Starts the translation for the newest commit on a project's default branch.

  Only one continuously-triggered translation remains active. A newer commit
  cancels older pending or running sessions and carries their checkpointed
  branch and pull request into the replacement session. The project row lock
  makes webhook redelivery and concurrent pushes idempotent across replicas.
  """
  def start_continuous_session(%Project{id: project_id}, attrs, opts \\ []) do
    Translate.serialize_project_publication(project_id, fn ->
      with :ok <- validate_continuous_start(opts),
           {:ok, result} <- create_continuous_session(project_id, attrs) do
        prepare_continuous_start(result, opts)
      end
    end)
    |> case do
      {:aborted, reason} ->
        {:error, {:publication_lock_aborted, reason}}

      {:ignore, reason} ->
        {:ignored, reason}

      {:ok, session, superseded_sessions} ->
        Enum.each(superseded_sessions, &stop_superseded_session/1)
        notify_project_sessions_changed(session)
        {:ok, session}

      {:enqueue_error, reason, superseded_sessions} ->
        Enum.each(superseded_sessions, &stop_superseded_session/1)
        {:error, reason}

      error ->
        error
    end
  end

  defp validate_continuous_start(opts) do
    case Keyword.get(opts, :validate) do
      validator when is_function(validator, 0) -> validator.()
      nil -> :ok
    end
  end

  defp create_continuous_session(project_id, attrs) do
    Repo.transaction(fn ->
      project =
        Project
        |> where(id: ^project_id)
        |> lock("FOR UPDATE")
        |> preload([:account, :github_installation])
        |> Repo.one!()

      commit_sha = Map.get(attrs, :commit_sha) || Map.get(attrs, "commit_sha")

      existing =
        from(s in TranslationSession,
          where: s.project_id == ^project.id and s.commit_sha == ^commit_sha,
          where: s.status in ["pending", "running", "completed"],
          order_by: [desc: s.inserted_at],
          limit: 1
        )
        |> Repo.one()

      if existing do
        {:existing, existing}
      else
        active_sessions =
          from(s in TranslationSession,
            where: s.project_id == ^project.id and s.status in ["pending", "running"],
            order_by: [desc: s.updated_at],
            lock: "FOR UPDATE"
          )
          |> Repo.all()

        continued_from = Enum.find(active_sessions, &reusable_publication?/1)
        now = DateTime.utc_now()

        superseded_sessions =
          Enum.map(active_sessions, fn session ->
            counts = progress_counts(session.id)

            session
            |> Ecto.Changeset.change(%{
              status: "cancelled",
              outcome: "superseded",
              translated_content_count: counts.translated,
              content_hit_count: counts.content_hits,
              completed_at: now
            })
            |> Repo.update!()
          end)

        session_attrs =
          attrs
          |> normalize_session_attrs()
          |> Map.put(:status, "pending")
          |> inherit_publication(continued_from)

        session =
          %TranslationSession{account_id: project.account_id, project_id: project.id}
          |> TranslationSession.changeset(session_attrs)
          |> Repo.insert!()

        {:created, session, superseded_sessions}
      end
    end)
  end

  defp prepare_continuous_start({:existing, %{status: "pending"} = session}, opts) do
    if Keyword.get(opts, :enqueue, true) do
      enqueue_continuous_session(session, [])
    else
      {:ok, session, []}
    end
  end

  defp prepare_continuous_start({:existing, session}, _opts), do: {:ok, session, []}

  defp prepare_continuous_start({:created, session, superseded_sessions}, opts) do
    if Keyword.get(opts, :enqueue, true) do
      enqueue_continuous_session(session, superseded_sessions)
    else
      {:ok, session, superseded_sessions}
    end
  end

  defp enqueue_continuous_session(session, superseded_sessions) do
    case session.id
         |> then(&%{session_id: &1})
         |> Glossia.TranslationSessions.TranslateWorker.new()
         |> Oban.insert() do
      {:ok, _job} ->
        {:ok, session, superseded_sessions}

      {:error, reason} ->
        update_session_status(session, "failed",
          error: "Could not queue the translation: #{inspect(reason)}"
        )

        {:enqueue_error, reason, superseded_sessions}
    end
  end

  defp stop_superseded_session(session) do
    cancel_superseded_jobs(session.id)

    case Glossia.TranslationSessions.Launcher.cancel(session.id) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not stop superseded translation runner",
          translation_session_id: session.id,
          reason: inspect(reason)
        )
    end

    broadcast_session_status(session, "cancelled")
  end

  defp cancel_superseded_jobs(session_id) do
    cancel_queued_jobs(session_id)
  rescue
    error ->
      Logger.warning("Could not cancel queued superseded translation",
        translation_session_id: session_id,
        reason: Exception.message(error)
      )

      :ok
  end

  defp reusable_publication?(session) do
    is_binary(session.publication_branch) and session.publication_branch != "" and
      is_binary(session.publication_commit_sha) and session.publication_commit_sha != ""
  end

  defp inherit_publication(attrs, nil), do: attrs

  defp inherit_publication(attrs, session) do
    Map.merge(attrs, %{
      continued_from_session_id: session.id,
      publication_branch: session.publication_branch,
      publication_commit_sha: session.publication_commit_sha,
      pull_request_url: session.pull_request_url,
      pull_request_number: session.pull_request_number
    })
  end

  defp normalize_session_attrs(attrs) do
    [
      :commit_sha,
      :commit_message,
      :source_language,
      :target_languages
    ]
    |> Enum.reduce(%{}, fn key, normalized ->
      string_key = Atom.to_string(key)

      cond do
        Map.has_key?(attrs, key) -> Map.put(normalized, key, Map.fetch!(attrs, key))
        Map.has_key?(attrs, string_key) -> Map.put(normalized, key, Map.fetch!(attrs, string_key))
        true -> normalized
      end
    end)
  end

  def update_session_status(%TranslationSession{} = session, status, opts \\ []) do
    now = DateTime.utc_now()

    changes =
      case status do
        "pending" ->
          %{
            status: status,
            outcome: nil,
            started_at: nil,
            completed_at: nil,
            error: nil,
            summary: nil
          }

        "running" ->
          %{
            status: status,
            outcome: nil,
            started_at: now,
            completed_at: nil,
            error: nil,
            summary: nil
          }

        "completed" ->
          counts = progress_counts(session.id)

          %{
            status: status,
            outcome: completed_outcome(counts, opts),
            translated_content_count: counts.translated,
            content_hit_count: counts.content_hits,
            completed_at: now,
            error: nil
          }

        "failed" ->
          %{status: status, outcome: "failed", completed_at: now, summary: nil}

        "cancelled" ->
          counts = progress_counts(session.id)

          %{
            status: status,
            outcome: "cancelled",
            translated_content_count: counts.translated,
            content_hit_count: counts.content_hits,
            completed_at: now,
            error: nil,
            summary: nil
          }

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
        # A run announces itself the moment it starts, not when it has finished
        # cloning. Doing it here means a retry clears the previous attempt's
        # files straight away rather than leaving them on screen for the minute
        # or so a clone can take.
        if status == "running", do: start_progress_run(updated_session)

        broadcast_session_status(updated_session, status)
        {:ok, updated_session}

      error ->
        error
    end
  end

  @doc false
  def start_session(%TranslationSession{id: session_id}) do
    now = DateTime.utc_now()

    query =
      from(s in TranslationSession,
        where: s.id == ^session_id and s.status in ["pending", "running"],
        update: [
          set: [
            status: "running",
            outcome: nil,
            translated_content_count: 0,
            content_hit_count: 0,
            started_at: fragment("COALESCE(?, ?)", s.started_at, ^now),
            completed_at: nil,
            error: nil,
            summary: nil,
            updated_at: ^now
          ]
        ]
      )

    case Repo.update_all(query, []) do
      {1, _} ->
        session = Repo.get!(TranslationSession, session_id)
        start_progress_run(session)
        broadcast_session_status(session, "running")
        {:ok, session}

      {0, _} ->
        {:error, :not_active}
    end
  end

  @doc false
  def finish_session(%TranslationSession{id: session_id}, status, opts \\ [])
      when status in ["completed", "failed"] do
    now = DateTime.utc_now()
    counts = progress_counts(session_id)

    changes =
      case status do
        "completed" ->
          %{
            status: status,
            outcome: completed_outcome(counts, opts),
            translated_content_count: counts.translated,
            content_hit_count: counts.content_hits,
            completed_at: now,
            error: nil
          }

        "failed" ->
          %{
            status: status,
            outcome: "failed",
            translated_content_count: counts.translated,
            content_hit_count: counts.content_hits,
            completed_at: now,
            summary: nil
          }
      end

    changes =
      if Keyword.has_key?(opts, :error),
        do: Map.put(changes, :error, opts[:error]),
        else: changes

    changes =
      if Keyword.has_key?(opts, :summary),
        do: Map.put(changes, :summary, opts[:summary]),
        else: changes

    query =
      from(s in TranslationSession,
        where: s.id == ^session_id and s.status in ["pending", "running"]
      )

    case Repo.update_all(query, set: Map.to_list(Map.put(changes, :updated_at, now))) do
      {1, _} ->
        session = Repo.get!(TranslationSession, session_id)
        broadcast_session_status(session, status)
        {:ok, session}

      {0, _} ->
        {:error, :not_active}
    end
  end

  @doc """
  Records that the translation is still alive on this session.

  `expire_stale_sessions/0` reads the resulting `updated_at` to tell a long
  translation apart from one whose pod is gone.
  """
  def heartbeat_session(session_id) do
    from(s in TranslationSession, where: s.id == ^session_id and s.status == "running")
    |> Repo.update_all(set: [updated_at: DateTime.utc_now()])

    :ok
  rescue
    # As with progress rows, a missed heartbeat must not end a translation. The
    # next file writes another one, and the reaper's cutoff is wide enough that
    # a transient failure here cannot make a healthy session look abandoned.
    error ->
      Logger.warning("Could not heartbeat translation session",
        translation_session_id: session_id,
        reason: inspect(error)
      )

      :ok
  end

  @doc """
  Ends sessions that stopped reporting.

  A detached translation outlives the pod that launched it, but not a lost
  node or an evicted pod, and nothing else notices when one disappears: the
  Oban job finished the moment the Job was created. Without this a session
  stays `running` forever — there is one in production that has been running
  since July.
  """
  def expire_stale_sessions do
    now = DateTime.utc_now()
    running_cutoff = DateTime.add(now, -@stale_running_session_seconds, :second)
    pending_cutoff = DateTime.add(now, -@stale_pending_session_seconds, :second)

    from(s in TranslationSession,
      where:
        (s.status == "running" and s.updated_at < ^running_cutoff) or
          (s.status == "pending" and s.updated_at < ^pending_cutoff)
    )
    |> Repo.all()
    |> Enum.each(fn session ->
      Logger.warning("Ending abandoned translation session",
        translation_session_id: session.id,
        status: session.status
      )

      Glossia.TranslationSessions.Launcher.cancel(session.id)
      Glossia.TranslationSessions.Translate.fail_session(session.id, :translation_abandoned)
    end)
  end

  def cancel_session(%TranslationSession{status: status} = session)
      when status in ["pending", "running"] do
    with {:ok, _count} <- cancel_queued_jobs(session.id) do
      # Cancelling the Oban job only stops a launch that has not happened yet.
      # Once the translation is detached it is the Kubernetes Job that has to
      # go, or it keeps translating and opens a pull request for a session the
      # member already cancelled.
      Glossia.TranslationSessions.Launcher.cancel(session.id)
      update_session_status(session, "cancelled")
    end
  end

  def cancel_session(%TranslationSession{}), do: {:error, :not_cancellable}

  defp cancel_queued_jobs(session_id) do
    session_id = to_string(session_id)

    from(job in Oban.Job,
      where:
        job.worker ==
          ^Oban.Worker.to_string(Glossia.TranslationSessions.TranslateWorker),
      where: job.state in ["available", "scheduled", "executing", "retryable"],
      where: fragment("?->>'session_id' = ?", job.args, ^session_id)
    )
    |> Oban.cancel_all_jobs()
  end

  def update_session_publication(%TranslationSession{} = session, attrs) do
    session
    |> Ecto.Changeset.change(
      Map.take(attrs, [
        :publication_branch,
        :publication_commit_sha,
        :pull_request_url,
        :pull_request_number
      ])
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

  def subscribe_project_sessions(%Project{id: id}) do
    Phoenix.PubSub.subscribe(Glossia.PubSub, "translation_sessions:project:#{id}")
  end

  @doc """
  Persists a progress event when it shapes the panel, then fans it out.

  Persisting first is what makes the panel survive the run: a viewer that
  arrives later — on another replica, or after the pod that produced the event
  is gone — rebuilds from these rows. The broadcast is the live path for
  viewers already watching, and carries the high-frequency text and reasoning
  chunks that are deliberately not written down.
  """
  def broadcast_session_event(%TranslationSession{id: id}, event) do
    if Progress.durable_event?(event), do: record_progress_event(id, event)

    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translation_session:#{id}",
      {:translation_session_event, event}
    )
  end

  # Resets the panel for a new attempt. Folded, this clears the files from any
  # earlier run while leaving the sequence climbing, so a viewer still holding
  # the previous attempt adopts this one rather than dismissing its events as
  # ones it has already seen.
  defp start_progress_run(%TranslationSession{} = session) do
    broadcast_session_event(session, %{
      type: "run_started",
      seq: max_progress_seq(session.id) + 1
    })
  end

  @doc "The folded panel state for a session, rebuilt from its persisted events."
  def session_progress(session_id) do
    session_id
    |> list_progress_events()
    |> Enum.map(&Progress.decode(&1.payload))
    |> Progress.fold()
  end

  @doc "The highest sequence written for a session, so a run can continue past it."
  def max_progress_seq(session_id) do
    from(e in ProgressEvent, where: e.session_id == ^session_id, select: max(e.seq))
    |> Repo.one() || 0
  end

  defp list_progress_events(session_id) do
    from(e in ProgressEvent, where: e.session_id == ^session_id, order_by: [asc: e.seq])
    |> Repo.all()
  end

  defp progress_counts(session_id) do
    latest_run_seq =
      from(e in ProgressEvent,
        where: e.session_id == ^session_id,
        where: fragment("?->>'type' = 'run_started'", e.payload),
        select: max(e.seq)
      )
      |> Repo.one() || 0

    from(e in ProgressEvent,
      where: e.session_id == ^session_id and e.seq > ^latest_run_seq,
      select: %{
        translated:
          fragment(
            "COALESCE(COUNT(DISTINCT (?->>'index')) FILTER (WHERE ?->>'type' = 'item_completed'), 0)::integer",
            e.payload,
            e.payload
          ),
        content_hits:
          fragment(
            "COALESCE(MAX((?->>'up_to_date')::integer) FILTER (WHERE ?->>'type' = 'plan_assessed'), COUNT(*) FILTER (WHERE ?->>'type' = 'item_skipped'), 0)::integer",
            e.payload,
            e.payload,
            e.payload
          )
      }
    )
    |> Repo.one!()
  end

  defp completed_outcome(%{translated: translated}, opts) do
    cond do
      Keyword.get(opts, :outcome) == "content_hit" -> "content_hit"
      translated > 0 -> "translated"
      Keyword.get(opts, :summary) == "No translations needed." -> "content_hit"
      true -> "translated"
    end
  end

  defp record_progress_event(session_id, event) do
    # A run stamps its own sequence, which is what keeps it monotonic across a
    # relay hop. An event arriving without one still needs a distinct sequence,
    # or every such event would collide on the same row and only the first
    # would survive.
    seq = Map.get(event, :seq) || max_progress_seq(session_id) + 1

    %ProgressEvent{}
    |> ProgressEvent.changeset(%{
      session_id: session_id,
      seq: seq,
      payload: event |> Map.put(:seq, seq) |> encode_progress_payload()
    })
    # The unique (session_id, seq) index makes a re-delivered event a no-op
    # rather than a second row that would be folded twice.
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:session_id, :seq])
    |> case do
      {:ok, _event} -> :ok
      {:error, changeset} -> skip_progress_event(session_id, changeset.errors)
    end
  rescue
    # A progress row is worth far less than the hour of translation producing
    # it. A database blip, or a session row that has since been deleted, must
    # not take the run down: the panel degrades to what was written before, and
    # live viewers keep getting the broadcast below either way.
    error -> skip_progress_event(session_id, error)
  end

  defp skip_progress_event(session_id, reason) do
    Logger.warning("Could not persist translation progress",
      translation_session_id: session_id,
      reason: inspect(reason)
    )

    :ok
  end

  defp encode_progress_payload(event) do
    Map.new(event, fn {key, value} -> {to_string(key), value} end)
  end

  # A detached translation job runs on a node with its own Repo and PubSub, so
  # it records and broadcasts directly. Only a FLAME runner, which starts
  # neither, has to relay through the node that placed it.
  def broadcast_session_event(%TranslationSession{} = session, event, target_node)
      when target_node == node(),
      do: broadcast_session_event(session, event)

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

  def broadcast_session_status(%TranslationSession{id: id} = session, status) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translation_session:#{id}",
      {:translation_session_status, status}
    )

    notify_project_sessions_changed(session)
  end

  defp notify_project_sessions_changed(%TranslationSession{project_id: project_id, id: id}) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "translation_sessions:project:#{project_id}",
      {:project_translation_sessions_changed, id}
    )
  end

  defp escape_like_pattern(search) do
    search
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
