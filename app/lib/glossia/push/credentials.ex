defmodule Glossia.Push.Credentials do
  @moduledoc "Bounded Cachex provider credentials with expiry and coalesced misses. No device tokens."
  import Cachex.Spec
  alias Glossia.Push.Config

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Supervisor.child_spec(
      {Cachex,
       name: name,
       expiration: expiration(default: :timer.minutes(50)),
       hooks: [hook(module: Cachex.Limit.Scheduled, args: {32, [], []})]},
      id: name
    )
  end

  def apns(config, cache \\ __MODULE__) do
    fetch(
      :apns,
      config,
      fn ->
        jwt =
          sign(config.private_key, %{"alg" => "ES256", "kid" => config.key_id}, %{
            "iss" => config.team_id,
            "iat" => System.system_time(:second)
          })

        {:ok, jwt, 3000}
      end,
      cache
    )
  end

  def fcm(config, cache \\ __MODULE__),
    do: fetch(:fcm, config, fn -> exchange(config) end, cache)

  def invalidate(provider, config, cache \\ __MODULE__),
    do: Cachex.del(cache, key(provider, config))

  defp fetch(provider, config, resolver, cache) do
    case Cachex.fetch(cache, key(provider, config), fn _ ->
           case resolver.() do
             {:ok, token, ttl} -> {:commit, {:ok, token}, ttl: :timer.seconds(ttl)}
             {:error, _} = error -> {:ignore, error}
           end
         end) do
      {status, result} when status in [:ok, :commit, :ignore] -> result
      _ -> {:error, :credentials_unavailable}
    end
  end

  defp key(provider, config),
    do: {provider, :crypto.hash(:sha256, :erlang.term_to_binary(config))}

  defp exchange(config) do
    now = System.system_time(:second)

    assertion =
      sign(config.private_key, %{"alg" => "RS256"}, %{
        "iss" => config.client_email,
        "scope" => "https://www.googleapis.com/auth/firebase.messaging",
        "aud" => "https://oauth2.googleapis.com/token",
        "iat" => now,
        "exp" => now + 3600
      })

    options =
      Keyword.merge(Config.req_options(),
        finch: Glossia.Finch,
        form: [grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: assertion],
        retry: false,
        redirect: false,
        receive_timeout: 10_000,
        pool_timeout: 5000
      )

    case Req.post("https://oauth2.googleapis.com/token", options) do
      {:ok, %Req.Response{status: 200, body: %{"access_token" => token, "expires_in" => ttl}}}
      when is_binary(token) and is_integer(ttl) and ttl > 300 ->
        {:ok, token, min(ttl - 300, 3000)}

      {:ok, %Req.Response{status: status}} when status in [400, 401, 403] ->
        {:error, :credentials_rejected}

      _ ->
        {:error, :credentials_unavailable}
    end
  end

  defp sign(pem, headers, claims) do
    pem
    |> JOSE.JWK.from_pem()
    |> JOSE.JWT.sign(headers, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
