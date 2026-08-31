defmodule Glossia.Pomerium do
  @moduledoc false

  alias Glossia.Pomerium.JWKSCache

  @clock_skew_seconds 30
  @supported_algorithms ["ES256"]

  def identity_from_assertion(assertion, config \\ config())

  def identity_from_assertion(assertion, config) when is_binary(assertion) do
    with true <- Keyword.get(config, :enabled, false),
         {:ok, key_id} <- key_id(assertion),
         {:ok, jwks} <-
           JWKSCache.fetch(
             fn -> fetch_jwks(config) end,
             Keyword.get(config, :jwks_cache, JWKSCache)
           ),
         {:ok, jwk} <- jwk_for_key_id(jwks, key_id),
         {true, jwt, _jws} <- JOSE.JWT.verify_strict(jwk, @supported_algorithms, assertion),
         {:ok, claims} <- validated_claims(jwt.fields, config) do
      {:ok, %{email: claims["email"], name: claims["name"], subject: claims["sub"]}}
    else
      _error -> {:error, :invalid_assertion}
    end
  rescue
    _error -> {:error, :invalid_assertion}
  end

  def identity_from_assertion(_assertion, _config), do: {:error, :invalid_assertion}

  defp config, do: Application.get_env(:glossia, __MODULE__, [])

  defp key_id(assertion) do
    case JOSE.JWT.peek_protected(assertion) do
      %JOSE.JWS{fields: %{"kid" => key_id}} when is_binary(key_id) and byte_size(key_id) > 0 ->
        {:ok, key_id}

      _other ->
        {:error, :missing_key_id}
    end
  end

  defp fetch_jwks(config) do
    case Keyword.get(config, :jwks_fetcher) do
      fetcher when is_function(fetcher, 0) -> fetcher.()
      nil -> request_jwks(Keyword.fetch!(config, :jwks_url))
    end
  end

  defp request_jwks(url) do
    with %URI{scheme: "https", host: host} <- URI.parse(url),
         {:ok, {{_http_version, 200, _reason_phrase}, _headers, body}} <-
           :httpc.request(
             :get,
             {String.to_charlist(url), []},
             [
               connect_timeout: 5_000,
               timeout: 5_000,
               ssl: [
                 verify: :verify_peer,
                 cacerts: :public_key.cacerts_get(),
                 server_name_indication: String.to_charlist(host),
                 customize_hostname_check: [
                   match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
                 ]
               ]
             ],
             body_format: :binary
           ),
         {:ok, jwks} <- Jason.decode(body) do
      {:ok, jwks}
    else
      _error -> {:error, :jwks_unavailable}
    end
  end

  defp jwk_for_key_id(%{"keys" => keys}, key_id) do
    case Enum.find(keys, &match?(%{"kid" => ^key_id}, &1)) do
      nil -> {:error, :unknown_key}
      jwk -> {:ok, JOSE.JWK.from_map(jwk)}
    end
  end

  defp jwk_for_key_id(_jwks, _key_id), do: {:error, :invalid_jwks}

  defp validated_claims(claims, config) do
    expected_issuer = Keyword.fetch!(config, :expected_issuer)
    expected_audience = Keyword.fetch!(config, :expected_audience)
    email_domain = Keyword.fetch!(config, :email_domain)

    if claims["iss"] == expected_issuer and
         audience_matches?(claims["aud"], expected_audience) and
         valid_times?(claims) and
         valid_email?(claims["email"], email_domain) and
         is_binary(claims["sub"]) do
      {:ok, claims}
    else
      {:error, :invalid_claims}
    end
  end

  defp audience_matches?(audience, expected_audience) when is_binary(audience),
    do: audience == expected_audience

  defp audience_matches?(audiences, expected_audience) when is_list(audiences),
    do: expected_audience in audiences

  defp audience_matches?(_audience, _expected_audience), do: false

  defp valid_times?(%{"exp" => expiration, "iat" => issued_at} = claims)
       when is_integer(expiration) and is_integer(issued_at) do
    now = System.system_time(:second)

    expiration > now - @clock_skew_seconds and
      issued_at <= now + @clock_skew_seconds and
      valid_not_before?(claims["nbf"], now)
  end

  defp valid_times?(_claims), do: false

  defp valid_not_before?(nil, _now), do: true

  defp valid_not_before?(not_before, now) when is_integer(not_before),
    do: not_before <= now + @clock_skew_seconds

  defp valid_not_before?(_not_before, _now), do: false

  defp valid_email?(email, email_domain) when is_binary(email) and is_binary(email_domain) do
    case String.split(String.downcase(email), "@", parts: 2) do
      [local_part, domain] when local_part != "" -> domain == String.downcase(email_domain)
      _ -> false
    end
  end

  defp valid_email?(_email, _email_domain), do: false
end
