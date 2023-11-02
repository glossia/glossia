defmodule GlossiaWeb.LiveViews.Projects.Dashboard do
  use GlossiaWeb.Helpers.App, :live_view

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
end
