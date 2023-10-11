defmodule GlossiaWeb.Controllers.ProjectHTML do
  use GlossiaWeb.Helpers.App, :html

  def show(assigns) do
    ~H"""
    <div><%= @url_project.handle %></div>
    """
  end
end
