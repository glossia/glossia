defmodule Glossia.Foundation.ContentSources.Core.GitHub do
  @moduledoc """
  An interface to interact with GitHub's API.
  """

  # Modules
  require Logger

  # Behaviors
  @behaviour Glossia.Foundation.ContentSources.Core.ContentSource

  # Struct
  defstruct [:id, :client, :owner, :repo]

  def new(id) do
    [owner, repo] = id |> String.split("/")
    client = get_client_for_repository("#{owner}/#{repo}")
    %__MODULE__{id: :github, client: client, owner: owner, repo: repo}
  end

  def new() do
    %__MODULE__{id: :github}
  end

  # Glossia.Foundation.ContentSources.Core.ContentSource behavior

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def get_content(github, file_path, {:version, commit_sha}) do
    Logger.debug("Fetching the content of a file", %{
      owner: github.owner,
      repo: github.repo,
      file_path: file_path,
      commit_sha: commit_sha
    })

    case Tentacat.Contents.find_in(
           github.client,
           github.owner,
           github.repo,
           file_path,
           commit_sha
         ) do
      {status, payload, _response} when status in 200..299 ->
        %{"content" => content, "encoding" => "base64"} = payload
        {:ok, Base.decode64!(content, ignore: :whitespace)}

      {_, body, _response} ->
        {:error, body}
    end
  end

  def get_content(github, file_path, :latest) do
    Logger.debug("Fetching the latest content of a file", %{
      owner: github.owner,
      repo: github.repo,
      file_path: file_path
    })

    case get_most_recent_version(github) do
      {:ok, commit_sha} -> github |> get_content(file_path, {:version, commit_sha})
      {:error, body} -> {:error, body}
    end
  end

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def get_most_recent_version(github) do
    Logger.debug("Fetching the most recent version", %{owner: github.owner, repo: github.repo})

    with {:repository, {status, %{"default_branch" => default_branch}, _}} when status in 200..299 <-
           {:repository, Tentacat.Repositories.repo_get(github.client, github.owner, github.repo)},
         {:commits, {status, [most_recent_commit | _], _}} when status in 200..299 <-
           {:commits,
            Tentacat.get(
              "repos/#{github.owner}/#{github.repo}/commits?#{default_branch}",
              github.client
            )} do
      %{"sha" => commit_sha} = most_recent_commit
      {:ok, commit_sha}
    else
      {:repository, {_, body, _}} -> {:error, body}
      {:commits, {_, body, _}} -> {:error, body}
    end
  end

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def update_content(
        github,
        %{
          title: commit_title,
          description: commit_description,
          version: commit_sha,
          content: content
        } = opts
      )
      when length(content) > 0 do
    Logger.debug(
      "Updating the content",
      opts |> Map.merge(%{owner: github.owner, repo: github.repo})
    )

    with {:branch, {status, [%{"name" => branch} | _], _}} when status in 200..299 <-
           {:branch,
            Tentacat.get(
              "repos/#{github.owner}/#{github.repo}/commits/#{commit_sha}/branches-where-head",
              github.client
            )},
         {:commit, {status, %{"commit" => %{"tree" => %{"sha" => commit_tree_sha}}}, _}}
         when status in 200..299 <-
           {:commit, Tentacat.Commits.find(github.client, commit_sha, github.owner, github.repo)},
         {:tree, tree} <-
           {:tree,
            %{
              base_tree: commit_tree_sha,
              tree:
                Enum.map(content, fn [id: path, content: content] ->
                  %{path: path, mode: "100644", type: "blob", content: content}
                end)
            }},
         {:tree_creation, {status, %{"sha" => created_tree}, _}} when status in 200..299 <-
           {:tree_creation,
            Tentacat.post("repos/#{github.owner}/#{github.repo}/git/trees", github.client, tree)},
         {:commit_creation, {status, %{"sha" => created_commit_sha, "html_url" => commit_url}, _}}
         when status in 200..299 <-
           {:commit_creation,
            Tentacat.post("repos/#{github.owner}/#{github.repo}/git/commits", github.client, %{
              message: "#{commit_title}\n#{commit_description}",
              parents: [commit_sha],
              tree: created_tree
            })},
         {:reference_update, {status, _, _}} when status in 200..299 <-
           {:reference_update,
            Tentacat.patch(
              "repos/#{github.owner}/#{github.repo}/git/refs/heads/#{branch}",
              github.client,
              %{sha: created_commit_sha, force: false}
            )} do
      {:ok, %{id: created_commit_sha, url: commit_url}}
    else
      {:branch, {200, [] = _, _}} -> {:error, :newer_version_exists}
      {:branch, {_, body, _}} -> {:error, body}
      {:tree_creation, {_, body, _}} -> {:error, body}
    end
  end

  def update_content(
        _github,
        %{
          content: content
        }
      )
      # credo:disable-for-next-line
      when length(content) == 0 do
    # Noop
  end

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def get_content_branch_id(github, %{version: commit_sha} = opts) do
    Logger.debug(
      "Getting the branch id",
      opts |> Map.merge(%{owner: github.owner, repo: github.repo})
    )

    case Tentacat.get(
           "repos/#{github.owner}/#{github.repo}/commits/#{commit_sha}/branches-where-head",
           github.client
         ) do
      {status, [%{"name" => branch} | _], _} when status in 200..299 ->
        branch

      {200, [] = _, _} ->
        nil

      {_, _, _} ->
        nil
    end
  end

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def should_localize?(github, commit_sha) do
    case Tentacat.Commits.find(github.client, commit_sha, github.owner, github.repo) do
      {status, payload, _} when status in 200..299 ->
        %{"author" => %{"login" => login}} = payload
        login != app_bot_user()

      {_, body, _} ->
        {:error, body}
    end
  end

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def update_state(github, state, version, opts \\ []) do
    params =
      %{
        state: Atom.to_string(state),
        context:
          if(Application.get_env(:glossia, :env) == :prod, do: "Glossia", else: "Glossia (Dev)")
      }
      |> Map.merge(Map.new(opts))

    case Tentacat.post(
           "repos/#{github.owner}/#{github.repo}/statuses/#{version}",
           github.client,
           params
         ) do
      {status, _, _} when status in 200..299 ->
        :ok

      {_, body, response} ->
        {:error, body, response}
    end
  end

  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def generate_auth_token(github) do
    app_jwt_token = Glossia.Foundation.ContentSources.Core.GitHub.AppToken.generate_and_sign!()
    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    with {:installation, {status, %{"id" => installation_id}, _}} when status in 200..299 <-
           {:installation,
            Tentacat.get(
              "repos/#{github.owner}/#{github.repo}/installation",
              client
            )},
         {:access_token, {status, %{"token" => access_token}, _}} when status in 200..299 <-
           {:access_token,
            Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{
              repositories: [github.repo]
            })} do
      {:ok, access_token}
    else
      {:installation, {_, body, _}} -> {:error, body}
      {:access_token, {_, body, _}} -> {:error, body}
    end
  end

  @doc """
  Given the request headers and the payload it validates the payload signature.
  """
  @impl Glossia.Foundation.ContentSources.Core.ContentSource
  def is_webhook_payload_valid?(_, req_headers, payload) do
    case signature_from_req_headers(req_headers) do
      nil ->
        false

      signature ->
        is_payload_signature_valid?(signature, payload)
    end
  end

  # Private

  def app_bot_user() do
    Application.get_env(:glossia, :github_app_bot_user)
  end

  @spec get_client_for_installation(
          installation_id :: integer(),
          app_jwk_token :: String.t() | nil
        ) ::
          Tentacat.Client.t()
  defp get_client_for_installation(installation_id, app_jwk_token) do
    app_jwt_token =
      app_jwk_token || Glossia.Foundation.ContentSources.Core.GitHub.AppToken.generate_and_sign!()

    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    {201, %{"token" => access_token}, _} =
      Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{})

    %{access_token: access_token} |> Tentacat.Client.new()
  end

  defp get_client_for_repository(content_source_id) do
    app_jwt_token = Glossia.Foundation.ContentSources.Core.GitHub.AppToken.generate_and_sign!()

    {200, %{"id" => installation_id}, _} =
      Tentacat.get(
        "repos/#{content_source_id}/installation",
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

  def webhook_secret do
    Application.get_env(:glossia, :github_app_webhooks_secret)
  end
end
