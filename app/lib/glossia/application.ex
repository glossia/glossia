defmodule Glossia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @compile {:no_warn_undefined, [LLMDB]}

  @impl true
  def start(_type, _args) do
    Glossia.OTel.setup()
    Logger.add_handlers(:glossia)
    {:ok, _} = LLMDB.load()

    children = [
      Glossia.Vault,
      {Finch,
       name: Glossia.Finch,
       pools: %{
         "https://api.minimax.io" => [
           size: 5,
           count: 1,
           conn_opts: [transport_opts: [timeout: 60_000]]
         ],
         "https://app.daytona.io" => [
           size: 5,
           count: 1,
           conn_opts: [transport_opts: [timeout: 30_000]]
         ],
         :default => [size: 10, count: 1]
       }},
      Glossia.PromEx,
      GlossiaWeb.Telemetry,
      Glossia.Repo,
      Glossia.ClickHouseRepo,
      Glossia.IngestRepo,
      {Oban, Application.fetch_env!(:glossia, Oban)},
      {DNSCluster, query: Application.get_env(:glossia, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Glossia.PubSub},
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
      # Start to serve requests, typically the last entry
      GlossiaWeb.Endpoint
    ]

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

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Glossia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GlossiaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
