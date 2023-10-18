defmodule GlossiaWeb.Helpers.Marketing do
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :xml],
        layouts: [html: {GlossiaWeb.Layouts.Marketing, :app}]

      unquote(GlossiaWeb.Helpers.Shared.controller())
    end
  end

  def verified_routes do
    quote do
      unquote(GlossiaWeb.Helpers.Shared.verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(GlossiaWeb.Helpers.Shared.html())

      import GlossiaWeb.Components.Shared
      import GlossiaWeb.Components.Marketing

      unquote(verified_routes())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
