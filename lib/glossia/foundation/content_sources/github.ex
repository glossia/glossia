defmodule Glossia.Foundation.ContentSources.GitHub do
  @moduledoc """
  An interface to interact with GitHub's API.
  """

  # Modules
  require Logger

  # Behaviors
  @behaviour Glossia.Foundation.ContentSources.Platform
  @behaviour Glossia.Foundation.ContentSources.ContentSource

  # Struct
  defstruct [:client, :owner, :repo]
  @enforce_keys [:client, :owner, :repo]

  def new({:repository, repository_id}) do
    [owner, repo] = repository_id |> String.split("/")
    new([owner: owner, repo: repo])
  end

  def new([owner: owner, repo: repo]) do
    client = get_client_for_repository("#{owner}/#{repo}")
    %__MODULE__{client: client, owner: owner, repo: repo}
  end

  # Glossia.Foundation.ContentSources.ContentSource behavior

  @impl true
  def get_content(github, file_path, {:version, commit_sha}) do
    case Tentacat.Contents.find_in(github.client, github.owner, github.repo, file_path, commit_sha) do
      {status, payload, _response} when status in 200..299 ->
        %{"content" => content, "encoding" => "base64"} = payload
        {:ok, Base.decode64!(content, ignore: :whitespace)}

      {_, body, _response} ->
        {:error, body}
    end
  end

  def get_content(github, file_path, :latest) do
    with {:most_recent_commit, {:ok, commit_sha}} <- {:most_recent_commit, get_most_recent_version(github)} do
      github |> get_content(file_path, {:version, commit_sha})
    else
      {:most_recent_commit, {:error, body}} -> {:error, body}
    end
  end

  def get_most_recent_version(github) do
    with {:repository, {status, %{ "default_branch" => default_branch}, _} } when status in 200..299  <- {:repository, Tentacat.Repositories.repo_get(github.client, github.owner, github.repo)},
    {:commits, {status, [most_recent_commit | _], _}} when status in 200..299 <- {:commits, Tentacat.get("repos/#{github.owner}/#{github.repo}/commits?#{default_branch}", github.client)} do
      %{ "sha" => commit_sha } = most_recent_commit
      {:ok, commit_sha}
    else
      {:repository, {_, body, _}} -> {:error, body}
      {:commits, {_, body, _}} -> {:error, body}
    end
  end

  # Glossia.Foundation.ContentSources.Platform behavior

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
  def create_commit_status(%{vcs_id: vcs_id, commit_sha: commit_sha} = attrs) do
    client = get_client_for_repository(vcs_id)

    params =
      attrs
      |> Map.drop([:commit_sha, :vcs_id])
      |> Enum.into(%{})

    case Tentacat.post("repos/#{vcs_id}/statuses/#{commit_sha}", client, params) do
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

  @impl true
  def generate_token_for_cloning(vcs_id) do
    app_jwt_token = Glossia.Foundation.ContentSources.GitHub.AppToken.generate_and_sign!()
    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    {200, %{"id" => installation_id}, _} =
      Tentacat.get(
        "repos/#{vcs_id}/installation",
        client
      )

    {201, %{"token" => access_token}, _} =
      Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{
        repositories: [vcs_id |> String.split("/") |> List.last()]
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
    app_jwt_token =
      app_jwk_token || Glossia.Foundation.ContentSources.GitHub.AppToken.generate_and_sign!()

    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    {201, %{"token" => access_token}, _} =
      Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{})

    %{access_token: access_token} |> Tentacat.Client.new()
  end

  defp get_client_for_repository(vcs_id) do
    app_jwt_token = Glossia.Foundation.ContentSources.GitHub.AppToken.generate_and_sign!()

    {200, %{"id" => installation_id}, _} =
      Tentacat.get(
        "repos/#{vcs_id}/installation",
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
