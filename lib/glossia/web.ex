defmodule Glossia.Web do
  use Boundary,
    deps: [
      Glossia,
      Glossia.Accounts,
      Glossia.Analytics,
      Glossia.Projects,
      Glossia.Changelog,
      Glossia.Blog,
      Glossia.Auth,
      Glossia.Foundation.ContentSources.Core
    ],
    exports: [
      {Plugs, []},
      AuthController,
      WebhookController,
      MarketingController,
      UserAuth,
      API.APIController,
      Auth.Resources,
      Auth.Policies
    ]

  def static_paths, do: ~w(assets fonts images schemas favicons robots.txt builder)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :xml],
        layouts: [html: Glossia.Web.AppLayouts]

      import Plug.Conn
      import Glossia.Web.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Glossia.Web.AppLayouts, :root}

      unquote(html_helpers(:app))
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers(:app))
    end
  end

  def app_html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers(:app))
    end
  end

  def marketing_html do
    quote do
      use Phoenix.Component

      use Glossia.Web.SEO

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers(:marketing))
    end
  end

  defp html_helpers(surface) do
    components_import_ast =
      case surface do
        :app ->
          quote do
            import(Glossia.Web.SharedComponents)
            import(Glossia.Web.AppComponents)
          end

        :marketing ->
          quote do
            import(Glossia.Web.SharedComponents)
            import(Glossia.Web.MarketingComponents)
          end
      end

    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      unquote(components_import_ast)

      import Glossia.Web.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def xml do
    quote do
      use Phoenix.Component

      import Phoenix.HTML

      # Include general helpers for rendering HTML
      unquote(html_helpers(:marketing))
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Glossia.Endpoint,
        router: Glossia.Router,
        statics: Glossia.Web.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end