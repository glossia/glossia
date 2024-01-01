defmodule Glossia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    flame_parent = FLAME.Parent.get()

    Glossia.Secrets.load()

    Oban.Telemetry.attach_default_logger()

    :telemetry.attach(
      "oban-errors",
      [:oban, :job, :exception],
      &Glossia.Support.ErrorReporter.handle_event/4,
      []
    )

    children =
      [
        GlossiaWeb.Telemetry,
        Glossia.Repo,
        {Phoenix.PubSub, name: Glossia.PubSub},
        {Finch,
         name: Glossia.Finch,
         pools: %{
           "https://api.openai.com" => [
             size: 10,
             conn_opts: [recv_timeout: :timer.minutes(5), send_timeout: :timer.minutes(5)]
           ]
         }},
        {FLAME.Pool,
         name: Glossia.EventProcessor,
         min: 0,
         max: 10,
         max_concurrency: 1,
         idle_shutdown_after: 10_000,
         log: :debug},
        !flame_parent && GlossiaWeb.Endpoint,
        !flame_parent && {Oban, Application.fetch_env!(:glossia, Oban)},
        {Task.Supervisor, name: Glossia.TaskSupervisor}
      ] ++ google_cloud_children()

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

  defp google_cloud_children() do
    case Glossia.Secrets.get_in([:google_cloud, :application_credentials_json_base_64]) do
      "" ->
        []

      nil ->
        []

      base_64 ->
        credentials = Jason.decode!(Base.decode64!(base_64))

        [
          {Goth, name: Glossia.Goth, source: {:service_account, credentials}}
        ]
    end
  end
end
