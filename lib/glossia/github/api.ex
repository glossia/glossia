defmodule Glossia.GitHub.API do
  alias Glossia.GitHub.Metadata
  alias Glossia.GitHub.AppToken

  @type credentials :: %{
          token: binary(),
          refresh_token: binary(),
          expires_at: DateTime.t(),
          refresh_token_expires_at: DateTime.t() | any()
        }

  @spec get_user_repositories(credentials :: __MODULE__.credentials()) ::
          {:ok, [String.t()]} | {:error, number(), any()}
  def get_user_repositories(%{token: token}) do
    client = Tentacat.Client.new(%{jwt: token})

    case Tentacat.get("user/installations", client) do
      {status, %{"installations" => installations}, _} when status in 200..299 ->
        repositories =
          for installation <- installations do
            {_, %{"repositories" => repositories}, _} =
              Tentacat.get("user/installations/#{installation["id"]}/repositories", client)

            repositories
          end
          |> List.flatten()
          |> Enum.map(fn repo -> repo["full_name"] end)

        {:ok, repositories}

      {status, body, _} ->
        {:error, status, body}
    end
  end

  @spec refreshing_token_if_needed(
          credentials :: __MODULE__.credentials(),
          action :: (__MODULE__.credentials() -> any()),
          token_refreshed :: (__MODULE__.credentials() -> any())
        ) :: any()
  def refreshing_token_if_needed(credentials, action, token_refreshed) do
    with {:refreshed_credentials, {:ok, credentials}} <-
           {:refreshed_credentials,
            refresh_user_access_token_if_outdated(credentials, token_refreshed)},
         {:action_result, {:error, 401, _}} <- {:action_result, action.(credentials)},
         {:second_refreshed_credentials, {:ok, second_credentials}} <-
           {:second_refreshed_credentials,
            refresh_user_access_token_if_outdated(credentials, token_refreshed)} do
      action.(second_credentials)
    else
      {:refreshed_credentials, {:error, :refresh_token_expired}} ->
        {:error, :refresh_token_expired}

      {:refreshed_credentials, {:error, 401, _}} ->
        {:error, :refresh_token_invalid}

      {:refreshed_credentials, {:error, status, body}} ->
        {:error, status, body}

      {:action_result, result} ->
        result

      {:second_refreshed_credentials, result} ->
        result
    end
  end

  @spec refresh_user_access_token_if_outdated(
          credentials :: __MODULE__.credentials(),
          token_refreshed :: (__MODULE__.credentials() -> any())
        ) :: any()
  defp refresh_user_access_token_if_outdated(
         %{
           token: token,
           refresh_token: refresh_token,
           expires_at: expires_at,
           refresh_token_expires_at: refresh_token_expires_at
         },
         token_refreshed
       ) do
    with {:refresh_token_valid, true} <-
           {:refresh_token_valid,
            refresh_token_expires_at == nil ||
              DateTime.compare(refresh_token_expires_at, DateTime.utc_now()) == :gt},
         {:access_token_expired, true} <-
           {:access_token_expired, DateTime.compare(expires_at, DateTime.utc_now()) == :lt} do
      app_jwt_token = AppToken.generate_and_sign!()
      client = Tentacat.Client.new(%{jwt: app_jwt_token})

      body = %{
        client_id: Metadata.app_client_id(),
        client_secret: Metadata.app_client_secret(),
        grant_type: "refresh_token",
        refresh_token: refresh_token
      }

      response =
        Tentacat.post("login/oauth/access_token", client, body)

      case response do
        {status, %{"access_token" => access_token, "expires_in" => expires_in}, _}
        when status in 200..299 ->
          credentials = %{
            token: access_token,
            refresh_token: refresh_token,
            expires_at: DateTime.utc_now() |> DateTime.add(expires_in, :second),
            refresh_token_expires_at: refresh_token_expires_at
          }

          token_refreshed.(credentials)
          {:ok, credentials}

        {status, body, _} ->
          {:error, status, body}
      end
    else
      {:refresh_token_valid, false} -> {:error, :refresh_token_expired}
      {:access_token_expired, false} -> {:ok, %{token: token, expires_at: expires_at}}
    end
  end
end
