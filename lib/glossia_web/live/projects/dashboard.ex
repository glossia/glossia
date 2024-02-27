defmodule GlossiaWeb.LiveViews.Projects.Dashboard do
  use GlossiaWeb.Helpers.App, :live_view
  require Logger

  def mount(
        %{} = _params,
        _,
        socket
      ) do
    {:ok, socket}
  end

  def handle_event("localize_most_recent_version", _value, socket) do
    # project = GlossiaWeb.LiveViewMountablePlug.url_project(socket)
    # platform_module = Glossia.ContentSources.get_platform_module(project.platform)

    # {:ok, _version} =
    #   platform_module.get_most_recent_version(project.id_in_platform)

    # :ok =
    #   Glossia.Projects.trigger_build(project, %{
    #     type: "new_content",
    #     version: version
    #   })

    {:noreply, socket}
  end
end
