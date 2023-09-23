defmodule Glossia.Foundation.GitHub.Core.API do
  use Modulex
  alias Glossia.Foundation.GitHub.Core.Metadata

  defimplementation do
    # def get_user_repositories(%{ token: token, refresh_token: refresh_token, expires_at: expires_at}) do
    # end

    def refresh_user_access_token_if_outdated(%{
          token: token,
          refresh_token: refresh_token,
          expires_at: expires_at
        }) do
      if expires_at > DateTime.utc_now() do
        {:ok, token}
      else
        app_jwt_token = Glossia.Foundation.GitHub.Core.AppToken.generate_and_sign!()
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
               expires_at: DateTime.utc_now() |> DateTime.add(expires_in, :seconds)
             }}

          {_, body, _} ->
            {:error, body}
        end
      end
    end
  end

  defbehaviour do
    @doc """
    Given a user's credentials, it returns a list of repositories that are accessible to the user access token
    https://docs.github.com/en/rest/apps/installations?apiVersion=2022-11-28#list-repositories-accessible-to-the-user-access-token
    """
    @callback get_user_repositories(%{
                token: String.t(),
                refresh_token: String.t(),
                expires_at: DateTime.t()
              }) :: [{:ok, String.t()}, {:error, any()}]

    @doc """
    It refreshes a user access token if it's oudated.
    """
    @callback refresh_user_access_token_if_outdated(%{
                token: String.t(),
                refresh_token: String.t(),
                expires_at: DateTime.t()
              }) :: [{:ok, %{token: String.t(), expires_at: DateTime.t()}}, {:error, any()}]
  end
end
