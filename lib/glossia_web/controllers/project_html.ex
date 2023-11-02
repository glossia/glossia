defmodule GlossiaWeb.Controllers.ProjectHTML do
  use GlossiaWeb.Helpers.App, :html

  def show(assigns) do
    ~H"""
    <div>
      <.link href={~p"/auth/logout"} method="delete">Sign out</.link>
    </div>
    """
  end
end
