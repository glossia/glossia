defmodule GlossiaWeb.Router do
  # Modules
  use Phoenix.Router, helpers: false
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Oban.Web.Router

  ##### Base pipelines #####

  pipeline :browser do
    plug :accepts, ["html"]

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()

    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Loads the project from the slug in the URL
  pipeline :load_url_project do
    plug Glossia.Foundation.Projects.Web.Plugs.ResourcesPlug, :url_project
  end

  pipeline :marketing do
    plug :put_root_layout, html: {Glossia.Features.Marketing.Web.Layouts, :root}
  end

  scope "/", Glossia.Features.Marketing.Web.Controllers do
    pipe_through [:browser, :marketing]

    get "/", MarketingController, :index
    get "/beta", MarketingController, :beta
    get "/about", MarketingController, :about
    get "/team", MarketingController, :team
    get "/beta-added", MarketingController, :beta_added
    get "/blog", MarketingController, :blog
    get "/blog/posts/:year/:month/:day/:id", MarketingController, :blog_post
    # get "/docs/*id", MarketingController, :docs
  end

  pipeline :docs do
    plug :put_root_layout, html: {Glossia.Features.Docs.Web.Layouts, :root}
  end

  scope "/", Glossia.Features.Docs.Web.Controllers do
    pipe_through [:browser, :docs]

    get "/docs", DocsController, :show
    get "/docs/*id", DocsController, :show
  end

  ##### API Routes #####

  pipeline :api do
    plug :accepts, ["json"]

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()

    plug OpenApiSpex.Plug.PutApiSpec, module: Glossia.Application.APISpec
  end

  pipeline :load_authenticated_project do
    # The build environments authenticate projects using a token generated for them.
    plug Glossia.Foundation.Projects.Web.Plugs.ResourcesPlug, :authenticated_project
  end

  pipeline :ensure_authenticated_project_present do
    plug Glossia.Foundation.Projects.Web.Plugs.PoliciesPlug, :authenticated_project_present
  end

  # Authenticated builder API endpoints:
  # These endpoints authenticate and authorize the authenticated entities
  scope "/api/v1" do
    pipe_through [
      :api,
      :load_authenticated_project,
      :ensure_authenticated_project_present,
      :load_url_project
    ]

    scope "/projects/:owner_handle/:project_handle",
          Glossia.Foundation.Localizations.Web.API.Controllers do
      resources "/localizations", LocalizationController, only: [:create]
    end
  end

  # Unauthenticated builder API endpoints:
  # There are some endpoints, like the one that returns the OpenAPI spec, that don't
  # require being authenticated because they don't return resource-tied data.
  scope "/api/v1" do
    pipe_through [:api]

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
    match(:*, "/*path", Glossia.Foundation.Builds.Web.Controllers.APIController, :not_found)
  end

  ##### RSS Routes #####
  pipeline :rss do
    plug :accepts, ["xml"]
  end

  scope "/", Glossia.Features.Marketing.Web.Controllers do
    pipe_through [:rss]
    get "/blog/feed.xml", MarketingController, :feed
  end

  ##### Webhook Routes #####
  pipeline :webhooks do
    plug :accepts, ["json"]
    plug Glossia.Foundation.Application.Web.Plugs.RawBodyPassthroughPlug, length: 4_000_000
    # It is important that this comes after `WebhookSignatureWeb.Plugs.RawBodyPassthrough`
    # as it relies on the `:raw_body` being inside the `conn.assigns`.
    plug Glossia.Foundation.ContentSources.Web.Plug
  end

  scope "/webhooks" do
    pipe_through [:webhooks]

    post "/github",
         Glossia.Foundation.ContentSources.Web.Controllers.GitHub.WebhookController,
         :github

    post "/stripe",
         Glossia.Foundation.Payments.Web.Controllers.StripeWebhooksController,
         :create
  end

  ##### App Routes #####

  pipeline :app do
    plug :put_root_layout, html: {Glossia.Foundation.Application.Web.Layouts.App, :root}
  end

  pipeline :load_authenticated_user do
    plug Glossia.Foundation.Accounts.Web.Plugs.ResourcesPlug, :authenticated_user
  end

  pipeline :authenticated_user_present do
    plug Glossia.Foundation.Accounts.Web.Plugs.PoliciesPlug, :authenticated_user_present
  end

  pipeline :track_project do
    plug Glossia.Foundation.Projects.Web.Plugs.RedirectToProjectIfNeededPlug
    plug Glossia.Foundation.Projects.Web.Plugs.SaveLastVisitedProjectPlug
  end

  pipeline :authorize_project_access do
    plug Glossia.Foundation.Projects.Web.Plugs.PoliciesPlug, {:read, :project}
  end

  pipeline :ensure_authenticated_user_is_admin do
    plug Glossia.Foundation.Accounts.Web.Plugs.PoliciesPlug, :authenticate_user_is_admin
  end

  scope "/admin" do
    pipe_through [
      :browser,
      :app,
      :load_authenticated_user,
      :authenticated_user_present,
      :ensure_authenticated_user_is_admin
    ]

    oban_dashboard("/oban")
  end

  scope "/auth", Glossia.Foundation.Accounts.Web.Controllers do
    pipe_through [:browser, :app]

    get "/login", AuthController, :login
    post "/logout", AuthController, :logout

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
  end

  scope "/" do
    pipe_through [
      :browser,
      :app,
      :load_authenticated_user,
      :load_url_project,
      :authorize_project_access,
      :track_project
    ]

    get "/:owner_handle/:project_handle",
        Glossia.Foundation.Projects.Web.Controllers.ProjectController,
        :show
  end

  scope "/" do
    pipe_through [:browser, :app, :load_authenticated_user, :authenticated_user_present]

    live_session :authenticated_user,
      on_mount: {Glossia.Foundation.Accounts.Web.LiveViews.AuthLiveView, :authenticated_user} do
      live "/new", Glossia.Foundation.Projects.Web.LiveViews.NewLiveView
      live "/settings", Glossia.Foundation.Accounts.Web.LiveViews.SettingsLiveView
    end
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
end
