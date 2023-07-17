defmodule GlossiaWeb do
  use Boundary, deps: [Glossia], exports: [Endpoint, Router, UserAuth]

  @moduledoc """
  The module that represents the web interface of Glossia
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

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
        formats: [:html, :json],
        layouts: [html: GlossiaWeb.Layouts]

      import Plug.Conn
      import GlossiaWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {GlossiaWeb.Layouts, :root}

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

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers(:app))
    end
  end

  defp html_helpers(surface) do
    components_import_ast =
      case surface do
        :app -> quote(do: import(GlossiaWeb.AppComponents))
        :marketing -> quote(do: import(GlossiaWeb.MarketingComponents))
        _ -> nil
      end

    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      unquote(components_import_ast)

      import GlossiaWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: GlossiaWeb.Endpoint,
        router: GlossiaWeb.Router,
        statics: GlossiaWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
