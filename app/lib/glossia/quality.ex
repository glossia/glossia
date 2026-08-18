defmodule Glossia.Quality do
  @moduledoc """
  Project-scoped localization quality assurance runs, persistent findings, and reviewed context.

  Browser evidence and findings remain separate from project context. Only an
  explicit review action creates a new immutable project-context version that
  future translations may consume.
  """

  import Ecto.Query

  require Logger

  alias Glossia.Accounts.{Account, Project, User}

  alias Glossia.Quality.{
    Artifacts,
    Finding,
    Occurrence,
    Page,
    Profile,
    ProjectContextEntry,
    ProjectContextVersion,
    Run,
    SessionEvent
  }

  alias Glossia.Repo
  alias Oban.Job, as: ObanJob

  @maximum_remembered_source_bytes 2_000
  @maximum_remembered_translation_bytes 4_000
  @retained_evidence_runs 20
  @prunable_runs_per_pass 5

  # A running review heartbeats after every captured page, and a single page is
  # capped at two 45s browser calls, so silence far beyond that means the worker
  # is gone. Pending runs get a longer grace period to survive a queue backlog.
  @stale_running_run_seconds 30 * 60
  @stale_pending_run_seconds 60 * 60

  @run_error_messages %{
    private_origin_not_allowed:
      "A configured web address resolves to a private or local network address.",
    origin_not_resolvable: "A configured web address could not be resolved.",
    invalid_origin: "A configured web address is invalid.",
    invalid_locale_origins: "The configured locale web addresses are invalid.",
    browser_sandbox_unavailable:
      "The browser could not start securely in the review environment.",
    quality_run_abandoned: "The browser worker stopped before the review completed."
  }

  def get_profile(%Project{id: project_id}) do
    Repo.get_by(Profile, project_id: project_id)
  end

  def profile_or_default(%Project{} = project) do
    get_profile(project) || default_profile(project)
  end

  def default_profile(%Project{} = project) do
    origin = project.url || ""

    %Profile{
      project_id: project.id,
      project: project,
      source_locale: "en",
      locale_origins: %{"en" => origin},
      seed_paths: ["/"],
      max_pages: 20
    }
  end

  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, normalize_profile_attrs(attrs))
  end

  def upsert_profile(%Project{} = project, attrs) do
    profile = get_profile(project) || %Profile{project_id: project.id}

    profile
    |> Profile.changeset(normalize_profile_attrs(attrs))
    |> Repo.insert_or_update()
  end

  def list_runs(%Project{id: project_id}, params \\ %{}) do
    Run
    |> where(project_id: ^project_id)
    |> preload(:triggered_by)
    |> Flop.validate_and_run(params, for: Run, replace_invalid_params: true)
  end

  def get_run!(%Project{id: project_id}, run_id) do
    Run
    |> where(project_id: ^project_id, id: ^run_id)
    |> preload([:sandbox, :triggered_by, pages: [], occurrences: :finding])
    |> Repo.one!()
  end

  def get_run!(run_id) do
    Run
    |> where(id: ^run_id)
    |> preload([:account, :project, :sandbox])
    |> Repo.one!()
  end

  def create_run(%Account{} = account, %Project{} = project, %User{} = user, opts \\ []) do
    expire_stale_runs(project)

    with %Profile{} = profile <- get_profile(project),
         {:ok, run} <- insert_run(account, project, user, profile) do
      case maybe_enqueue(run, opts) do
        :ok ->
          {:ok, run}

        {:error, _reason} = error ->
          _ = Repo.delete(run)
          error
      end
    else
      nil -> {:error, :quality_profile_missing}
      {:error, _reason} = error -> error
    end
  end

  def update_run(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} = result ->
        broadcast_run(updated, {:quality_run_updated, updated})
        result

      error ->
        error
    end
  end

  def mark_run_running(%Run{} = run, sandbox_id) do
    now = DateTime.utc_now()

    with {1, _rows} <-
           Run
           |> where(id: ^run.id, status: "pending")
           |> Repo.update_all(
             set: [
               status: "running",
               sandbox_id: sandbox_id,
               started_at: now,
               completed_at: nil,
               error: nil,
               updated_at: now
             ]
           ),
         running <-
           Run
           |> Repo.get!(run.id)
           |> Repo.preload([:account, :project, :sandbox]),
         :ok <- broadcast_run(running, {:quality_run_updated, running}),
         {:ok, _event} <-
           record_session_event(running, %{
             kind: "session_started",
             label: "Review session started",
             detail: "The browser sandbox is ready."
           }) do
      {:ok, running}
    else
      {0, _rows} -> {:error, :quality_run_not_pending}
      {:error, _reason} = error -> error
    end
  end

  def complete_run(%Run{} = run) do
    pages_count = Repo.aggregate(from(p in Page, where: p.run_id == ^run.id), :count)

    findings_count =
      Occurrence
      |> where(run_id: ^run.id)
      |> select([o], count(o.finding_id, :distinct))
      |> Repo.one()

    with {:ok, completed} <-
           transition_run(run, ["pending", "running"], %{
             status: "completed",
             pages_count: pages_count,
             findings_count: findings_count,
             completed_at: DateTime.utc_now(),
             error: nil
           }),
         {:ok, _event} <-
           record_session_event(completed, %{
             kind: "session_completed",
             label: "Review session completed",
             detail: "#{pages_count} pages inspected and #{findings_count} findings recorded."
           }) do
      prune_old_evidence(completed)
      {:ok, completed}
    end
  end

  def fail_run(%Run{} = run, reason) do
    error = human_error(reason)

    with {:ok, failed} <-
           transition_run(run, ["pending", "running"], %{
             status: "failed",
             completed_at: DateTime.utc_now(),
             error: error
           }),
         {:ok, _event} <-
           record_session_event(failed, %{
             kind: "session_failed",
             label: "Review session failed",
             detail: error
           }) do
      prune_old_evidence(failed)
      {:ok, failed}
    end
  end

  def cancel_run(%Run{} = run) do
    with {:ok, cancelled} <-
           transition_run(run, ["pending", "running"], %{
             status: "cancelled",
             completed_at: DateTime.utc_now(),
             error: nil
           }),
         {:ok, _event} <-
           record_session_event(cancelled, %{
             kind: "session_cancelled",
             label: "Review session cancelled",
             detail: "The browser review was stopped."
           }) do
      cancel_run_jobs(cancelled)
      prune_old_evidence(cancelled)
      {:ok, cancelled}
    end
  end

  @doc """
  Whether the run is still pending or running.

  The worker calls this between captures so a cancelled review stops driving the
  browser instead of finishing its whole plan against the customer's site.
  """
  def run_active?(%Run{id: run_id}) do
    Run
    |> where([run], run.id == ^run_id and run.status in ["pending", "running"])
    |> Repo.exists?()
  end

  @doc """
  Records that the worker is still alive on this run.

  `expire_stale_runs/1` uses the resulting `updated_at` to tell a long review
  apart from one whose worker disappeared.
  """
  def heartbeat_run(%Run{id: run_id}) do
    Run
    |> where([run], run.id == ^run_id and run.status == "running")
    |> Repo.update_all(set: [updated_at: DateTime.utc_now()])

    :ok
  end

  @doc """
  Ends runs whose worker stopped reporting, so they cannot hold the
  one-active-run-per-project slot forever.
  """
  def expire_stale_runs, do: do_expire_stale_runs(Run)

  def expire_stale_runs(%Project{id: project_id}) do
    do_expire_stale_runs(where(Run, [run], run.project_id == ^project_id))
  end

  defp do_expire_stale_runs(query) do
    now = DateTime.utc_now()
    running_cutoff = DateTime.add(now, -@stale_running_run_seconds, :second)
    pending_cutoff = DateTime.add(now, -@stale_pending_run_seconds, :second)

    query
    |> where(
      [run],
      (run.status == "running" and run.updated_at < ^running_cutoff) or
        (run.status == "pending" and run.updated_at < ^pending_cutoff)
    )
    |> Repo.all()
    |> Enum.each(fn run ->
      if run.status == "running" or not active_run_job?(run) do
        cancel_run_jobs(run)
        fail_run(run, :quality_run_abandoned)
      end
    end)
  end

  def create_page(%Run{} = run, attrs) do
    page =
      Repo.get_by(Page,
        run_id: run.id,
        locale: Map.get(attrs, :locale) || Map.get(attrs, "locale"),
        logical_path: Map.get(attrs, :logical_path) || Map.get(attrs, "logical_path")
      ) || %Page{run_id: run.id, project_id: run.project_id}

    page
    |> Page.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def list_run_pages(%Run{id: run_id}) do
    Page
    |> where(run_id: ^run_id)
    |> order_by([p], asc: p.inserted_at, asc: p.id)
    |> Repo.all()
  end

  def get_page(%Project{id: project_id}, run_id, page_id) do
    Page
    |> where(project_id: ^project_id, run_id: ^run_id, id: ^page_id)
    |> Repo.one()
  end

  def get_occurrence(%Run{id: run_id}, finding_id, page_id) do
    Occurrence
    |> where(run_id: ^run_id, finding_id: ^finding_id, page_id: ^page_id)
    |> preload(:finding)
    |> Repo.one()
  end

  def list_session_events(%Run{id: run_id}) do
    SessionEvent
    |> where(run_id: ^run_id)
    |> order_by([event], asc: event.inserted_at, asc: event.id)
    |> Repo.all()
  end

  def record_session_event(%Run{} = run, attrs) do
    %SessionEvent{run_id: run.id}
    |> SessionEvent.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, event} = result ->
        broadcast_run(run, {:quality_session_event, event})
        result

      error ->
        error
    end
  end

  def list_findings(%Project{id: project_id}, opts \\ []) do
    status = Keyword.get(opts, :status)
    run_id = Keyword.get(opts, :run_id)

    Finding
    |> where(project_id: ^project_id)
    |> maybe_filter_status(status)
    |> maybe_filter_run(run_id)
    |> order_by([f],
      asc:
        fragment(
          "CASE ? WHEN 'high' THEN 0 WHEN 'medium' THEN 1 WHEN 'low' THEN 2 ELSE 3 END",
          f.severity
        ),
      desc: f.last_seen_at
    )
    |> Repo.all()
  end

  def get_finding!(%Project{id: project_id}, finding_id) do
    Finding
    |> where(project_id: ^project_id, id: ^finding_id)
    |> preload(occurrences: [:run, :page])
    |> Repo.one!()
  end

  def record_finding(%Run{} = run, %Page{} = page, attrs, evidence \\ %{}) do
    now = DateTime.utc_now()
    fingerprint = Map.get(attrs, :fingerprint) || fingerprint(attrs)

    Repo.transaction(fn ->
      unless Repo.exists?(
               from quality_run in Run,
                 where:
                   quality_run.id == ^run.id and quality_run.status in ["pending", "running"],
                 lock: "FOR UPDATE"
             ) do
        Repo.rollback(:quality_run_not_active)
      end

      finding =
        Finding
        |> where(project_id: ^run.project_id, fingerprint: ^fingerprint)
        |> lock("FOR UPDATE")
        |> Repo.one()

      finding =
        if finding do
          status = if finding.status == "resolved", do: "open", else: finding.status

          finding
          |> Finding.changeset(
            attrs
            |> Map.put(:fingerprint, fingerprint)
            |> Map.put(:status, status)
            |> Map.put(:last_seen_at, now)
            |> Map.put(:resolved_at, nil)
          )
          |> Repo.update!()
        else
          %Finding{project_id: run.project_id}
          |> Finding.changeset(
            attrs
            |> Map.put(:fingerprint, fingerprint)
            |> Map.put_new(:status, "open")
            |> Map.put(:first_seen_at, now)
            |> Map.put(:last_seen_at, now)
          )
          |> Repo.insert!()
        end

      event =
        if Repo.get_by(Occurrence,
             finding_id: finding.id,
             run_id: run.id,
             page_id: page.id
           ) do
          nil
        else
          %Occurrence{finding_id: finding.id, run_id: run.id, page_id: page.id}
          |> Occurrence.changeset(%{
            evidence: evidence,
            screenshot_path: page.screenshot_path
          })
          |> Repo.insert!()

          %SessionEvent{run_id: run.id, page_id: page.id, finding_id: finding.id}
          |> SessionEvent.changeset(%{
            kind: "finding_recorded",
            label: finding.title,
            detail: finding.description,
            metadata: %{
              "severity" => finding.severity,
              "locale" => finding.locale,
              "logical_path" => finding.logical_path
            }
          })
          |> Repo.insert!()
        end

      {finding, event}
    end)
    |> case do
      {:ok, {finding, event}} ->
        if event, do: broadcast_run(run, {:quality_session_event, event})
        {:ok, finding}

      error ->
        error
    end
  end

  def update_finding_status(%Finding{} = finding, status)
      when status in ~w(open acknowledged resolved dismissed) do
    now = DateTime.utc_now()

    changes =
      case status do
        "resolved" -> %{status: status, resolved_at: now, dismissed_at: nil}
        "dismissed" -> %{status: status, dismissed_at: now, resolved_at: nil}
        _ -> %{status: status, resolved_at: nil, dismissed_at: nil}
      end

    finding
    |> Finding.changeset(changes)
    |> Repo.update()
  end

  def latest_project_context_version(%Project{id: project_id}) do
    ProjectContextVersion
    |> where(project_id: ^project_id)
    |> select([context], max(context.version))
    |> Repo.one()
  end

  def get_latest_project_context(%Project{id: project_id}) do
    ProjectContextVersion
    |> where(project_id: ^project_id)
    |> order_by(desc: :version)
    |> limit(1)
    |> Repo.one()
    |> load_effective_context_entries()
  end

  def get_project_context_version(%Project{id: project_id}, version) when is_integer(version) do
    ProjectContextVersion
    |> where(project_id: ^project_id, version: ^version)
    |> Repo.one()
    |> load_effective_context_entries()
  end

  def resolve_project_context(%Project{} = project, version, locale)
      when is_integer(version) and is_binary(locale) do
    case get_project_context_version(project, version) do
      nil -> %{version: version, terminology: [], guidance: []}
      context -> resolved_context(context, locale)
    end
  end

  def resolve_project_context(%Project{}, nil, _locale),
    do: %{version: nil, terminology: [], guidance: []}

  def remember_translation(
        %Project{} = project,
        %Finding{} = finding,
        %User{} = user,
        translation
      )
      when is_binary(translation) do
    translation = String.trim(translation)
    source_text = String.trim(finding.source_text || "")
    locale = finding.locale || ""

    cond do
      translation == "" ->
        {:error, :translation_required}

      source_text == "" ->
        {:error, :source_text_required}

      locale == "" ->
        {:error, :locale_required}

      byte_size(source_text) > @maximum_remembered_source_bytes ->
        {:error, :source_text_too_long}

      byte_size(translation) > @maximum_remembered_translation_bytes ->
        {:error, :translation_too_long}

      true ->
        create_context_version(project, finding, user, source_text, locale, translation)
    end
  end

  def subscribe_run(%Run{id: run_id}) do
    Phoenix.PubSub.subscribe(Glossia.PubSub, "quality_run:#{run_id}")
  end

  def unsubscribe_run(run_id) when is_binary(run_id) do
    Phoenix.PubSub.unsubscribe(Glossia.PubSub, "quality_run:#{run_id}")
  end

  defp insert_run(account, project, user, profile) do
    configuration = %{
      "source_locale" => profile.source_locale,
      "locale_origins" => profile.locale_origins,
      "seed_paths" => profile.seed_paths,
      "max_pages" => profile.max_pages
    }

    %Run{account_id: account.id, project_id: project.id, triggered_by_id: user.id}
    |> Run.changeset(%{status: "pending", configuration: configuration})
    |> Repo.insert()
    |> case do
      {:error, changeset} = error ->
        if active_run_constraint?(changeset),
          do: {:error, :quality_run_already_active},
          else: error

      result ->
        result
    end
  end

  defp maybe_enqueue(_run, enqueue: false), do: :ok

  defp maybe_enqueue(run, _opts) do
    case %{"run_id" => to_string(run.id)}
         |> Glossia.Quality.RunWorker.new()
         |> Oban.insert() do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_context_version(project, finding, user, source_text, locale, translation) do
    Repo.transaction(fn ->
      Repo.one!(from p in Project, where: p.id == ^project.id, lock: "FOR UPDATE")

      previous_version = latest_project_context_version(project)
      version = if previous_version, do: previous_version + 1, else: 1

      context =
        %ProjectContextVersion{project_id: project.id, created_by_id: user.id}
        |> ProjectContextVersion.changeset(%{
          version: version,
          change_note: "Remembered a translation from quality finding #{finding.id}"
        })
        |> Repo.insert!()

      insert_context_entry!(context, %{
        origin_finding_id: finding.id,
        kind: "terminology",
        locale: locale,
        source_text: source_text,
        instruction: translation,
        # Browser paths cannot be mapped reliably to repository source paths yet.
        # Reviewed browser translations therefore apply project-wide.
        route_scope: nil
      })

      finding
      |> Finding.changeset(%{status: "acknowledged"})
      |> Repo.update!()

      load_effective_context_entries(context)
    end)
  end

  defp insert_context_entry!(context, attrs) do
    %ProjectContextEntry{project_context_version_id: context.id}
    |> ProjectContextEntry.changeset(attrs)
    |> Repo.insert!()
  end

  defp resolved_context(context, locale) do
    candidates = locale_candidates(locale)

    selected =
      context.entries
      |> Enum.filter(&(normalize_locale(&1.locale) in candidates))
      |> Enum.group_by(fn entry -> {entry.kind, entry.source_text, entry.route_scope} end)
      |> Enum.map(fn {_key, entries} ->
        Enum.min_by(entries, fn entry ->
          Enum.find_index(candidates, fn candidate ->
            candidate == normalize_locale(entry.locale)
          end)
        end)
      end)

    terminology =
      selected
      |> Enum.filter(&(&1.kind == "terminology"))
      |> Enum.map(fn entry ->
        %{
          id: to_string(entry.id),
          term: entry.source_text,
          translation: entry.instruction,
          definition: "Approved from a project quality finding.",
          case_sensitive: false,
          route_scope: entry.route_scope
        }
      end)

    guidance =
      selected
      |> Enum.filter(&(&1.kind == "locale_guidance"))
      |> Enum.map(fn entry ->
        %{instruction: entry.instruction, route_scope: entry.route_scope}
      end)

    %{version: context.version, terminology: terminology, guidance: guidance}
  end

  defp locale_candidates(locale) do
    parts =
      locale
      |> String.replace("_", "-")
      |> String.downcase()
      |> String.split("-", trim: true)

    case parts do
      [] -> [locale]
      parts -> Enum.map(length(parts)..1//-1, &(parts |> Enum.take(&1) |> Enum.join("-")))
    end
  end

  defp normalize_locale(locale), do: locale |> String.replace("_", "-") |> String.downcase()

  defp load_effective_context_entries(nil), do: nil

  defp load_effective_context_entries(context) do
    entries =
      ProjectContextEntry
      |> join(:inner, [entry], version in assoc(entry, :project_context_version))
      |> where(
        [entry, version],
        version.project_id == ^context.project_id and version.version <= ^context.version
      )
      |> order_by([entry, version],
        desc: version.version,
        desc: entry.inserted_at,
        desc: entry.id
      )
      |> preload([entry, version], project_context_version: version)
      |> Repo.all()
      |> Enum.uniq_by(fn entry ->
        {entry.kind, normalize_locale(entry.locale), entry.source_text, entry.route_scope}
      end)

    %{context | entries: entries}
  end

  defp fingerprint(attrs) do
    [
      Map.get(attrs, :check),
      Map.get(attrs, :locale),
      Map.get(attrs, :logical_path),
      normalize_fingerprint_text(Map.get(attrs, :source_text)),
      normalize_fingerprint_text(Map.get(attrs, :target_text))
    ]
    |> JSON.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp normalize_fingerprint_text(nil), do: ""

  defp normalize_fingerprint_text(value) do
    value |> to_string() |> String.trim() |> String.downcase() |> String.replace(~r/\s+/, " ")
  end

  defp normalize_profile_attrs(attrs) when is_map(attrs) do
    attrs
    |> normalize_origins()
    |> normalize_paths()
  end

  defp normalize_profile_attrs(attrs), do: attrs

  defp normalize_origins(attrs) do
    key = if Map.has_key?(attrs, "locale_origins"), do: "locale_origins", else: :locale_origins

    case Map.get(attrs, key) do
      origins when is_map(origins) ->
        normalized =
          Map.new(origins, fn {locale, origin} ->
            {to_string(locale) |> String.trim(), to_string(origin) |> String.trim()}
          end)

        Map.put(attrs, key, normalized)

      _ ->
        attrs
    end
  end

  defp normalize_paths(attrs) do
    key = if Map.has_key?(attrs, "seed_paths"), do: "seed_paths", else: :seed_paths

    case Map.get(attrs, key) do
      paths when is_binary(paths) ->
        normalized =
          paths |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

        Map.put(attrs, key, normalized)

      _ ->
        attrs
    end
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [f], f.status == ^status)

  defp maybe_filter_run(query, nil), do: query

  defp maybe_filter_run(query, run_id) do
    from finding in query,
      join: occurrence in Occurrence,
      on: occurrence.finding_id == finding.id,
      where: occurrence.run_id == ^run_id
  end

  defp active_run_constraint?(changeset) do
    Enum.any?(changeset.errors, fn {_field, {_message, metadata}} ->
      to_string(metadata[:constraint_name]) == "quality_runs_one_active_per_project_index"
    end)
  end

  defp transition_run(run, current_statuses, attrs) do
    now = DateTime.utc_now()
    updates = attrs |> Map.put(:updated_at, now) |> Map.to_list()

    case Run
         |> where([quality_run], quality_run.id == ^run.id)
         |> where([quality_run], quality_run.status in ^current_statuses)
         |> Repo.update_all(set: updates) do
      {1, _rows} ->
        updated = Repo.get!(Run, run.id)
        :ok = broadcast_run(updated, {:quality_run_updated, updated})
        {:ok, updated}

      {0, _rows} ->
        {:error, :quality_run_not_active}
    end
  end

  defp cancel_run_jobs(run) do
    run_id = to_string(run.id)

    # Oban stores the worker without the `Elixir.` prefix that `to_string/1`
    # produces, so the module has to be rendered the same way Oban wrote it.
    worker = Oban.Worker.to_string(Glossia.Quality.RunWorker)

    jobs =
      from(job in ObanJob,
        where: job.worker == ^worker,
        where: job.state in ["available", "scheduled", "executing", "retryable"],
        where: fragment("?->>'run_id' = ?", job.args, ^run_id)
      )

    {:ok, _count} = Oban.cancel_all_jobs(jobs)
    :ok
  rescue
    error ->
      Logger.warning("Could not cancel quality job", reason: Exception.message(error))
      :ok
  catch
    :exit, reason ->
      Logger.warning("Could not cancel quality job", reason: inspect(reason))
      :ok
  end

  defp active_run_job?(run) do
    run_id = to_string(run.id)
    worker = Oban.Worker.to_string(Glossia.Quality.RunWorker)

    ObanJob
    |> where([job], job.worker == ^worker)
    |> where([job], job.state in ["available", "scheduled", "executing", "retryable"])
    |> where([job], fragment("?->>'run_id' = ?", job.args, ^run_id))
    |> Repo.exists?()
  end

  defp prune_old_evidence(%Run{project_id: project_id}) do
    retained_run_ids =
      Run
      |> where([run], run.project_id == ^project_id)
      |> where([run], run.status in ["completed", "failed", "cancelled"])
      |> order_by([run], desc: run.inserted_at, desc: run.id)
      |> limit(^@retained_evidence_runs)
      |> select([run], run.id)

    old_run_ids =
      Run
      |> where([run], run.project_id == ^project_id)
      |> where([run], run.status in ["completed", "failed", "cancelled"])
      |> where([run], run.id not in subquery(retained_run_ids))
      |> order_by([run], asc: run.inserted_at, asc: run.id)
      |> limit(^@prunable_runs_per_pass)
      |> select([run], run.id)

    pages =
      Page
      |> where([page], page.run_id in subquery(old_run_ids))
      |> where([page], not is_nil(page.screenshot_path))
      |> select([page], {page.id, page.screenshot_path})
      |> Repo.all()

    Page
    |> where([page], page.run_id in subquery(old_run_ids))
    |> where([page], page.visible_text != "" or page.alternate_links != ^%{})
    |> Repo.update_all(set: [visible_text: "", alternate_links: %{}])

    Occurrence
    |> where([occurrence], occurrence.run_id in subquery(old_run_ids))
    |> where([occurrence], fragment("? <> '{}'::jsonb", occurrence.evidence))
    |> Repo.update_all(set: [evidence: %{}])

    SessionEvent
    |> where([event], event.run_id in subquery(old_run_ids))
    |> Repo.delete_all()

    Enum.each(pages, &delete_retained_screenshot/1)

    Page
    |> where([page], page.run_id in subquery(old_run_ids))
    |> where([page], is_nil(page.screenshot_path))
    |> Repo.delete_all()

    :ok
  rescue
    error ->
      Logger.warning("Could not prune old quality evidence", reason: Exception.message(error))
      :ok
  end

  defp delete_retained_screenshot({_page_id, nil}), do: :ok

  defp delete_retained_screenshot({page_id, screenshot_path}) do
    case Artifacts.delete_screenshot(screenshot_path) do
      result when result == :ok or elem(result, 0) == :ok ->
        Page |> where(id: ^page_id) |> Repo.update_all(set: [screenshot_path: nil])

        Occurrence
        |> where(page_id: ^page_id)
        |> Repo.update_all(set: [screenshot_path: nil])

        :ok

      _error ->
        :ok
    end
  rescue
    _error -> :ok
  end

  defp broadcast_run(run, message) do
    Phoenix.PubSub.broadcast(Glossia.PubSub, "quality_run:#{run.id}", message)
  end

  defp human_error(%{__exception__: true}), do: "The quality run stopped unexpectedly."

  defp human_error(reason) when is_atom(reason),
    do: Map.get(@run_error_messages, reason, "The quality run could not be completed.")

  defp human_error(_reason), do: "The quality run could not be completed."
end
