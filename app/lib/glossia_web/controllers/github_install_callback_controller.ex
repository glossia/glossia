defmodule GlossiaWeb.GithubInstallCallbackController do
  use GlossiaWeb, :controller

  alias Glossia.Github.Installations

  require Logger

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "github_install_callback",
    scale: :timer.minutes(1),
    limit: 30,
    by: :ip,
    format: :text

  def create(conn, params) do
    installation_id = params["installation_id"]
    setup_action = params["setup_action"]

    Logger.info("GitHub App install callback",
      installation_id: installation_id,
      setup_action: setup_action
    )

    cond do
      setup_action == "request" ->
        conn
        |> put_flash(
          :info,
          gettext("Your GitHub App installation request has been sent to the organization admin.")
        )
        |> redirect(to: default_redirect(conn))

      is_nil(installation_id) ->
        conn
        |> put_flash(:error, gettext("GitHub installation callback missing installation ID."))
        |> redirect(to: default_redirect(conn))

      true ->
        handle_install(conn, installation_id)
    end
  end

  defp handle_install(conn, installation_id) do
    user = conn.assigns[:current_user]

    if user do
      link_installation(conn, user, installation_id)
    else
      conn
      |> put_session(:pending_github_installation_id, installation_id)
      |> put_flash(:info, gettext("Please sign in to complete your GitHub connection."))
      |> redirect(to: ~p"/auth/login")
    end
  end

  defp link_installation(conn, user, installation_id) do
    # Use the account from session (set during wizard flow) if available,
    # falling back to the user's personal account. This enables Vercel-like
    # behavior where installations link to the account the user was on.
    account =
      case get_session(conn, :install_account_handle) do
        nil ->
          user.account

        handle ->
          case Glossia.Accounts.get_account_by_handle(handle) do
            nil -> user.account
            found_account -> found_account
          end
      end

    return_to = get_session(conn, :wizard_return_to)
    default_path = "/#{account.handle}/-/settings/github"

    case fetch_and_create_installation(account, installation_id) do
      {:ok, installation} ->
        Glossia.Auditing.record("github_installation.created", account, user,
          resource_type: "github_installation",
          resource_id: to_string(installation.id),
          resource_path: "/#{account.handle}/-/settings/github",
          summary: "Connected GitHub account #{installation.github_account_login}"
        )

        conn
        |> delete_session(:wizard_return_to)
        |> delete_session(:install_account_handle)
        |> put_flash(:info, gettext("GitHub connected successfully."))
        |> redirect(to: return_to || default_path)

      {:error, :already_linked} ->
        conn
        |> delete_session(:wizard_return_to)
        |> delete_session(:install_account_handle)
        |> put_flash(:info, gettext("GitHub is already connected."))
        |> redirect(to: return_to || default_path)

      {:error, reason} ->
        Logger.warning("Failed to link GitHub installation",
          installation_id: installation_id,
          reason: inspect(reason)
        )

        conn
        |> delete_session(:wizard_return_to)
        |> delete_session(:install_account_handle)
        |> put_flash(:error, gettext("Failed to connect GitHub. Please try again."))
        |> redirect(to: return_to || default_path)
    end
  end

  defp fetch_and_create_installation(account, installation_id) do
    with {:ok, github_id} <- parse_installation_id(installation_id) do
      if Installations.get_installation_by_github_id(github_id) do
        {:error, :already_linked}
      else
        with {:ok, token} <- Glossia.Github.App.installation_token(github_id),
             {:ok, install_info} <- fetch_installation_info(token) do
          Installations.create_installation(account, %{
            github_installation_id: github_id,
            github_account_login: install_info["login"],
            github_account_type: install_info["type"],
            github_account_id: install_info["id"]
          })
        end
      end
    end
  end

  defp parse_installation_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> {:ok, id}
      _ -> {:error, :invalid_installation_id}
    end
  end

  defp parse_installation_id(_), do: {:error, :invalid_installation_id}

  defp fetch_installation_info(token) do
    case Glossia.HTTP.new()
         |> Req.get(
           url: "https://api.github.com/installation/repositories?per_page=1",
           headers: [
             {"authorization", "token #{token}"},
             {"accept", "application/vnd.github+json"},
             {"x-github-api-version", "2022-11-28"}
           ]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case body["repositories"] do
          [%{"owner" => owner} | _] ->
            {:ok, owner}

          _ ->
            {:ok, %{"login" => "unknown", "type" => "User", "id" => 0}}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp default_redirect(conn) do
    return_to = get_session(conn, :wizard_return_to)

    cond do
      return_to ->
        return_to

      conn.assigns[:current_user] ->
        "/#{conn.assigns.current_user.account.handle}"

      true ->
        ~p"/auth/login"
    end
  end
end
