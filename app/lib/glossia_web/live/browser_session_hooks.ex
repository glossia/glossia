defmodule GlossiaWeb.BrowserSessionHooks do
  @moduledoc false
  use GlossiaWeb, :verified_routes
  import Phoenix.Component, only: [assign: 3]

  def attach(socket, session) do
    socket
    |> assign(:browser_session, session)
    |> assign(:browser_token, session["browser_token"])
    |> Phoenix.LiveView.attach_hook(:browser_auth_events, :handle_event, fn _, _, socket ->
      check(socket)
    end)
    |> Phoenix.LiveView.attach_hook(:browser_auth_params, :handle_params, fn _, _, socket ->
      check(socket)
    end)
    |> Phoenix.LiveView.attach_hook(:browser_auth_info, :handle_info, fn _, socket ->
      check(socket)
    end)
    |> Phoenix.LiveView.attach_hook(:browser_auth_async, :handle_async, fn _, _, socket ->
      check(socket)
    end)
  end

  defp check(socket) do
    user = socket.assigns[:current_user]

    if user &&
         is_nil(GlossiaWeb.BrowserAuthentication.current_user(socket.assigns.browser_session)) do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
    else
      {:cont, socket}
    end
  end
end
