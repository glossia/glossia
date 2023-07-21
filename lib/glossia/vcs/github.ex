defmodule Glossia.VCS.Github do
  @moduledoc """
  An interface to interact with GitHub's API.
  """

  @spec create_commit_status(
          client :: Tentacat.Client.t(),
          repository_id :: integer(),
          commit_sha :: String.t(),
          attrs :: %{
            state: String.t(),
            target_url: String.t() | nil,
            description: String.t() | nil,
            context: String.t() | nil
          }
        ) ::
          Tentacat.response()
  def create_commit_status(client, repository_id, commit_sha, attrs) do
    Tentacat.post("repos/#{repository_id}/statuses/#{commit_sha}", client, attrs)
  end

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
  @spec user_installations(client :: Tentacat.Client.t()) :: Tentacat.response()
  def user_installations(client) do
    Tentacat.App.Installations.list_for_user(client)
  end

  @doc """
  Given a user session and an installation id it returns all the repositories the installation
  has access to.
  """
  @spec user_installation_repositories(
          client :: Tentacat.Client.t(),
          installation_id :: integer()
        ) ::
          Tentacat.response()
  def user_installation_repositories(client, installation_id) do
    Tentacat.App.Installations.list_repositories_for_user(client, installation_id)
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

  @spec get_client_for_installation(
          installation_id :: integer(),
          app_jwk_token :: String.t() | nil
        ) ::
          Tentacat.Client.t()
  def get_client_for_installation(installation_id, app_jwk_token \\ nil) do
    app_jwt_token = app_jwk_token || Glossia.VCS.Github.AppToken.generate_and_sign!()

    {201, %{"token" => access_token}, _} =
      Tentacat.Client.new(%{jwt: app_jwt_token})
      |> Tentacat.App.Installations.token(installation_id)

    %{access_token: access_token} |> Tentacat.Client.new()
  end

  def get_client_for_repository(repository_id) do
    app_jwt_token = Glossia.VCS.Github.AppToken.generate_and_sign!()

    Tentacat.get(
      "repos/#{repository_id}/installation",
      Tentacat.Client.new(%{jwt: app_jwt_token})
    )
    |> case do
      {200, %{"id" => installation_id}, _} ->
        get_client_for_installation(installation_id, app_jwt_token)

      {404, %{}, _} ->
        nil
    end
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
