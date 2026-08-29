defmodule Glossia.BabelWorkloadIdentity do
  @moduledoc """
  Verifies the projected Kubernetes service-account tokens Babel uses for
  Glossia's internal operations interface.

  Tokens are verified offline against a pinned JSON Web Key Set. In addition
  to a valid signature, the verifier requires the configured issuer, audience,
  service account, namespace, and short token lifetime.
  """

  @clock_skew_seconds 60
  @supported_algorithms ["RS256"]

  def verify(token, policy \\ policy())

  def verify(token, policy) when is_binary(token) and token != "" do
    with {:ok, policy} <- normalize_policy(policy),
         {:ok, jwks} <- configured_jwks(policy),
         {:ok, key_id} <- peek_key_id(token),
         {:ok, claims} <- verify_signature(token, jwks, key_id),
         :ok <- validate_issuer(claims, policy),
         :ok <- validate_audience(claims, policy),
         :ok <- validate_issued_at(claims),
         :ok <- validate_expiration(claims),
         :ok <- validate_not_before(claims),
         :ok <- validate_max_token_lifetime(claims, policy),
         {:ok, principal} <- service_account_principal(claims),
         :ok <- validate_expected_principal(principal, policy),
         :ok <- validate_kubernetes_claims(claims, policy) do
      {:ok, principal}
    end
  end

  def verify(_token, _policy), do: {:error, :invalid_token}

  def database_readonly_role do
    case System.get_env("GLOSSIA_BABEL_DATABASE_READONLY_ROLE") do
      role when is_binary(role) and role != "" ->
        if Regex.match?(~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/, role) do
          {:ok, role}
        else
          {:error, :database_role_not_configured}
        end

      _ ->
        {:error, :database_role_not_configured}
    end
  end

  defp policy do
    %{
      audience: System.get_env("GLOSSIA_BABEL_TOKEN_AUDIENCE"),
      issuer: System.get_env("GLOSSIA_BABEL_TOKEN_ISSUER"),
      jwks: System.get_env("GLOSSIA_BABEL_TOKEN_JWKS"),
      max_token_lifetime_seconds:
        System.get_env("GLOSSIA_BABEL_TOKEN_MAX_LIFETIME_SECONDS", "3600"),
      namespace: System.get_env("GLOSSIA_BABEL_TOKEN_NAMESPACE", "babel"),
      service_account_name: System.get_env("GLOSSIA_BABEL_TOKEN_SERVICE_ACCOUNT", "babel")
    }
  end

  defp normalize_policy(policy) when is_map(policy) do
    normalized = %{
      audience: policy_value(policy, :audience),
      issuer: policy_value(policy, :issuer),
      jwks: policy_value(policy, :jwks),
      max_token_lifetime_seconds: policy_value(policy, :max_token_lifetime_seconds),
      namespace: policy_value(policy, :namespace),
      service_account_name: policy_value(policy, :service_account_name)
    }

    with {:ok, max_token_lifetime_seconds} <-
           parse_positive_integer(normalized.max_token_lifetime_seconds),
         true <-
           Enum.all?(Map.drop(normalized, [:max_token_lifetime_seconds]), fn {_key, value} ->
             present?(value)
           end) do
      {:ok, %{normalized | max_token_lifetime_seconds: max_token_lifetime_seconds}}
    else
      _ -> {:error, :not_configured}
    end
  end

  defp normalize_policy(_policy), do: {:error, :not_configured}

  defp policy_value(policy, key), do: Map.get(policy, key) || Map.get(policy, Atom.to_string(key))

  defp parse_positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> {:ok, integer}
      _ -> {:error, :invalid_integer}
    end
  end

  defp parse_positive_integer(_value), do: {:error, :invalid_integer}

  defp configured_jwks(%{jwks: jwks}) do
    with {:ok, decoded} <- Jason.decode(jwks),
         %{"keys" => keys} when is_list(keys) and keys != [] <- decoded do
      {:ok, keys}
    else
      {:error, _reason} -> {:error, :invalid_jwks}
      _ -> {:error, :invalid_jwks}
    end
  end

  defp peek_key_id(token) do
    case JOSE.JWT.peek_protected(token) do
      %JOSE.JWS{fields: %{"kid" => key_id}} when is_binary(key_id) and key_id != "" ->
        {:ok, key_id}

      _ ->
        {:error, :invalid_token}
    end
  rescue
    _error -> {:error, :invalid_token}
  end

  defp verify_signature(token, jwks, key_id) do
    with {:ok, jwk} <- jwk_for_key_id(jwks, key_id),
         {true, jwt, _jws} <- JOSE.JWT.verify_strict(jwk, @supported_algorithms, token) do
      {:ok, jwt.fields}
    else
      {false, _jwt, _jws} -> {:error, :invalid_signature}
      _ -> {:error, :invalid_signature}
    end
  rescue
    _error -> {:error, :invalid_signature}
  end

  defp jwk_for_key_id(jwks, key_id) do
    case Enum.find(jwks, &match?(%{"kid" => ^key_id}, &1)) do
      nil -> {:error, :invalid_signature}
      jwk -> {:ok, JOSE.JWK.from_map(jwk)}
    end
  end

  defp validate_issuer(%{"iss" => issuer}, %{issuer: expected_issuer})
       when issuer == expected_issuer, do: :ok

  defp validate_issuer(_claims, _policy), do: {:error, :bad_issuer}

  defp validate_audience(%{"aud" => audience}, %{audience: expected_audience})
       when is_binary(audience) do
    if audience == expected_audience, do: :ok, else: {:error, :bad_audience}
  end

  defp validate_audience(%{"aud" => audiences}, %{audience: expected_audience})
       when is_list(audiences) do
    if expected_audience in audiences, do: :ok, else: {:error, :bad_audience}
  end

  defp validate_audience(_claims, _policy), do: {:error, :bad_audience}

  defp validate_issued_at(%{"iat" => issued_at}) when is_integer(issued_at) do
    if issued_at <= now() + @clock_skew_seconds, do: :ok, else: {:error, :token_not_yet_valid}
  end

  defp validate_issued_at(_claims), do: {:error, :missing_issued_at}

  defp validate_expiration(%{"exp" => expiration}) when is_integer(expiration) do
    if expiration > now() - @clock_skew_seconds, do: :ok, else: {:error, :token_expired}
  end

  defp validate_expiration(_claims), do: {:error, :token_expired}

  defp validate_not_before(%{"nbf" => not_before}) when is_integer(not_before) do
    if not_before <= now() + @clock_skew_seconds, do: :ok, else: {:error, :token_not_yet_valid}
  end

  defp validate_not_before(%{"nbf" => _not_before}), do: {:error, :token_not_yet_valid}
  defp validate_not_before(_claims), do: :ok

  defp validate_max_token_lifetime(
         %{"exp" => expiration, "iat" => issued_at},
         %{max_token_lifetime_seconds: max_token_lifetime_seconds}
       )
       when is_integer(expiration) and is_integer(issued_at) do
    if expiration >= issued_at and expiration - issued_at <= max_token_lifetime_seconds do
      :ok
    else
      {:error, :token_lifetime_exceeded}
    end
  end

  defp validate_max_token_lifetime(_claims, _policy), do: {:error, :token_lifetime_exceeded}

  defp service_account_principal(%{"sub" => "system:serviceaccount:" <> subject} = claims) do
    case String.split(subject, ":", parts: 2) do
      [namespace, name] when namespace != "" and name != "" ->
        {:ok,
         %{
           namespace: namespace,
           name: name,
           uid: get_in(claims, ["kubernetes.io", "serviceaccount", "uid"])
         }}

      _ ->
        {:error, :not_service_account}
    end
  end

  defp service_account_principal(_claims), do: {:error, :not_service_account}

  defp validate_expected_principal(
         %{namespace: namespace, name: name},
         %{namespace: expected_namespace, service_account_name: expected_name}
       ) do
    if namespace == expected_namespace and name == expected_name do
      :ok
    else
      {:error, :wrong_principal}
    end
  end

  defp validate_kubernetes_claims(
         %{"kubernetes.io" => %{"namespace" => namespace, "serviceaccount" => %{"name" => name}}},
         %{namespace: expected_namespace, service_account_name: expected_name}
       ) do
    if namespace == expected_namespace and name == expected_name do
      :ok
    else
      {:error, :bad_kubernetes_claims}
    end
  end

  defp validate_kubernetes_claims(_claims, _policy), do: {:error, :bad_kubernetes_claims}

  defp present?(value), do: is_binary(value) and value != ""
  defp now, do: DateTime.to_unix(DateTime.utc_now())
end
