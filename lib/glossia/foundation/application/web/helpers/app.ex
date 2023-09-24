defmodule Glossia.Foundation.Application.Web.Helpers.App do
  def html do
    quote do
      use Phoenix.Component
      use PrimerLive

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
        layout: {Glossia.Foundation.Application.Web.Layouts.App, :base}

      use PrimerLive
      import Glossia.Foundation.Application.Web.Helpers.OpenGraph

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
        layouts: [html: Glossia.Foundation.Application.Web.Layouts.App]

      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.controller())
    end
  end

  defp html_helpers() do
    quote do
      import(Glossia.Foundation.Application.Web.Components.Shared)
      import(Glossia.Foundation.Application.Web.Components.App)

      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.html())

      # Routes generation with the ~p sigil
      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.verified_routes())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
