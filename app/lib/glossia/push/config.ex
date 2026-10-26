defmodule Glossia.Push.Config do
  @moduledoc "Server-only direct APNs and FCM settings. Missing providers disable independently."

  def apns(environment) do
    case config()[:apns] do
      %{environment: scope} = value when scope in ["both", environment] -> {:ok, value}
      _ -> {:error, :not_configured}
    end
  end

  def fcm do
    case config()[:fcm] do
      %{} = value -> {:ok, value}
      _ -> {:error, :not_configured}
    end
  end

  def available?("ios", environment), do: match?({:ok, _}, apns(environment))
  def available?("android", "production"), do: match?({:ok, _}, fcm())
  def available?(_, _), do: false

  def capabilities do
    %{
      "ios" => available?("ios", "production") or available?("ios", "sandbox"),
      "android" => available?("android", "production")
    }
  end

  def req_options, do: config()[:req_options] || []
  @doc false
  def credentials_cache, do: config()[:credentials_cache] || Glossia.Push.Credentials
  defp config, do: Application.get_env(:glossia, Glossia.Push, [])

  @doc "Parse runtime environment. Partial/malformed providers fail without echoing secrets."
  def parse!(env) do
    [apns: parse_apns!(env), fcm: parse_fcm!(env)]
  end

  defp parse_apns!(env) do
    values = Enum.map(~w(TEAM_ID KEY_ID PRIVATE_KEY), &present(env, "GLOSSIA_APNS_" <> &1))

    case values do
      [nil, nil, nil] ->
        nil

      [team, key_id, pem] when is_binary(team) and is_binary(key_id) and is_binary(pem) ->
        environment = present(env, "GLOSSIA_APNS_ENVIRONMENT") || "production"
        topic = present(env, "GLOSSIA_APNS_TOPIC")

        unless Regex.match?(~r/\A[A-Z0-9]{10}\z/, team) and
                 Regex.match?(~r/\A[A-Z0-9]{10}\z/, key_id) and
                 environment in ["production", "sandbox", "both"] and
                 is_binary(topic) and Regex.match?(~r/\A[A-Za-z0-9.-]{3,200}\z/, topic),
               do: raise(ArgumentError, "Invalid APNs identifiers, topic or environment")

        ensure_key!(pem, "EC")
        %{team_id: team, key_id: key_id, private_key: pem, topic: topic, environment: environment}

      _ ->
        raise ArgumentError, "Configure all APNs credentials and topic, or none"
    end
  end

  defp parse_fcm!(env) do
    case present(env, "GLOSSIA_FCM_SERVICE_ACCOUNT_JSON") do
      nil ->
        nil

      json ->
        with {:ok, %{"type" => "service_account"} = account} <- JSON.decode(json),
             project when is_binary(project) <- account["project_id"],
             true <- Regex.match?(~r/\A[a-z][a-z0-9-]{4,28}[a-z0-9]\z/, project),
             email when is_binary(email) and email != "" <- account["client_email"],
             pem when is_binary(pem) <- account["private_key"] do
          ensure_key!(pem, "RSA")
          %{project_id: project, client_email: email, private_key: pem}
        else
          _ -> raise ArgumentError, "Invalid FCM service account"
        end
    end
  end

  defp ensure_key!(pem, type) do
    valid? =
      try do
        [{_, _, :not_encrypted}] = :public_key.pem_decode(pem)
        {_, key} = pem |> JOSE.JWK.from_pem() |> JOSE.JWK.to_map()
        key["kty"] == type and is_binary(key["d"]) and (type != "EC" or key["crv"] == "P-256")
      rescue
        _ -> false
      catch
        _, _ -> false
      end

    unless valid?, do: raise(ArgumentError, "Invalid push signing key")
  end

  defp present(env, key) do
    case String.trim(Map.get(env, key) || "") do
      "" -> nil
      value -> value
    end
  end
end
