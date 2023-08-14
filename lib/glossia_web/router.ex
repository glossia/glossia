defmodule GlossiaWeb.Router do
  use GlossiaWeb, :router

  import GlossiaWeb.UserAuth

  # Pipelines

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_and_track_current_user

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
  end

  pipeline :app do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_and_track_current_user
    plug :put_root_layout, html: {GlossiaWeb.AppLayouts, :root}

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
  end

  pipeline :marketing do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_and_track_current_user
    plug :put_root_layout, html: {GlossiaWeb.MarketingLayouts, :root}

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
  end

  pipeline :webhooks do
    plug :accepts, ["json"]
    plug GlossiaWeb.Plugs.RawBodyPassthroughPlug, length: 4_000_000
    # It is important that this comes after `WebhookSignatureWeb.Plugs.RawBodyPassthrough`
    # as it relies on the `:raw_body` being inside the `conn.assigns`.
    plug GlossiaWeb.Plugs.RequirePayloadSignatureMatchPlug
  end

  pipeline :rss do
    plug :accepts, ["xml"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :builder_api do
    plug :accepts, ["json"]
    plug GlossiaWeb.Auth.Resources, :current_project
    plug GlossiaWeb.Auth.Policies, :current_project
  end

  # Marketing
  scope "/", GlossiaWeb do
    pipe_through [:browser]

    get "/", MarketingController, :index
    get "/beta", MarketingController, :beta
    get "/about", MarketingController, :about
    get "/team", MarketingController, :team
    get "/beta-added", MarketingController, :beta_added
    get "/blog", MarketingController, :blog
    get "/blog/posts/:year/:month/:day/:id", MarketingController, :blog_post
    get "/docs/*id", MarketingController, :docs
    get "/changelog", MarketingController, :changelog
  end

  # API
  scope "/api", GlossiaWeb.API do
    pipe_through [:api]
  end

  scope "/builder-api", GlossiaWeb.BuilderAPI do
    pipe_through [:builder_api]
  end

  # RSS
  scope "/", GlossiaWeb do
    pipe_through :rss
    get "/blog/feed.xml", MarketingController, :feed
  end

  # Authentication
  scope "/auth", GlossiaWeb do
    pipe_through [:browser]

    get "/login", AuthController, :login
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :logout
  end

  # Webhooks
  scope "/webhooks", GlossiaWeb do
    pipe_through [:webhooks]

    post "/github", WebhookController, :github
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:glossia, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GlossiaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # scope "/", GlossiaWeb do
  #   pipe_through [:browser, :project]

  #   get "/:account/:project", ProjectController, :show
  # end
end
