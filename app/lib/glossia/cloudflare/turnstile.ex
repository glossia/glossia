defmodule Glossia.Cloudflare.Turnstile do
  @moduledoc """
  Server-side verification for [Cloudflare Turnstile] tokens.

  Called from the sign-up surface via `GlossiaWeb.SignupProtection` so a
  bot that never solved the widget cannot reach `Glossia.Accounts.find_or_create_user_from_oauth/3`.

  The site + secret keys come from environment variables, and enforcement
  is composed via `Glossia.FeatureFlags.turnstile_enabled?/0` so a
  FunWithFlags kill switch can turn the gate off globally without a
  redeploy.

  [Cloudflare Turnstile]: https://developers.cloudflare.com/turnstile/
  """

  require Logger

  @endpoint "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  @doc """
  True when Turnstile enforcement is on for this environment and the kill
  switch is off.
  """
  def required? do
    Glossia.FeatureFlags.turnstile_enabled?()
  end

  @doc """
  True when the runtime env toggle is set. Kept separate from
  `required?/0` so callers that must not hit the FunWithFlags store
  (e.g. hot-path plugs that need to answer without a Postgres round
  trip on a cold cache) have a raw-env fallback.
  """
  def env_enabled? do
    config(:enabled?, false)
  end

  @doc "Public site key rendered into the Turnstile widget markup."
  def site_key do
    config(:site_key)
  end

  @doc """
  Verify a Turnstile response token against Cloudflare's siteverify
  endpoint.

  Returns `:ok` when the token is valid, when the widget is not required
  (dev, kill switch on, etc.), and when the caller can trust that no
  user-visible action should be blocked.

  Errors:

    * `{:error, :misconfigured}` — Turnstile is required but no secret
      key or app URL is configured (fail-closed for the operator).
    * `{:error, :missing_token}` — no token sent by the browser.
    * `{:error, :rejected}` — Cloudflare returned `success: false`, or
      the `action` / `hostname` in the response did not match.
    * `{:error, :unavailable}` — Cloudflare returned a non-200 status
      or the request failed at the network layer.

  Options:

    * `:required?` — override the runtime enforcement flag (tests).
    * `:secret_key`, `:endpoint`, `:request` — dependency injection.
    * `:expected_action` — bind the token to a widget `action` attribute
      so a token solved for one form cannot be replayed against another.
    * `:expected_hostname` — override the derived hostname check.
  """
  def verify(token, opts \\ []) do
    required? = Keyword.get(opts, :required?, required?())

    if required? do
      verify_required(token, opts)
    else
      :ok
    end
  end

  defp verify_required(token, opts) do
    secret_key = Keyword.get(opts, :secret_key, config(:secret_key))

    cond do
      not is_binary(secret_key) or secret_key == "" ->
        Logger.error("Turnstile is enabled without a secret key")
        {:error, :misconfigured}

      not is_binary(token) or token == "" ->
        {:error, :missing_token}

      true ->
        verify_token(token, secret_key, opts)
    end
  end

  defp verify_token(token, secret_key, opts) do
    request = Keyword.get(opts, :request, &Req.post/2)
    endpoint = Keyword.get(opts, :endpoint, @endpoint)
    expected_action = Keyword.get(opts, :expected_action)
    expected_hostname = Keyword.get_lazy(opts, :expected_hostname, &expected_hostname/0)

    case request.(endpoint,
           form: %{secret: secret_key, response: token},
           connect_options: [timeout: 1_000],
           receive_timeout: 5_000
         ) do
      {:ok, %Req.Response{status: 200, body: %{"success" => true} = body}} ->
        with :ok <- validate_action(body, expected_action) do
          validate_hostname(body, expected_hostname)
        end

      {:ok, %Req.Response{status: 200}} ->
        {:error, :rejected}

      {:ok, %Req.Response{status: status}} ->
        Logger.warning("Turnstile verification returned an unexpected status", status: status)
        {:error, :unavailable}

      {:error, _reason} ->
        Logger.warning("Turnstile verification request failed")
        {:error, :unavailable}
    end
  end

  defp validate_action(_body, nil), do: :ok
  defp validate_action(%{"action" => action}, expected) when action == expected, do: :ok
  defp validate_action(_body, _expected), do: {:error, :rejected}

  defp validate_hostname(_body, expected) when not is_binary(expected) or expected == "" do
    Logger.error("Turnstile is enabled without a configured host")
    {:error, :misconfigured}
  end

  defp validate_hostname(%{"hostname" => hostname}, expected) when hostname == expected, do: :ok
  defp validate_hostname(_body, _expected), do: {:error, :rejected}

  defp expected_hostname do
    case Application.get_env(:glossia, GlossiaWeb.Endpoint, [])[:url][:host] do
      host when is_binary(host) -> host
      _ -> nil
    end
  end

  defp config(key, default \\ nil) do
    :glossia
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
