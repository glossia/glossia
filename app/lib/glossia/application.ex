defmodule Glossia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @compile {:no_warn_undefined, [LLMDB]}

  @impl true
  def start(_type, _args) do
    Glossia.OTel.setup()
    Logger.add_handlers(:glossia)
    {:ok, _} = LLMDB.load()

    role = role()
    Logger.info("Starting Glossia as #{role}")

    children =
      case role do
        :isolated_child -> flame_child_children()
        :translation_job -> translation_job_children()
        :parent -> parent_children()
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Glossia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp parent_children do
    children =
      [
        Glossia.Vault,
        {Finch, name: Glossia.Finch},
        Glossia.PromEx,
        GlossiaWeb.Telemetry,
        Glossia.Repo,
        Glossia.ClickHouseRepo,
        Glossia.IngestRepo,
        {Oban, Application.fetch_env!(:glossia, Oban)},
        {DNSCluster, query: Application.get_env(:glossia, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Glossia.PubSub},
        FunWithFlags.Supervisor,
        Glossia.Docs.SearchIndexer,
        Glossia.Sandbox.ProcessRegistry,
        Glossia.Sandbox.Reaper,
        # Start a worker by calling: Glossia.Worker.start_link(arg)
        # {Glossia.Worker, arg},
        Glossia.RateLimiter,
        Hermes.Server.Registry,
        %{
          id: Glossia.MCP.Server,
          start:
            {Hermes.Server.Supervisor, :start_link,
             [Glossia.MCP.Server, [transport: :streamable_http]]}
        },
        %{
          id: Glossia.Admin.MCP.Server,
          start:
            {Hermes.Server.Supervisor, :start_link,
             [Glossia.Admin.MCP.Server, [transport: :streamable_http]]}
        },
        {Glossia.Ingestion.Buffer,
         [name: Glossia.Ingestion.EventBuffer] ++
           (Glossia.Ingestion.Event.buffer_opts()
            |> Map.take([:insert_sql, :insert_opts, :header])
            |> Map.to_list())},
        Supervisor.child_spec(
          {Glossia.Ingestion.Buffer,
           [name: Glossia.Ingestion.SetupEventBuffer, flush_interval_ms: 1_000] ++
             (Glossia.Ingestion.SetupEvent.buffer_opts()
              |> Map.take([:insert_sql, :insert_opts, :header])
              |> Map.to_list())},
          id: Glossia.Ingestion.SetupEventBuffer
        ),
        Supervisor.child_spec(
          {Glossia.Ingestion.Buffer,
           [name: Glossia.Ingestion.TranslationSessionEventBuffer, flush_interval_ms: 1_000] ++
             (Glossia.Ingestion.TranslationSessionEvent.buffer_opts()
              |> Map.take([:insert_sql, :insert_opts, :header])
              |> Map.to_list())},
          id: Glossia.Ingestion.TranslationSessionEventBuffer
        ),
        Supervisor.child_spec(
          {Glossia.Ingestion.Buffer,
           [name: Glossia.Analytics.EventBuffer, flush_interval_ms: 1_000] ++
             (Glossia.Analytics.Event.buffer_opts()
              |> Map.take([:insert_sql, :insert_opts, :header])
              |> Map.to_list())},
          id: Glossia.Analytics.EventBuffer
        ),
        Glossia.Analytics.SettingsCache,
        Glossia.Analytics.Geolocation.Ipapi.Cache,
        Glossia.Github.InstallationTokens,
        Glossia.Pomerium.JWKSCache
      ] ++
        setup_recovery_children() ++
        [
          Glossia.Flame.pool_child_spec(),
          # Start to serve requests, typically the last entry
          GlossiaWeb.Endpoint
        ] ++ internal_babel_endpoint_children()

    children =
      if Application.get_env(:glossia, Glossia.OgImage, [])[:enabled] != false do
        List.insert_at(
          children,
          -2,
          {ChromicPDF,
           no_sandbox: true, discard_stderr: false, chrome_args: "--disable-dev-shm-usage"}
        )
      else
        children
      end

    children
  end

  defp setup_recovery_children do
    if Application.get_env(:glossia, Glossia.Projects.SetupRecovery, [])[:enabled] == false do
      []
    else
      [Glossia.Projects.SetupRecovery]
    end
  end

  defp internal_babel_endpoint_children do
    [GlossiaWeb.BabelInternalEndpoint]
  end

  defp role do
    cond do
      Glossia.Flame.child?() -> :isolated_child
      Glossia.TranslationSessions.Job.current?() -> :translation_job
      true -> :parent
    end
  end

  defp flame_child_children do
    []
  end

  # A detached translation pod: everything a translation touches, and nothing
  # that serves. No Endpoint, since it answers no requests, and no FLAME pool,
  # since it is already the isolated compute. Oban is present but consumes
  # nothing: domain events are recorded by enqueueing them, and this pod exits
  # when its translation ends, so running queues here would have it pick up
  # other accounts' work and abandon it half-done.
  defp translation_job_children do
    oban_config =
      :glossia
      |> Application.fetch_env!(Oban)
      |> Keyword.merge(queues: false, plugins: false)

    [
      Glossia.Vault,
      {Finch, name: Glossia.Finch},
      Glossia.Repo,
      Glossia.ClickHouseRepo,
      Glossia.IngestRepo,
      {Oban, oban_config},
      {DNSCluster, query: Application.get_env(:glossia, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Glossia.PubSub},
      FunWithFlags.Supervisor,
      Glossia.RateLimiter,
      {Glossia.Ingestion.Buffer,
       [name: Glossia.Ingestion.EventBuffer] ++
         (Glossia.Ingestion.Event.buffer_opts()
          |> Map.take([:insert_sql, :insert_opts, :header])
          |> Map.to_list())},
      Supervisor.child_spec(
        {Glossia.Ingestion.Buffer,
         [name: Glossia.Ingestion.TranslationSessionEventBuffer, flush_interval_ms: 1_000] ++
           (Glossia.Ingestion.TranslationSessionEvent.buffer_opts()
            |> Map.take([:insert_sql, :insert_opts, :header])
            |> Map.to_list())},
        id: Glossia.Ingestion.TranslationSessionEventBuffer
      ),
      Glossia.Github.InstallationTokens,
      # Last, so the translation only starts once everything it depends on is up.
      Glossia.TranslationSessions.Job
    ]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GlossiaWeb.Endpoint.config_change(changed, removed)
    GlossiaWeb.BabelInternalEndpoint.config_change(changed, removed)
    :ok
  end
end
