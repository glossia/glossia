defmodule GlossiaWeb.LiveViews.Projects.Versions do
  use GlossiaWeb.Helpers.App, :live_view

  def mount(_params, _, socket) do
    socket = socket |> assign(:versions, get_versions(socket))
    {:ok, socket}
  end

  def get_versions(_socket) do
    # project = GlossiaWeb.LiveViewMountablePlug.url_project(socket)
    # platform_module = Glossia.ContentSources.get_platform_module(project.platform)
    # versions = platform_module.get_versions(project.id_in_platform)
    # versions
    []
  end
end
