defmodule GlossiaEnterprise.Application do
  @moduledoc """
  Enterprise boot: decides which supervision tree the release image starts.

  Not an OTP application in its own right — `Glossia.Application` is still
  the `mod:` behind the running node. This module is what glossia calls
  through its `:application, children:` MFA seam
  (configured in `enterprise/config/config.exs`) to pick the child list.

  Three roles are recognised, in order:

    * a runner child pod (`GlossiaEnterprise.Flame.child?/0`) — nothing to
      start locally, FLAME owns the child's supervision
    * a detached translation-job pod
      (`GlossiaEnterprise.TranslationSessions.Job.current?/0`) — everything
      the translation needs (DB, PubSub, ingestion buffers, GitHub tokens)
      but no HTTP endpoint, no Oban queues, no runner pool
    * everything else — glossia's `parent_children/0` plus the managed
      runner pool the OSS default no longer starts
  """

  alias Glossia.Ingestion

  require Logger

  @doc "MFA target for `:glossia, :application, children: {…}`."
  def children do
    cond do
      GlossiaEnterprise.Flame.child?() ->
        Logger.info("Starting Glossia in the runner-child role")
        runner_child_children()

      GlossiaEnterprise.TranslationSessions.Job.current?() ->
        Logger.info("Starting Glossia in the translation-job role")
        translation_job_children()

      true ->
        Logger.info("Starting Glossia in the parent role")
        Glossia.Application.parent_children() ++ enterprise_parent_children()
    end
  end

  # Enterprise-only children the OSS `parent_children/0` no longer provides.
  # The `Sandbox.ProcessRegistry` + `Sandbox.Reaper` back the Kata-scheduled
  # sandbox lifecycle; `SetupRecovery` re-runs any project setup that was
  # mid-flight when a previous pod died. `Ingestion.SetupEventBuffer` batches
  # setup events into ClickHouse.
  defp enterprise_parent_children do
    setup_event_buffer =
      Supervisor.child_spec(
        {Glossia.Ingestion.Buffer,
         [name: GlossiaEnterprise.Ingestion.SetupEventBuffer, flush_interval_ms: 1_000] ++
           (GlossiaEnterprise.Ingestion.SetupEvent.buffer_opts()
            |> Map.take([:insert_sql, :insert_opts, :header])
            |> Map.to_list())},
        id: GlossiaEnterprise.Ingestion.SetupEventBuffer
      )

    [
      GlossiaEnterprise.Sandbox.ProcessRegistry,
      GlossiaEnterprise.Sandbox.Reaper,
      GlossiaEnterprise.Projects.SetupRecovery,
      setup_event_buffer
    ]
  end

  # A FLAME runner child pod has FLAME.Terminator monitoring its lifetime and
  # the pool placing work onto it. Nothing local needs to supervise anything.
  defp runner_child_children, do: []

  # A detached translation Job pod runs the release image with
  # `GLOSSIA_TRANSLATION_JOB=1`. It needs everything the translation itself
  # touches — DB pools, PubSub, ingestion buffers, GitHub tokens — and
  # nothing else. No HTTP endpoint, no Oban queues (its queue set is
  # `false`), and no runner pool: it is already the isolated compute.
  defp translation_job_children do
    oban_config =
      :glossia
      |> Application.fetch_env!(Oban)
      |> Keyword.merge(queues: false, plugins: false)

    [
      Glossia.Vault,
      {Finch, name: Glossia.Finch, pools: %{default: [size: http_pool_size()]}},
      Glossia.Repo,
      Glossia.ClickHouseRepo,
      Glossia.IngestRepo,
      {Oban, oban_config},
      {DNSCluster, query: Application.get_env(:glossia, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Glossia.PubSub},
      FunWithFlags.Supervisor,
      Glossia.RateLimiter,
      {Ingestion.Buffer,
       [name: Ingestion.EventBuffer] ++
         (Ingestion.Event.buffer_opts()
          |> Map.take([:insert_sql, :insert_opts, :header])
          |> Map.to_list())},
      Supervisor.child_spec(
        {Ingestion.Buffer,
         [name: Ingestion.TranslationSessionEventBuffer, flush_interval_ms: 1_000] ++
           (Ingestion.TranslationSessionEvent.buffer_opts()
            |> Map.take([:insert_sql, :insert_opts, :header])
            |> Map.to_list())},
        id: Ingestion.TranslationSessionEventBuffer
      ),
      Glossia.Github.InstallationTokens,
      # Last, so the translation only starts once everything it depends on is up.
      GlossiaEnterprise.TranslationSessions.Job
    ]
  end

  defp http_pool_size, do: Application.get_env(:glossia, :http_pool_size, 50)
end
