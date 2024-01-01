defmodule GlossiaWeb.Router do
  @moduledoc false
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Plug.Conn
  import Redirect
  import Glossia.Flavor
  use Phoenix.Router, helpers: false

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
    plug GlossiaWeb.Auth, :load_authenticated_subject
  end

  pipeline :tracking do
    plug GlossiaWeb.LiveViewMountablePlug, :track_page
  end

  pipeline :load_url_project do
    plug GlossiaWeb.LiveViewMountablePlug, :load_url_project
  end

  pipeline :marketing do
    plug :put_root_layout, html: {GlossiaWeb.Layouts.Marketing, :root}
  end

  only_for_flavors [:cloud] do
    scope "/", GlossiaWeb.Controllers do
      pipe_through [:browser, :marketing, :tracking]

      get "/", MarketingController, :index
      get "/beta", MarketingController, :beta
      get "/about", MarketingController, :about
      get "/team", MarketingController, :team
      get "/beta-added", MarketingController, :beta_added
      get "/blog", MarketingController, :blog
      get "/blog/posts/:year/:month/:day/:id", MarketingController, :blog_post
      get "/terms", MarketingController, :terms
      get "/privacy", MarketingController, :privacy
    end
  end

  pipeline :docs do
    plug :put_root_layout, html: {GlossiaWeb.Layouts.Docs, :root}
  end

  only_for_flavors [:cloud] do
    # We read the value from the compiled docs to ensure if the slug changes the compilation of the router fails.
    whats_glossia_docs_slug =
      Glossia.Docs.Content.pages()
      |> Enum.find(&(&1.slug == "users/what-is-glossia"))
      |> Map.get(:slug)

    redirect("/docs", "/docs/#{whats_glossia_docs_slug}", :permanent)

    scope "/", GlossiaWeb.Controllers do
      pipe_through [:browser, :docs, :tracking]

      for page <- Glossia.Docs.Content.pages() do
        get "/docs/#{page.slug}", DocsController, :show
      end
    end
  end

  ##### API Routes #####

  pipeline :api do
    plug :accepts, ["json"]

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()

    plug OpenApiSpex.Plug.PutApiSpec, module: GlossiaWeb.APISpec
    plug GlossiaWeb.Auth, :load_authenticated_subject
  end

  # Authenticated builder API endpoints:
  # These endpoints authenticate and authorize the authenticated entities
  scope "/api/v1" do
    pipe_through [
      :api,
      :ensure_authenticated_subject_present,
      :load_url_project,
      :tracking
    ]

    scope "/projects/:owner_handle/:project_handle",
          GlossiaWeb.Controllers.API do
      resources "/localizations", LocalizationController, only: [:create]
    end
  end

  # Unauthenticated builder API endpoints:
  # There are some endpoints, like the one that returns the OpenAPI spec, that don't
  # require being authenticated because they don't return resource-tied data.
  scope "/api/v1" do
    pipe_through [:api, :tracking]

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
    match(:*, "/*path", GlossiaWeb.Controllers.API.APIController, :not_found)
  end

  ##### RSS Routes #####
  pipeline :rss do
    plug :accepts, ["xml"]
  end

  only_for_flavors [:cloud] do
    scope "/", GlossiaWeb.Controllers do
      pipe_through [:rss, :tracking]
      get "/blog/feed.xml", MarketingController, :feed
    end
  end

  ##### Webhook Routes #####
  pipeline :webhooks do
    plug :accepts, ["json"]
    plug GlossiaWeb.Plugs.RawBodyPassthroughPlug, length: 4_000_000
    # It is important that this comes after `WebhookSignatureWeb.Plugs.RawBodyPassthrough`
    # as it relies on the `:raw_body` being inside the `conn.assigns`.
    plug GlossiaWeb.Plugs.ValidateGitHubWebhookPlug
  end

  scope "/webhooks" do
    pipe_through [:webhooks]

    post "/github",
         GlossiaWeb.Controllers.Webhooks.GitHubWebhooksController,
         :github

    post "/stripe", GlossiaWeb.Controllers.Webhooks.StripeWebhooksController, :create
  end

  ##### App Routes #####

  pipeline :app do
    plug :put_root_layout, html: {GlossiaWeb.Layouts.App, :root}
  end

  pipeline :ensure_authenticated_subject_present do
    plug GlossiaWeb.Auth, :ensure_authenticated_subject_present
  end

  pipeline :ensure_authenticated_subject_can_read_admin do
    plug Glossia.Authorization.Plug,
      policy: Glossia.Admin,
      action: :read,
      subject: {GlossiaWeb.Auth, :authenticated_subject}
  end

  pipeline :project do
    plug GlossiaWeb.LiveViewMountablePlug, :project
  end

  scope "/admin" do
    pipe_through [
      :browser,
      :app,
      :ensure_authenticated_subject_present,
      :ensure_authenticated_subject_can_read_admin,
      :tracking
    ]
  end

  scope "/auth", GlossiaWeb.Controllers do
    pipe_through [:browser, :app, :tracking]

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
      :project
    ]

    live_session :project_live_session,
      on_mount: {GlossiaWeb.LiveViewMountablePlug, :project_live_session} do
      live "/:owner_handle/:project_handle", GlossiaWeb.LiveViews.Projects.Dashboard
      live "/:owner_handle/:project_handle/versions", GlossiaWeb.LiveViews.Projects.Versions
      live "/:owner_handle/:project_handle/events", GlossiaWeb.LiveViews.Projects.Events

      live "/:owner_handle/:project_handle/localizations",
           GlossiaWeb.LiveViews.Projects.Localizations

      live "/:owner_handle/:project_handle/settings", GlossiaWeb.LiveViews.Projects.Settings
    end
  end

  scope "/" do
    pipe_through [
      :browser,
      :app,
      :ensure_authenticated_subject_present,
      :tracking
    ]

    live_session :authenticated_user,
      layout: {GlossiaWeb.Layouts.App, :empty},
      on_mount: {GlossiaWeb.LiveViews.AuthLiveView, :authenticated_user} do
      live "/new", GlossiaWeb.LiveViews.Projects.New
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
