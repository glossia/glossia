defmodule Glossia.Github.App do
  @moduledoc false

  require Logger

  @github_api_url "https://api.github.com"
  @github_app_url "https://github.com/apps"

  def install_url(opts \\ []) do
    config = Application.get_env(:glossia, __MODULE__, [])
    app_slug = Keyword.get(opts, :app_slug, config[:app_slug])

    if configured?() and present?(app_slug) do
      {:ok, "#{@github_app_url}/#{String.trim(app_slug)}/installations/new"}
    else
      {:error, :not_configured}
    end
  end

  def jwt(opts \\ []) do
    config = Application.get_env(:glossia, __MODULE__, [])
    app_id = Keyword.get(opts, :app_id, config[:app_id])
    private_key_pem = Keyword.get(opts, :private_key, config[:private_key])

    if is_nil(app_id) or is_nil(private_key_pem) do
      {:error, :not_configured}
    else
      now = System.os_time(:second)

      claims = %{
        "iat" => now - 60,
        "exp" => now + 600,
        "iss" => to_string(app_id)
      }

      jwk = JOSE.JWK.from_pem(private_key_pem)
      jws = %{"alg" => "RS256"}
      {_, token} = JOSE.JWT.sign(jwk, jws, claims) |> JOSE.JWS.compact()
      {:ok, token}
    end
  end

  def installation_token(installation_id, opts \\ []) do
    with {:ok, jwt_token} <- jwt(opts) do
      api_url = Keyword.get(opts, :api_url, @github_api_url)
      url = "#{api_url}/app/installations/#{installation_id}/access_tokens"

      case Glossia.HTTP.new()
           |> Req.post(
             url: url,
             headers: [
               {"authorization", "Bearer #{jwt_token}"},
               {"accept", "application/vnd.github+json"},
               {"x-github-api-version", "2022-11-28"}
             ]
           ) do
        {:ok, %Req.Response{status: 201, body: body}} ->
          {:ok, body["token"]}

        {:ok, %Req.Response{status: status, body: body}} ->
          Logger.warning("GitHub installation token request failed",
            status: status,
            body: inspect(body)
          )

          {:error, {:api_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def configured? do
    config = Application.get_env(:glossia, __MODULE__, [])
    present?(config[:app_id]) and present?(config[:private_key])
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false
end
