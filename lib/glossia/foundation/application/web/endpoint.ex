defmodule Glossia.Foundation.Application.Web.Endpoint do
  use Boundary, top_level?: true, check: [out: false, in: false]

  use Phoenix.Endpoint, otp_app: :glossia

  plug RemoteIp
  plug Glossia.Foundation.Application.Web.Plugs.AttackPlug

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_glossia_key",
    signing_salt: "1YJLDOEElsf0Hwky+QOJ74mzTj1xUBstZj+GEMCFCZxpqdnLskZkAUJDCpr/yHqs",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :glossia,
    gzip: false,
    only: Glossia.Foundation.Application.Web.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :glossia
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug(Plug.Static,
    at: "/primer_live",
    from: {:primer_live, "priv/static"}
  )

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug Glossia.Foundation.Application.Web.Router
end