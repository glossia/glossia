defmodule GlossiaWeb.Router do
  use GlossiaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GlossiaWeb.Layouts, :root}
    plug :put_layout, html: {GlossiaWeb.Layouts, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug GlossiaWeb.Plugs.Auth
  end

  pipeline :public do
    plug :accepts, ["html"]
    plug :put_root_layout, html: {GlossiaWeb.Layouts, :root}
    plug :put_layout, html: {GlossiaWeb.Layouts, :app}
    plug :put_secure_browser_headers
  end

  pipeline :require_auth do
    plug GlossiaWeb.Plugs.RequireAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  get "/up", GlossiaWeb.HealthController, :index

  scope "/auth", GlossiaWeb do
    pipe_through :browser

    get "/login", AuthController, :login
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :logout
  end

  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth]

    get "/dashboard", DashboardController, :index
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:glossia, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GlossiaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", GlossiaWeb do
    pipe_through :public

    get "/", PageController, :home
    get "/blog", BlogController, :index
    get "/blog/feed.xml", BlogController, :feed
    get "/blog/:slug", BlogController, :show
    get "/docs", DocsController, :index
    get "/docs/:category", DocsController, :category
    get "/docs/:category/:slug", DocsController, :show
    get "/terms", LegalController, :terms
    get "/terms/:date", LegalController, :terms
    get "/privacy", LegalController, :privacy
    get "/privacy/:date", LegalController, :privacy
    get "/cookies", LegalController, :cookies
    get "/cookies/:date", LegalController, :cookies
  end
end
