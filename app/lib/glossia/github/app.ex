defmodule Glossia.Github.App do
  @moduledoc false

  require Logger

  alias Glossia.Github.InstallationTokens

  @default_github_api_url "https://api.github.com"
  @default_github_app_url "https://github.com/apps"

  def install_url(opts \\ []) do
    config = Application.get_env(:glossia, __MODULE__, [])
    app_slug = Keyword.get(opts, :app_slug, config[:app_slug])

    if configured?() and present?(app_slug) do
      {:ok, "#{github_app_url(opts)}/#{String.trim(app_slug)}/installations/new"}
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

  @doc """
  Mints an installation token, returning it alongside GitHub's expiry.

  GitHub expires the token an hour after this call, so a caller that keeps it
  for longer than a request needs the expiry to know when to mint another. See
  `Glossia.Github.InstallationTokens`, which caches on exactly that basis.
  """
  def mint_installation_token(installation_id, opts \\ []) do
    with {:ok, jwt_token} <- jwt(opts) do
      api_url = github_api_url(opts)
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
          {:ok, %{token: body["token"], expires_at: body["expires_at"]}}

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

  @doc """
  Returns a token for `installation_id`, reusing a cached one while it is live.

  Callers that hold the token only for the length of one request can use this
  directly. A caller that spans more than an hour, such as a translation run,
  has to ask again at the point of use rather than holding the result.
  """
  def installation_token(installation_id, opts \\ []) do
    resolver = fn -> mint_installation_token(installation_id, opts) end

    case Keyword.fetch(opts, :token_cache) do
      {:ok, cache} -> InstallationTokens.fetch(installation_id, resolver, cache)
      :error -> InstallationTokens.fetch(installation_id, resolver)
    end
  end

  def configured? do
    config = Application.get_env(:glossia, __MODULE__, [])
    present?(config[:app_id]) and present?(config[:private_key])
  end

  def app_id do
    config = Application.get_env(:glossia, __MODULE__, [])

    case config[:app_id] do
      value when is_integer(value) -> value
      value when is_binary(value) -> parse_app_id(value)
      _ -> nil
    end
  end

  defp github_api_url(opts) do
    config = Application.get_env(:glossia, __MODULE__, [])

    opts
    |> Keyword.get(:api_url, config[:api_url] || @default_github_api_url)
    |> String.trim_trailing("/")
  end

  defp github_app_url(opts) do
    config = Application.get_env(:glossia, __MODULE__, [])

    opts
    |> Keyword.get(:app_url, config[:app_url] || @default_github_app_url)
    |> String.trim_trailing("/")
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false

  defp parse_app_id(value) do
    case Integer.parse(String.trim(value)) do
      {app_id, ""} -> app_id
      _ -> nil
    end
  end
end
