defmodule GlossiaWeb.LiveViews.Projects.NewLiveView do
  alias Glossia.Accounts.Credentials
  alias Glossia.Accounts.Repository
  alias Glossia.Accounts.Repository, as: AccountsRepository
  alias Glossia.ContentSources.GitHub
  alias Glossia.Projects.Project
  alias Glossia.GitHub.API, as: GitHubAPI
  use GlossiaWeb.Helpers.App, :live_view

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
      |> assign(form: to_form(Project.changeset(%Project{}, %{
        content_source_platform: :github
      })))
      |> assign(repositories: repositories)

    {:ok, socket}
  end

  def handle_event("validate", %{"project" => attrs}, socket) do
    changeset = %Project{} |> Project.changeset(attrs) |> Map.put(:action, :insert)
    {:noreply, assign(socket, form: changeset |> to_form())}
  end

  def handle_event("save", %{"project" => attrs}, socket) do
    user = socket.assigns.authenticated_user
    account = AccountsRepository.get_user_account(user)

    attrs =
      attrs
      |> Map.merge(%{account_id: account.id})
      |> Useful.atomize_map_keys()

    case Glossia.Projects.create_project(attrs) do
      {:ok, project} ->
        {:noreply, redirect(socket, to: ~p"/#{account.handle}/#{project.handle}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: changeset |> map_error_changeset |> to_form())}
    end
  end

  @spec map_error_changeset(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp map_error_changeset(changeset) do
    errors = changeset.errors || []

    changeset =
      with {:content_source_id_errors, {_, attrs}} when errors != nil <-
             {:content_source_id_errors, Keyword.get(errors, :content_source_id)},
           {:error_constraint, :unique} <- {:error_constraint, Keyword.get(attrs, :constraint)} do
        changeset
        |> Ecto.Changeset.add_error(
          :content_source_id,
          "Another project is already linked to this repository."
        )
      else
        _ -> changeset
      end

    changeset
  end
end
