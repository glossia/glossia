defmodule BabelWeb.Router do
  use BabelWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BabelWeb.Layouts, :root}
    plug :put_layout, html: {BabelWeb.Layouts, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :operations do
    plug BabelWeb.Plugs.PomeriumAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  get "/up", BabelWeb.HealthController, :index

  scope "/.well-known", BabelWeb do
    pipe_through :api

    get "/oauth-authorization-server", WellKnownController, :oauth_authorization_server
    get "/oauth-protected-resource", WellKnownController, :oauth_protected_resource
    get "/oauth-protected-resource/mcp", WellKnownController, :oauth_protected_resource
  end

  scope "/oauth", BabelWeb.OAuth do
    pipe_through :api

    post "/register", RegisterController, :register
    post "/token", TokenController, :token
  end

  scope "/oauth", BabelWeb.OAuth do
    pipe_through [:browser, :operations]

    get "/authorize", AuthorizeController, :authorize
    post "/authorize", AuthorizeController, :authorize
  end

  scope "/mcp" do
    pipe_through [:api, BabelWeb.Plugs.OAuthBearerAuth, BabelWeb.Plugs.RequireMcpAuth]

    forward "/", Hermes.Server.Transport.StreamableHTTP.Plug, server: Babel.MCP.Server
  end

  scope "/", BabelWeb do
    pipe_through [:browser, :operations]

    live "/", OperationsLive, :overview
    live "/growth", OperationsLive, :go_to_market
    live "/organizations", OperationsLive, :organizations
    live "/organizations/:id", OperationsLive, :organization
  end

  if Application.compile_env(:babel, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BabelWeb.Telemetry
    end
  end
end
