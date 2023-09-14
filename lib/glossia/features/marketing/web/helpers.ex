defmodule Glossia.Features.Marketing.Web.Helpers do
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :xml],
        layouts: [html: {Glossia.Features.Marketing.Web.Layouts, :base}]

      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.controller())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      use Glossia.Foundation.Application.Core.SEO

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.html())

      import Glossia.Foundation.Application.Web.Components.Shared
      import Glossia.Features.Marketing.Web.Components

      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.verified_routes())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
