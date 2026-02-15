defmodule GlossiaWeb.Router do
  use GlossiaWeb, :router

  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GlossiaWeb.Layouts, :root}
    plug :put_layout, html: {GlossiaWeb.Layouts, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug GlossiaWeb.Plugs.Auth
    plug GlossiaWeb.Plugs.OtelAttributes
  end

  pipeline :public do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, html: {GlossiaWeb.Layouts, :root}
    plug :put_layout, html: {GlossiaWeb.Layouts, :app}
    plug :put_secure_browser_headers
    plug GlossiaWeb.Plugs.Auth
    plug GlossiaWeb.Plugs.OtelAttributes
  end

  pipeline :require_auth do
    plug GlossiaWeb.Plugs.RequireAuth
  end

  pipeline :require_access do
    plug GlossiaWeb.Plugs.RequireAccess
  end

  pipeline :dashboard do
    plug :put_layout, html: {GlossiaWeb.Layouts, :dashboard}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :ops do
    plug GlossiaWeb.Plugs.OpsAuth
  end

  get "/up", GlossiaWeb.HealthController, :index

  # Webhooks (no session, no CSRF)
  scope "/webhooks", GlossiaWeb do
    pipe_through :api

    post "/stripe", StripeWebhookController, :create
    post "/github", GithubWebhookController, :create
    post "/gitlab", GitlabWebhookController, :create
  end

  scope "/auth", GlossiaWeb do
    pipe_through :browser

    get "/login", AuthController, :login
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :logout
  end

  if Application.compile_env(:glossia, :dev_routes) do
    scope "/auth", GlossiaWeb do
      pipe_through :browser

      post "/dev-login", AuthController, :dev_login
    end
  end

  # Swoosh mailbox preview in development
  if Application.compile_env(:glossia, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/ops" do
    pipe_through [:browser, :ops]

    get "/", GlossiaWeb.OpsRedirectController, :index
    live_dashboard "/dashboard", metrics: GlossiaWeb.Telemetry
    oban_dashboard("/oban")
  end

  # OAuth2 provider API endpoints (MCP clients authenticate here)
  scope "/oauth", GlossiaWeb.OAuth do
    pipe_through :api

    post "/register", RegisterController, :register
    post "/token", TokenController, :token
    post "/revoke", RevokeController, :revoke
    post "/introspect", IntrospectController, :introspect
  end

  # OAuth2 authorization (requires browser session)
  scope "/oauth", GlossiaWeb.OAuth do
    pipe_through [:browser, :require_auth]

    get "/authorize", AuthorizeController, :authorize
    post "/authorize", AuthorizeController, :authorize
  end

  # OpenAPI spec
  scope "/api", GlossiaWeb do
    pipe_through :api

    get "/openapi.json", OpenApiController, :show
  end

  # MCP auth discovery (RFC 8414, RFC 9728)
  scope "/.well-known", GlossiaWeb do
    pipe_through :api

    get "/oauth-authorization-server", WellKnownController, :oauth_authorization_server
    get "/oauth-protected-resource", WellKnownController, :oauth_protected_resource
  end

  scope "/docs", GlossiaWeb do
    pipe_through :api

    get "/search.json", DocsController, :search_index
  end

  scope "/", GlossiaWeb do
    pipe_through :public

    get "/", PageController, :home
    get "/blog", BlogController, :index
    get "/blog/feed.xml", BlogController, :feed
    get "/blog/:slug", BlogController, :show
    get "/docs", DocsController, :index
    get "/docs/:category", DocsController, :category
    get "/docs/:category/:subcategory/:slug", DocsController, :subcategory_page
    get "/docs/:category/:slug", DocsController, :show
    get "/terms", LegalController, :terms
    get "/terms/:date", LegalController, :terms
    get "/privacy", LegalController, :privacy
    get "/privacy/:date", LegalController, :privacy
    get "/cookies", LegalController, :cookies
    get "/cookies/:date", LegalController, :cookies
  end

  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth]

    get "/interest", WaitlistController, :new
    post "/interest", WaitlistController, :create

    get "/billing", BillingController, :show
    post "/billing/checkout", BillingController, :checkout
    get "/billing/return", BillingController, :return
    post "/billing/portal", BillingController, :portal
  end

  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth, :require_access]

    get "/organizations/new", OrganizationController, :new
    post "/organizations", OrganizationController, :create
  end

  # Authenticated API
  scope "/api", GlossiaWeb.Api do
    pipe_through [
      :api,
      GlossiaWeb.Plugs.BearerAuth,
      GlossiaWeb.Plugs.RequireApiAuth,
      GlossiaWeb.Plugs.OtelAttributes
    ]

    get "/accounts", AccountApiController, :index

    get "/organizations", OrganizationApiController, :index
    post "/organizations", OrganizationApiController, :create
    get "/organizations/:handle", OrganizationApiController, :show
    patch "/organizations/:handle", OrganizationApiController, :update
    delete "/organizations/:handle", OrganizationApiController, :delete
    get "/organizations/:handle/members", OrganizationApiController, :list_members

    delete "/organizations/:handle/members/:user_handle",
           OrganizationApiController,
           :remove_member

    get "/organizations/:handle/invitations", OrganizationApiController, :list_invitations
    post "/organizations/:handle/invitations", OrganizationApiController, :create_invitation

    delete "/organizations/:handle/invitations/:invitation_id",
           OrganizationApiController,
           :revoke_invitation

    get "/:handle/projects", ProjectApiController, :index
    get "/:handle/voice", VoiceApiController, :show
    post "/:handle/voice", VoiceApiController, :create
    get "/:handle/voice/history", VoiceApiController, :history
    get "/:handle/glossary", GlossaryApiController, :show
    post "/:handle/glossary", GlossaryApiController, :create
    get "/:handle/glossary/history", GlossaryApiController, :history
  end

  # MCP server (StreamableHTTP transport)
  scope "/mcp" do
    pipe_through [
      :api,
      GlossiaWeb.Plugs.BearerAuth,
      GlossiaWeb.Plugs.RequireApiAuth,
      GlossiaWeb.Plugs.OtelAttributes
    ]

    forward "/", Hermes.Server.Transport.StreamableHTTP.Plug, server: Glossia.MCP.Server
  end

  # Authenticated dashboard redirect
  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth, :require_access, :dashboard]

    get "/dashboard", DashboardController, :index
  end

  # Invitation acceptance (browser pipeline, handles auth internally)
  scope "/invitations", GlossiaWeb do
    pipe_through :browser

    get "/:token", InvitationController, :show
    post "/:token/accept", InvitationController, :accept
    post "/:token/decline", InvitationController, :decline
  end

  # Dashboard LiveView (access controlled by on_mount hooks)
  scope "/", GlossiaWeb do
    pipe_through [:browser, :dashboard]

    live_session :dashboard,
      layout: {GlossiaWeb.Layouts, :dashboard},
      on_mount: [
        {GlossiaWeb.DashboardHooks, :load_user},
        {GlossiaWeb.DashboardHooks, :load_account},
        {GlossiaWeb.DashboardHooks, :check_write}
      ] do
      live "/:handle/logs", DashboardLive, :logs
      live "/:handle/voice", DashboardLive, :voice
      live "/:handle/voice/:version", DashboardLive, :voice_version
      live "/:handle/glossary", DashboardLive, :glossary
      live "/:handle/glossary/:version", DashboardLive, :glossary_version
      live "/:handle/members", DashboardLive, :members
      live "/:handle", DashboardLive, :account
      live "/:handle/:project", DashboardLive, :project
    end
  end
end
