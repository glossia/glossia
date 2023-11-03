defmodule GlossiaWeb.LiveViews.Projects.Versions do
  use GlossiaWeb.Helpers.App, :live_view

  def mount(_params, socket) do
    socket = socket |> assign(:versions, get_versions(socket))
    {:ok, socket}
  end

  def get_versions(socket) do
    _project = GlossiaWeb.LiveViewMountablePlug.url_project(socket)

    # content_source =
    #   ContentSources.new(project.content_source_platform, project.content_source_id)

    []
  end
end
