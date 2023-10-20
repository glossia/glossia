defmodule Glossia.GitHub.API do
  alias Glossia.GitHub.Metadata
  alias Glossia.GitHub.AppToken

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

      {_, body, _} ->
        {:error, body}
    end
  end

  def refresh_user_access_token_if_outdated(%{
        token: token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        refresh_token_expires_at: refresh_token_expires_at
      }) do
    with {:refresh_token_valid, true} <-
           {:refresh_token_valid,
            refresh_token_expires_at == nil || refresh_token_expires_at > DateTime.utc_now()},
         {:access_token_expired, true} <-
           {:access_token_expired, expires_at < DateTime.utc_now()} do
      app_jwt_token = AppToken.generate_and_sign!()
      client = Tentacat.Client.new(%{jwt: app_jwt_token})

      response =
        Tentacat.post("login/oauth/access_token", client, %{
          client_id: Metadata.app_client_id(),
          client_secret: Metadata.app_client_secret(),
          grant_type: "refresh_token",
          refresh_token: refresh_token
        })

      case response do
        {status, %{"access_token" => access_token, "expires_in" => expires_in}, _}
        when status in 200..299 ->
          {:ok,
           %{
             token: access_token,
             expires_at: DateTime.utc_now() |> DateTime.add(expires_in, :second)
           }}

        {_, body, _} ->
          {:error, body}
      end
    else
      {:refresh_token_valid, false} -> {:error, :refresh_token_expired}
      {:access_token_expired, false} -> {:ok, %{token: token, expires_at: expires_at}}
    end
  end
end
