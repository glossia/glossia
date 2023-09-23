defmodule Glossia.Foundation.Projects.Web.LiveViews.NewLiveView do
  alias Glossia.Foundation.Accounts.Core.Repository
  use Glossia.Foundation.Application.Web.Helpers.App, :live_view
  alias Glossia.Foundation.Projects.Core.Models.Project
  alias Glossia.Foundation.ContentSources.Core.GitHub

  def mount(_params, _, socket) do
    socket =
      socket
      |> put_open_graph_metadata(%{
        title: "New project"
      })
      |> assign(project_changeset: Project.changeset(%Project{}, %{}))
      |> assign(github_id: Repository.get_github_id(socket.assigns.authenticated_user))

    {:ok, socket}
  end

  def handle_event("validate", %{"project" => attrs}, socket) do
    changeset = %Project{} |> Project.changeset(attrs) |> Map.put(:action, :insert)
    {:noreply, assign(socket, project_changeset: changeset)}
  end
end
