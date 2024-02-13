defmodule GlossiaWeb.LiveViews.Projects.Dashboard do
  use GlossiaWeb.Helpers.App, :live_view
  require Logger

  def mount(
        %{"owner_handle" => owner_handle, "project_handle" => project_handle} = _params,
        _,
        socket
      ) do
    project =
      Glossia.Projects.find_project_by_owner_and_project_handle(owner_handle, project_handle)

    socket = socket |> assign(:url_project, project)
    {:ok, socket}
  end

  def handle_event("localize_most_recent_version", _value, socket) do
    project = GlossiaWeb.LiveViewMountablePlug.url_project(socket)
    content_source_platform_module = Glossia.ContentSources.get_platform_module(project.content_source_platform)
    {:ok, version} = content_source_platform_module.get_most_recent_version(project.id_in_content_source_platform)

    :ok =
      Glossia.Projects.trigger_build(project, %{
        type: "new_content",
        version: version
      })

    {:noreply, socket}
  end
end
