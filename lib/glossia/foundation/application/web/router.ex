defmodule Glossia.Foundation.Application.Web.Router do
  use Boundary, top_level?: true, check: [out: false]

  # Modules
  use Glossia.Foundation.Application.Web, :router
  import Glossia.Foundation.Accounts.Web.Auth
  import Glossia.Foundation.Utilities.Core.Plan

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
    plug :fetch_and_track_current_user
  end

  # Loads the project from the slug in the URL
  pipeline :project do
    plug Glossia.Foundation.Projects.Web.Plugs.AssignProjectFromURLPlug
  end

  #### Documentation Routes ####

  scope "/" do
    get "/docs/api", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  ##### Marketing Routes #####
  pipeline :marketing do
    plug :put_root_layout, html: {Glossia.Features.Marketing.Web.Components.Layouts, :root}
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
    get "/docs/*id", MarketingController, :docs
  end

  ##### API Routes #####

  pipeline :api do
    plug :accepts, ["json"]

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()

    plug OpenApiSpex.Plug.PutApiSpec, module: Glossia.Foundation.API.Core.Spec
  end

  pipeline :api_auth do
    plug Glossia.Foundation.Accounts.Web.Resources, :authenticated_project
    plug Glossia.Foundation.Accounts.Web.Policies, :authenticated_project
  end

  # Authenticated API endpoints:
  # These endpoints authenticate and authorize the authenticated entities
  scope "/api" do
    pipe_through [:api, :api_auth, :project]

    scope "/projects/:owner_handle/:project_handle",
          Glossia.Foundation.API.Web.Controllers.Project do
      resources "/localization-requests", LocalizationRequestController, only: [:create]
    end
  end

  # Unauthenticated API endpoints:
  # There are some endpoints, like the one that returns the OpenAPI spec, that don't
  # require being authenticated because they don't return resource-tied data.
  scope "/api" do
    pipe_through [:api]

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
    match(:*, "/*path", Glossia.Web.API.APIController, :not_found)
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

  scope "/webhooks", Glossia.Web do
    pipe_through [:webhooks]
    post "/github", WebhookController, :github
  end

  ##### App Routes #####
  pipeline :app do
    plug :put_root_layout, html: {Glossia.Foundation.Application.Web.Layouts.App, :root}
  end

  scope "/auth", Glossia.Foundation.Accounts.Web.Controllers do
    pipe_through [:browser, :app]

    get "/login", AuthController, :login
    post "/logout", AuthController, :logout

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
  end

  scope "/admin" do
    pipe_through [:browser, :app]

    only_for_plans([:cloud]) do
      import Oban.Web.Router
      oban_dashboard("/oban")
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

      live_dashboard "/dashboard", metrics: Glossia.Foundation.Application.Core.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
