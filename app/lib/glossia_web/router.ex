defmodule GlossiaWeb.Router do
  use GlossiaWeb, :router

  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  @compile {:no_warn_undefined,
            [
              GlossiaWeb.AgentScriptController,
              GlossiaWeb.AvatarController,
              GlossiaWeb.GithubInstallCallbackController,
              GlossiaWeb.Plugs.ApiRateLimit,
              GlossiaWeb.Plugs.McpRateLimit,
              GlossiaWeb.RedirectController,
              GlossiaWeb.SitemapController,
              GlossiaWeb.OAuth.DeviceController
            ]}

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

  pipeline :platform do
    plug :put_layout, html: {GlossiaWeb.Layouts, :platform}
  end

  pipeline :user_profile do
    plug :put_layout, html: {GlossiaWeb.Layouts, :user_profile}
  end

  pipeline :admin do
    plug :put_layout, html: {GlossiaWeb.Layouts, :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :ops do
    plug GlossiaWeb.Plugs.OpsAuth
  end

  get "/up", GlossiaWeb.HealthController, :index

  # Agent script serving (Deno fetches TS modules from here)
  scope "/agent/scripts", GlossiaWeb do
    pipe_through :api

    get "/*path", AgentScriptController, :show
  end

  # Webhooks (no session, no CSRF)
  scope "/webhooks", GlossiaWeb do
    pipe_through :api

    post "/stripe", StripeWebhookController, :create
    post "/github", GithubWebhookController, :create
    post "/gitlab", GitlabWebhookController, :create
  end

  # GitHub App install callback (needs browser session for user lookup)
  scope "/callbacks", GlossiaWeb do
    pipe_through :browser

    get "/github/install", GithubInstallCallbackController, :create
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
    post "/device_authorization", DeviceController, :device_authorization
    post "/token", TokenController, :token
    post "/revoke", RevokeController, :revoke
    post "/introspect", IntrospectController, :introspect
  end

  # OAuth2 authorization (requires browser session)
  scope "/oauth", GlossiaWeb.OAuth do
    pipe_through [:browser, :require_auth]

    get "/authorize", AuthorizeController, :authorize
    post "/authorize", AuthorizeController, :authorize
    get "/device", DeviceController, :verify
    post "/device", DeviceController, :submit_code
    post "/device/confirm", DeviceController, :confirm
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

  scope "/avatars", GlossiaWeb do
    pipe_through :api

    get "/:handle/projects/:project_handle", AvatarController, :project
    get "/users/:user_id", AvatarController, :user
  end

  scope "/og", GlossiaWeb do
    pipe_through :api

    get "/marketing/:category/:hash", OgImageController, :marketing
    get "/app/:handle/:hash", OgImageController, :account
    get "/app/:handle/:project/:hash", OgImageController, :project
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
    get "/features", FeatureController, :index
    get "/features/:slug", FeatureController, :show
    get "/changelog", ChangelogController, :index
    get "/changelog/feed.xml", ChangelogController, :feed
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

    get "/sitemap.xml", SitemapController, :show
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
      GlossiaWeb.Plugs.ApiRateLimit,
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

    get "/:handle/tokens", TokenApiController, :index
    post "/:handle/tokens", TokenApiController, :create
    delete "/:handle/tokens/:id", TokenApiController, :revoke

    get "/:handle/oauth-apps", OAuthAppApiController, :index
    post "/:handle/oauth-apps", OAuthAppApiController, :create
    get "/:handle/oauth-apps/:id", OAuthAppApiController, :show
    patch "/:handle/oauth-apps/:id", OAuthAppApiController, :update
    delete "/:handle/oauth-apps/:id", OAuthAppApiController, :delete
    post "/:handle/oauth-apps/:id/regenerate-secret", OAuthAppApiController, :regenerate_secret

    get "/:handle/projects", ProjectApiController, :index
    post "/:handle/projects", ProjectApiController, :create
    get "/:handle/voice", VoiceApiController, :show
    post "/:handle/voice", VoiceApiController, :create
    get "/:handle/voice/history", VoiceApiController, :history
    get "/:handle/glossary", GlossaryApiController, :show
    post "/:handle/glossary", GlossaryApiController, :create
    get "/:handle/glossary/history", GlossaryApiController, :history
    get "/:handle/kits", KitApiController, :index
    get "/:handle/kits/:kit_handle", KitApiController, :show
    post "/:handle/kits", KitApiController, :create
    post "/:handle/kits/:kit_handle/entries", KitApiController, :create_entry
  end

  # MCP server (StreamableHTTP transport)
  scope "/mcp" do
    pipe_through [
      :api,
      GlossiaWeb.Plugs.BearerAuth,
      GlossiaWeb.Plugs.RequireApiAuth,
      GlossiaWeb.Plugs.McpRateLimit,
      GlossiaWeb.Plugs.OtelAttributes
    ]

    forward "/", Hermes.Server.Transport.StreamableHTTP.Plug, server: Glossia.MCP.Server
  end

  # Admin MCP server (super admin only)
  scope "/admin/mcp" do
    pipe_through [
      :api,
      GlossiaWeb.Plugs.BearerAuth,
      GlossiaWeb.Plugs.RequireApiAuth,
      GlossiaWeb.Plugs.McpRateLimit,
      GlossiaWeb.Plugs.RequireSuperAdminApi
    ]

    forward "/", Hermes.Server.Transport.StreamableHTTP.Plug, server: Glossia.Admin.MCP.Server
  end

  # Super admin impersonation (requires browser auth + super admin)
  scope "/admin", GlossiaWeb.Admin do
    pipe_through [:browser, :require_auth, :require_super_admin]

    post "/impersonate", ImpersonationController, :create
    delete "/impersonate", ImpersonationController, :delete
  end

  pipeline :require_super_admin do
    plug GlossiaWeb.Plugs.RequireSuperAdmin
  end

  # Super admin area (access controlled by on_mount hooks)
  scope "/admin", GlossiaWeb.Admin do
    pipe_through [:browser, :admin]

    live_session :admin,
      layout: {GlossiaWeb.Layouts, :admin},
      on_mount: [
        {GlossiaWeb.AdminHooks, :load_user},
        {GlossiaWeb.AdminHooks, :require_super_admin}
      ] do
      live "/", AdminLive, :home
      live "/users", AdminLive, :users
      live "/accounts", AdminLive, :accounts
      live "/discussions", AdminLive, :discussions
      live "/discussions/:discussion_id", AdminLive, :discussion_show
      live "/tickets", AdminLive, :discussions
      live "/tickets/:ticket_id", AdminLive, :discussion_show
    end
  end

  # Authenticated dashboard redirect
  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth, :require_access]

    get "/dashboard", DashboardController, :index
  end

  # Invitation acceptance (browser pipeline, handles auth internally)
  scope "/invitations", GlossiaWeb do
    pipe_through :browser

    get "/:token", InvitationController, :show
    post "/:token/accept", InvitationController, :accept
    post "/:token/decline", InvitationController, :decline
  end

  # GitHub App install redirect (sets session, then redirects to GitHub)
  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth]

    get "/:handle/-/projects/install-github",
        GithubInstallRedirectController,
        :redirect_to_install
  end

  # Redirect old commits URL to activity
  scope "/", GlossiaWeb do
    pipe_through :browser

    get "/:handle/:project/-/commits", RedirectController, :project_activity
  end

  # User settings routes (/-/settings/*, user-scoped, no handle)
  # Must come BEFORE the platform scope to avoid /:handle/:project catching /-/...
  scope "/", GlossiaWeb do
    pipe_through [:browser, :require_auth, :user_profile]

    post "/-/settings/profile/avatar", ProfileAvatarController, :update

    live_session :user_profile,
      layout: {GlossiaWeb.Layouts, :user_profile},
      on_mount: [{GlossiaWeb.ProfileHooks, :load_user_and_require_auth}] do
      live "/-/settings/profile", ProfileLive, :overview
      live "/-/settings/connected-accounts", ProfileLive, :connected_accounts
    end
  end

  # Platform routes (access controlled by on_mount hooks)
  scope "/", GlossiaWeb do
    pipe_through [:browser, :platform]

    live_session :platform,
      layout: {GlossiaWeb.Layouts, :platform},
      on_mount: [
        {GlossiaWeb.PlatformHooks, :load_user},
        {GlossiaWeb.PlatformHooks, :load_account},
        {GlossiaWeb.PlatformHooks, :check_write}
      ] do
      # App routes (/-/ separator disambiguates from project handles)
      live "/:handle/-/voice", DashboardLive, :voice
      live "/:handle/-/voice/suggestion/new", DashboardLive, :voice_suggestion_new
      live "/:handle/-/voice/request/new", DashboardLive, :voice_suggestion_new
      live "/:handle/-/voice/:version", DashboardLive, :voice_version
      live "/:handle/-/glossary", DashboardLive, :glossary
      live "/:handle/-/glossary/suggestion/new", DashboardLive, :glossary_suggestion_new
      live "/:handle/-/glossary/request/new", DashboardLive, :glossary_suggestion_new
      live "/:handle/-/glossary/:version", DashboardLive, :glossary_version
      live "/:handle/-/kits", DashboardLive, :kits
      live "/:handle/-/kits/new", DashboardLive, :kit_new
      live "/:handle/-/kits/:kit_handle", DashboardLive, :kit_show
      live "/:handle/-/kits/:kit_handle/edit", DashboardLive, :kit_edit
      live "/:handle/-/kits/:kit_handle/entries/new", DashboardLive, :kit_entry_new
      live "/:handle/-/kits/:kit_handle/entries/:entry_id", DashboardLive, :kit_entry_edit
      live "/:handle/-/discussions", DashboardLive, :discussions
      live "/:handle/-/discussions/new", DashboardLive, :discussion_new
      live "/:handle/-/discussions/:discussion_number", DashboardLive, :discussion_show
      live "/:handle/-/tickets", DashboardLive, :discussions
      live "/:handle/-/tickets/new", DashboardLive, :discussion_new
      live "/:handle/-/tickets/:ticket_number", DashboardLive, :discussion_show
      live "/:handle/-/members", DashboardLive, :members
      live "/:handle/-/logs", DashboardLive, :logs
      live "/:handle/-/settings/tokens", DashboardLive, :api_tokens
      live "/:handle/-/settings/tokens/new", DashboardLive, :api_tokens_new
      live "/:handle/-/settings/tokens/:token_id", DashboardLive, :api_token_edit
      live "/:handle/-/settings/apps", DashboardLive, :api_apps
      live "/:handle/-/settings/apps/new", DashboardLive, :api_apps_new
      live "/:handle/-/settings/apps/:app_id", DashboardLive, :api_app_edit
      live "/:handle/-/account", DashboardLive, :account
      live "/:handle/-/projects/new", DashboardLive, :project_new

      # Content routes (no /-/, MUST come last)
      live "/:handle", DashboardLive, :account
      live "/:handle/:project/-/settings", DashboardLive, :project_settings
      live "/:handle/:project/-/activity", DashboardLive, :project_activity
      live "/:handle/:project/-/translations", DashboardLive, :project_translations
      live "/:handle/:project/-/sessions/:session_id", DashboardLive, :project_session
      live "/:handle/:project", DashboardLive, :project
    end
  end
end
