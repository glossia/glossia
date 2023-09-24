defmodule Glossia.Foundation.Projects.Web.Controllers.ProjectHTML do
  use Glossia.Foundation.Application.Web.Helpers.App, :html

  def show(assigns) do
    ~H"""
    <div><%= @url_project.handle %></div>
    """
  end
end
