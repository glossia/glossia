defmodule Glossia.Foundation.Projects.Web.LiveViews.NewLiveView do
  alias Glossia.Foundation.Accounts.Core.Models.Credentials
  alias Glossia.Foundation.Accounts.Core.Repository
  alias Glossia.Foundation.Accounts.Core.Repository, as: AccountsRepository
  alias Glossia.Foundation.ContentSources.Core.GitHub
  alias Glossia.Foundation.Projects.Core.Models.Project
  alias Glossia.Support.GitHub.Core.API, as: GitHubAPI
  use Glossia.Foundation.Application.Web.Helpers.App, :live_view

  def mount(_params, _, socket) do
    repositories =
      case Repository.get_github_credentials(socket.assigns.authenticated_user) do
        %Credentials{} = credentials ->
          case GitHubAPI.get_user_repositories(credentials) do
            {:ok, repositories} ->
              repositories

            {:error, _} ->
              []
          end

        nil ->
          []
      end

    socket =
      socket
      |> put_open_graph_metadata(%{
        title: "New project"
      })
      |> assign(project_changeset: Project.changeset(%Project{}, %{}))
      |> assign(repositories: repositories)

    {:ok, socket}
  end

  def handle_event("validate", %{"project" => attrs}, socket) do
    changeset = %Project{} |> Project.changeset(attrs) |> Map.put(:action, :insert)
    {:noreply, assign(socket, project_changeset: changeset)}
  end

  def handle_event("save", %{"project" => attrs}, socket) do
    user = socket.assigns.authenticated_user
    account = AccountsRepository.get_user_account(user)

    attrs =
      attrs
      |> Map.merge(%{account_id: account.id, content_source_platform: :github})
      |> Useful.atomize_map_keys()

    case Glossia.Foundation.Projects.Core.create_project(attrs) do
      {:ok, project} ->
        {:noreply, redirect(socket, to: ~p"/#{account.handle}/#{project.handle}")}

      {:error, changeset} ->
        {:noreply, assign(socket, project_changeset: changeset)}
    end
  end
end
