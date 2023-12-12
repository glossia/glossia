defmodule GlossiaWeb.Helpers.App do
  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {GlossiaWeb.Layouts.App, :app},
        container: {:div, class: "h-full"}

      import GlossiaWeb.Helpers.OpenGraph

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :xml],
        layouts: [html: GlossiaWeb.Layouts.App]

      import InertiaPhoenix.Controller

      unquote(GlossiaWeb.Helpers.Shared.controller())
    end
  end

  def verified_routes do
    quote do
      unquote(GlossiaWeb.Helpers.Shared.verified_routes())
    end
  end

  defp html_helpers() do
    quote do
      import(GlossiaWeb.Components.Shared)
      import(GlossiaWeb.Components.App)

      unquote(GlossiaWeb.Helpers.Shared.html())

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
