defmodule GlossiaWeb.LiveViews.Projects.New do
  use GlossiaWeb.Helpers.App, :live_view

  # @dialyzer {:nowarn_function, put_github_repositories: 1}

  def mount(_params, _, socket) do
    # socket =
    #   socket
    #   |> put_github_repositories()
    #   |> put_open_graph_metadata(%{
    #     title: "New project"
    #   })
    #   |> assign(form: to_form(Project.changeset(%Project{}, %{})))

    {:ok, socket}
  end

  # @spec put_github_repositories(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  # defp put_github_repositories(socket) do
  #   case Accounts.get_github_credentials(socket.assigns.authenticated_user) do
  #     %Credentials{} = credentials ->
  #       case GitHubAPI.refreshing_token_if_needed(
  #              %{
  #                expires_at: credentials.expires_at,
  #                refresh_token: credentials.refresh_token,
  #                token: credentials.token,
  #                refresh_token_expires_at: credentials.refresh_token_expires_at
  #              },
  #              fn credentials ->
  #                GitHubAPI.get_user_repositories(credentials)
  #              end,
  #              # credo:disable-for-lines:10
  #              fn github_credentials ->
  #                {:ok, _} =
  #                  Accounts.find_and_update_or_create_credential(
  #                    Map.merge(github_credentials, credentials)
  #                  )

  #                :ok
  #              end
  #            ) do
  #         {:ok, repositories} ->
  #           socket
  #           |> assign(:repositories, repositories)
  #           |> assign(:needs_reauthentication, false)

  #         {:error, :refresh_token_expired} ->
  #           socket |> assign(:repositories, nil) |> assign(:needs_reauthentication, true)

  #         {:error, :refresh_token_invalid} ->
  #           socket |> assign(:repositories, nil) |> assign(:needs_reauthentication, true)
  #       end

  #     nil ->
  #       socket |> assign(:repositories, nil) |> assign(:needs_reauthentication, true)
  #   end
  # end

  # def handle_event("validate", %{"project" => attrs}, socket) do
  #   attrs = attrs |> put_account_id_and_platform_attrs(socket)
  #   changeset = %Project{} |> Project.changeset(attrs) |> Map.put(:action, :insert)
  #   {:noreply, assign(socket, form: changeset |> to_form())}
  # end

  # def handle_event("save", %{"project" => attrs}, socket) do
  #   account = socket |> authenticated_user_account
  #   attrs = attrs |> put_account_id_and_platform_attrs(socket)

  #   case Glossia.Projects.create_project(attrs) do
  #     {:ok, project} ->
  #       {:noreply, redirect(socket, to: ~p"/#{account.handle}/#{project.handle}")}

  #     {:error, changeset} ->
  #       {:noreply, assign(socket, form: changeset |> to_form())}
  #   end
  # end

  # defp put_account_id_and_platform_attrs(attrs, socket) do
  #   account = socket |> authenticated_user_account

  #   attrs
  #   |> Map.merge(%{account_id: account.id, platform: :github})
  #   |> Useful.atomize_map_keys()
  # end

  # defp authenticated_user_account(socket) do
  #   user = socket.assigns.authenticated_user
  #   Accounts.get_user_account(user)
  # end
end
