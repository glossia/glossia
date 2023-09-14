defmodule Glossia.Foundation.Application.Web do
  use Boundary, top_level?: true, check: [in: false, out: false]

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :xml],
        layouts: [html: Glossia.Foundation.Application.Web.Layouts.App]

      import Plug.Conn
      import Glossia.Foundation.Application.Core.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Glossia.Foundation.Application.Web.Layouts.App, :root}

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
      use PrimerLive

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

      use Glossia.Foundation.Application.Core.SEO

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
            import(Glossia.Foundation.Application.Web.Components.Shared)
            import(Glossia.Foundation.Application.Web.Components.App)
          end

        :marketing ->
          quote do
            import(Glossia.Foundation.Application.Web.Components.Shared)
            import(Glossia.Features.Marketing.Web.Components)
          end
      end

    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      unquote(components_import_ast)

      import Glossia.Foundation.Application.Core.Gettext

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
        endpoint: Glossia.Foundation.Application.Web.Endpoint,
        router: Glossia.Foundation.Application.Web.Router,
        statics: Glossia.Foundation.Application.Web.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def static_paths, do: ~w(assets fonts images schemas favicons robots.txt builder)
end
