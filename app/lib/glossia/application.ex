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

    Logger.info("Starting Glossia")

    children = children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Glossia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # `Glossia.Application` starts the same `parent_children/0` tree in every
  # environment. A downstream build that boots the same release into other
  # roles (a detached translation-job pod, a runner child) provides a
  # `children/0` override through:
  #
  #     config :glossia, :application, children: {MyApp.Boot, :children, []}
  #
  # The MFA returns the child list this process should start. The default
  # points back at `parent_children/0`.
  defp children do
    case Application.get_env(:glossia, :application, [])[:children] do
      {module, function, args} -> apply(module, function, args)
      nil -> parent_children()
    end
  end

  # Stated rather than inherited from Finch's default, because the translation
  # fan-out is derived from it: see `RepositoryRun.translation_concurrency/2`.
  defp http_pool_size, do: Application.get_env(:glossia, :http_pool_size, 50)

  @doc """
  The default supervision tree for the open-source parent process.

  Public so a downstream `:application` `children:` override can start these
  and add its own on top, keeping one description of the tree here.
  """
  def parent_children do
    children =
      [
        Glossia.Vault,
        {Finch, name: Glossia.Finch, pools: %{default: [size: http_pool_size()]}},
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
        Glossia.OgImage.Cache,
        {Task.Supervisor, name: Glossia.OgImage.Tasks},
        Glossia.Analytics.Geolocation.Ipapi.Cache,
        Glossia.Github.InstallationTokens,
        Glossia.Pomerium.JWKSCache
      ] ++
        setup_recovery_children() ++
        [
          Glossia.Runners.pool_child_spec(),
          # Start to serve requests, typically the last entry
          GlossiaWeb.Endpoint
        ] ++ internal_babel_endpoint_children()

    children =
      if Application.get_env(:glossia, Glossia.OgImage, [])[:enabled] != false do
        List.insert_at(
          children,
          -2,
          Browse.child_spec(Glossia.OgImage.BrowserPool,
            implementation: BrowseChrome.Browser,
            pool_size: 2
          )
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

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GlossiaWeb.Endpoint.config_change(changed, removed)
    GlossiaWeb.BabelInternalEndpoint.config_change(changed, removed)
    :ok
  end
end
