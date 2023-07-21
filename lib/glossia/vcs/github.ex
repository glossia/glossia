defmodule Glossia.VCS.Github do
  @moduledoc """
  An interface to interact with GitHub's API.
  """

  @doc """
  Given a user session it traverses the installations the user has access
  to and returns the repositories of those installations.
  """
  @spec user_repositories(auth :: Tentacat.Client.auth()) :: [map()]
  def user_repositories(auth) do
    {200, installation_data, _response} = user_installations(auth)

    installation_data["installations"]
    |> Enum.map(& &1["id"])
    |> Enum.flat_map(fn installation_id ->
      {200, repositories_data, _response} =
        user_installation_repositories(auth, installation_id)

      repositories_data["repositories"]
    end)
  end

  @doc """
  Given a user session, it returns all the app installations the user has access to.
  """
  @spec user_installations(auth :: Tentacat.Client.auth()) :: Tentacat.response()
  def user_installations(auth) do
    Tentacat.App.Installations.list_for_user(client(auth))
  end

  @doc """
  Given a user session and an installation id it returns all the repositories the installation
  has access to.
  """
  @spec user_installation_repositories(
          auth :: Tentacat.Client.auth(),
          installation_id :: integer()
        ) ::
          Tentacat.response()
  def user_installation_repositories(auth, installation_id) do
    Tentacat.App.Installations.list_repositories_for_user(client(auth), installation_id)
  end

  @doc """
  Given the request headers and the payload it validates the payload signature.
  """
  def is_webhook_payload_valid?(req_headers, payload) do
    case signature_from_req_headers(req_headers) do
      nil ->
        false

      signature ->
        is_payload_signature_valid?(signature, payload)
    end
  end

  @doc """
  It processes a webhook sent by GitHub.
  """
  @spec process_webhook(event :: String.t(), payload :: map()) :: nil
  def process_webhook(event, payload) do
    Glossia.VCS.Github.WebhookProcessor.process_webhook(event, payload)
  end

  @spec client(auth :: Tentacat.Client.auth()) :: Tentacat.Client.t()
  defp client(auth) do
    Tentacat.Client.new(auth)
  end

  defp signature_from_req_headers(req_headers) do
    case List.keyfind(req_headers, "x-hub-signature", 0) do
      {"x-hub-signature", full_signature} ->
        "sha1=" <> signature = full_signature
        signature

      _ ->
        nil
    end
  end

  defp is_payload_signature_valid?(payload_signature, payload) do
    case generate_payload_signature(payload, webhook_secret()) do
      {:ok, generated_payload_signature} ->
        Plug.Crypto.secure_compare(generated_payload_signature, payload_signature)

      _ ->
        false
    end
  end

  defp generate_payload_signature(_, nil) do
    {:error, :missing_app_secret}
  end

  defp generate_payload_signature(payload, app_secret) do
    {:ok, :crypto.mac(:hmac, :sha, app_secret, payload) |> Base.encode16(case: :lower)}
  end

  defp webhook_secret do
    Application.get_env(:glossia, :secrets)[:github_webhooks]
  end
end
