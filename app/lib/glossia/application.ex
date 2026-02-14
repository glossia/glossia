defmodule Glossia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Glossia.OTel.setup()
    Logger.add_handlers(:glossia)

    children = [
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
      {Glossia.Ingestion.Buffer,
       [name: Glossia.Ingestion.EventBuffer] ++
         (Glossia.Ingestion.Event.buffer_opts()
          |> Map.take([:insert_sql, :insert_opts, :header])
          |> Map.to_list())},
      # Start to serve requests, typically the last entry
      GlossiaWeb.Endpoint
    ]

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
