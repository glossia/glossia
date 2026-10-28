defmodule Glossia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Glossia.Ingestion

  require Logger

  @compile {:no_warn_undefined, [LLMDB]}

  @impl true
  def start(_type, _args) do
    Glossia.OTel.setup()
    Logger.add_handlers(:glossia)
    {:ok, _} = LLMDB.load()

    Logger.info("Starting Glossia")

    children = children()

    opts = [strategy: :one_for_one, name: Glossia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children do
    Glossia.Extensions.translation_runtime().children() || parent_children()
  end

  defp http_pool_size, do: Application.get_env(:glossia, :http_pool_size, 50)

  defp parent_children do
    children =
      [
        Glossia.Vault,
        {Finch, name: Glossia.Finch, pools: %{default: [size: http_pool_size()]}},
        Glossia.PromEx,
        GlossiaWeb.Telemetry,
        Glossia.Repo,
        Glossia.ClickHouseRepo,
        Glossia.IngestRepo,
        Glossia.Push.Supervisor,
        {Oban, Application.fetch_env!(:glossia, Oban)},
        {DNSCluster, query: Application.get_env(:glossia, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Glossia.PubSub},
        FunWithFlags.Supervisor,
        Glossia.Docs.SearchIndexer,
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
        Supervisor.child_spec(
          {Ingestion.Buffer,
           [name: Ingestion.TranslationSessionEventBuffer, flush_interval_ms: 1_000] ++
             (Ingestion.TranslationSessionEvent.buffer_opts()
              |> Map.take([:insert_sql, :insert_opts, :header])
              |> Map.to_list())},
          id: Ingestion.TranslationSessionEventBuffer
        ),
        Supervisor.child_spec(
          {Ingestion.Buffer,
           [name: Glossia.Analytics.EventBuffer, flush_interval_ms: 1_000] ++
             (Glossia.Analytics.Event.buffer_opts()
              |> Map.take([:insert_sql, :insert_opts, :header])
              |> Map.to_list())},
          id: Glossia.Analytics.EventBuffer
        ),
        Supervisor.child_spec(
          {Ingestion.Buffer,
           [name: Ingestion.SetupEventBuffer, flush_interval_ms: 1_000] ++
             (Glossia.Ingestion.SetupEvent.buffer_opts()
              |> Map.take([:insert_sql, :insert_opts, :header])
              |> Map.to_list())},
          id: Ingestion.SetupEventBuffer
        ),
        Glossia.Analytics.SettingsCache,
        Glossia.OgImage.Cache,
        {Task.Supervisor, name: Glossia.OgImage.Tasks},
        Glossia.Analytics.Geolocation.Ipapi.Cache,
        Glossia.Github.InstallationTokens,
        Glossia.Pomerium.JWKSCache,
        Glossia.Sandbox.ProcessRegistry,
        {DynamicSupervisor, name: Glossia.Sandbox.Supervisor, strategy: :one_for_one},
        Glossia.Sandbox.Reaper,
        Glossia.Projects.SetupRecovery
      ] ++
        Glossia.Extensions.audit_children() ++
        Glossia.Extensions.translation_runtime().parent_children() ++
        [
          GlossiaWeb.Endpoint
        ] ++ internal_babel_endpoint_children()

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
