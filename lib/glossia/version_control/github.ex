defmodule Glossia.VersionControl.GitHub do
  @moduledoc """
  An interface to interact with GitHub's API.
  """

  # Modules
  require Logger

  # Behaviors
  @behaviour Glossia.VersionControl.Platform

  # Glossia.VersionControl.Platform behavior

  @impl true
  def get_file_content(path, repository_id) do
    client = get_client_for_repository(repository_id)
    [owner, repo] = repository_id |> String.split("/")

    case Tentacat.Contents.find(client, owner, repo, path) do
      {status, content, _} when status in 200..299 -> {:ok, content}
      {_, body, response} -> {:error, body, response}
    end
  end

  @impl true
  def create_commit_status(attrs) do
    repository_id = attrs |> Keyword.fetch!(:repository_id)
    commit_sha = attrs |> Keyword.fetch!(:commit_sha)
    client = get_client_for_repository(repository_id)

    params =
      attrs
      |> Keyword.drop([:commit_sha, :repository_id])
      |> Enum.into(%{})

    case Tentacat.post("repos/#{repository_id}/statuses/#{commit_sha}", client, params) do
      {status, _, _} when status in 200..299 ->
        :ok

      {_, body, response} ->
        {:error, body, response}
    end
  end

  @doc """
  Given a user session it traverses the installations the user has access
  to and returns the repositories of those installations.
  """
  @spec get_user_repositories(auth :: Tentacat.Client.auth()) :: [map()]
  def get_user_repositories(auth) do
    {200, installation_data, _response} = get_user_installations(auth)

    installation_data["installations"]
    |> Enum.map(& &1["id"])
    |> Enum.flat_map(fn installation_id ->
      {200, repositories_data, _response} =
        get_user_installation_repositories(auth, installation_id)

      repositories_data["repositories"]
    end)
  end

  @doc """
  Given a user session, it returns all the app installations the user has access to.
  """
  @spec get_user_installations(client :: Tentacat.Client.t()) :: Tentacat.response()
  def get_user_installations(client) do
    Tentacat.App.Installations.list_for_user(client)
  end

  @doc """
  Given a user session and an installation id it returns all the repositories the installation
  has access to.
  """
  @spec get_user_installation_repositories(
          client :: Tentacat.Client.t(),
          installation_id :: integer()
        ) ::
          Tentacat.response()
  def get_user_installation_repositories(client, installation_id) do
    Tentacat.App.Installations.list_repositories_for_user(client, installation_id)
  end

  @doc """
  Given the request headers and the payload it validates the payload signature.
  """
  @impl true
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
  @impl true
  def get_webhook_processor(event, payload) when event == "push" do
    Logger.info("Processing GitHub webhook: #{event}")
    repository_id = payload["repository"]["full_name"]
    commit_sha = payload["after"]
    ref = payload["ref"]
    default_branch = payload["repository"]["default_branch"]

    {:push,
     %{
       commit_sha: commit_sha,
       repository_id: repository_id,
       ref: ref,
       default_branch: default_branch,
       vcs: :github
     }}
  end

  @impl true
  def get_webhook_processor(event, _payload) do
    Logger.info("Processing an unsupported GitHub webhook event: #{event}")
    nil
  end

  @impl true
  def generate_token_for_cloning(repository_id) do
    app_jwt_token = Glossia.VersionControl.GitHub.AppToken.generate_and_sign!()
    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    {200, %{"id" => installation_id}, _} =
      Tentacat.get(
        "repos/#{repository_id}/installation",
        client
      )

    {201, %{"token" => access_token}, _} =
      Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{
        repositories: [repository_id |> String.split("/") |> List.last()]
      })

    access_token
  end

  # Private

  @spec get_client_for_installation(
          installation_id :: integer(),
          app_jwk_token :: String.t() | nil
        ) ::
          Tentacat.Client.t()
  defp get_client_for_installation(installation_id, app_jwk_token) do
    app_jwt_token = app_jwk_token || Glossia.VersionControl.GitHub.AppToken.generate_and_sign!()
    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    {201, %{"token" => access_token}, _} =
      Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{})

    %{access_token: access_token} |> Tentacat.Client.new()
  end

  defp get_client_for_repository(repository_id) do
    app_jwt_token = Glossia.VersionControl.GitHub.AppToken.generate_and_sign!()

    {200, %{"id" => installation_id}, _} =
      Tentacat.get(
        "repos/#{repository_id}/installation",
        Tentacat.Client.new(%{jwt: app_jwt_token})
      )

    get_client_for_installation(installation_id, app_jwt_token)
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
    Application.get_env(:glossia, :github_app_webhooks_secret)
  end
end
