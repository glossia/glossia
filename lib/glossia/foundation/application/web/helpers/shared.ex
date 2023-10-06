defmodule Glossia.Foundation.Application.Web.Helpers.Shared do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def controller do
    quote do
      import Plug.Conn
      import Glossia.Foundation.Application.Core.Gettext
      import Glossia.Foundation.Application.Web.Helpers.OpenGraph

      unquote(Glossia.Foundation.Application.Web.Helpers.Shared.verified_routes())
    end
  end

  def html do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      import Glossia.Foundation.Application.Core.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Glossia.Application.Endpoint,
        router: Glossia.Application.Router,
        statics: Glossia.Foundation.Application.Web.static_paths()
    end
  end
end
