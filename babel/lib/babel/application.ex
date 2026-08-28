defmodule Babel.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Babel.Repo,
      {DNSCluster, query: Application.get_env(:babel, :dns_cluster_query) || :ignore},
      Babel.Pomerium.JWKSCache,
      {Phoenix.PubSub, name: Babel.PubSub},
      BabelWeb.Telemetry,
      Hermes.Server.Registry,
      %{
        id: Babel.MCP.Server,
        start:
          {Hermes.Server.Supervisor, :start_link,
           [Babel.MCP.Server, [transport: :streamable_http]]}
      },
      BabelWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Babel.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BabelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
