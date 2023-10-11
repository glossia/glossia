defmodule GlossiaWeb.Helpers.Shared do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def controller do
    quote do
      import Plug.Conn
      import GlossiaWeb.Gettext
      import GlossiaWeb.Helpers.OpenGraph

      unquote(GlossiaWeb.Helpers.Shared.verified_routes())
    end
  end

  def html do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML

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
end
