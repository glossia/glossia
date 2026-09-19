defmodule BabelWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :babel

  @session_options [
    store: :cookie,
    key: "_babel_key",
    signing_salt: "rZVUwFiQ",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :babel,
    gzip: not code_reloading?,
    only: BabelWeb.static_paths(),
    only_matching: ~w(favicon),
    raise_on_missing_only: code_reloading?

  if code_reloading? and Code.ensure_loaded?(Phoenix.LiveReloader) do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :babel
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BabelWeb.Router
end
