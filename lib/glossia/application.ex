defmodule Glossia.Application do
  use Boundary, top_level?: true, deps: [Glossia, GlossiaWeb]

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Oban.Telemetry.attach_default_logger()

    children = [
      # Start the Telemetry supervisor
      GlossiaWeb.Telemetry,
      # Start the Ecto repository
      Glossia.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Glossia.PubSub},
      # Start Finch
      {Finch, name: Glossia.Finch},
      # Start the Endpoint (http/https)
      GlossiaWeb.Endpoint,
      # Start a worker by calling: Glossia.Worker.start_link(arg)
      # {Glossia.Worker, arg}
      {Oban, Application.fetch_env!(:glossia, Oban)},
      {PlugAttack.Storage.Ets, name: GlossiaWeb.Plugs.Attack.Storage, clean_period: 60_000}
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
