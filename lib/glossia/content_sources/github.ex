defmodule Glossia.ContentSources.GitHub do
  @moduledoc false

  require Logger

  @behaviour Glossia.ContentSources.ContentSource

  # Glossia.ContentSources.ContentSource behavior

  @impl Glossia.ContentSources.ContentSource
  def get_content(content_source_id, file_path, {:version, commit_sha}) do
    {client, owner, repo} = get_client_owner_and_repo(content_source_id)

    Logger.debug("Fetching the content of a file", %{
      owner: owner,
      repo: repo,
      file_path: file_path,
      commit_sha: commit_sha
    })

    case Tentacat.Contents.find_in(
           client,
           owner,
           repo,
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

  def get_content(content_source_id, file_path, :latest) do
    {owner, repo} = get_owner_and_repo(content_source_id)

    Logger.debug("Fetching the latest content of a file", %{
      owner: owner,
      repo: repo,
      file_path: file_path
    })

    case get_most_recent_version(content_source_id) do
      {:ok, commit_sha} -> content_source_id |> get_content(file_path, {:version, commit_sha})
      {:error, body} -> {:error, body}
    end
  end

  defp send_graphql_query(content_source_id, query, variables \\ %{}) do
    {access_token, owner, repo} = get_access_token_owner_and_repo(content_source_id)

    Neuron.query(
      query,
      Map.merge(variables, %{"owner" => owner, "repo" => repo}),
      url: "https://api.github.com/graphql",
      headers: [
        authorization: "Bearer #{access_token}"
      ]
    )
  end

  @impl Glossia.ContentSources.ContentSource
  def get_most_recent_version(content_source_id) do
    {owner, repo} = get_owner_and_repo(content_source_id)
    Logger.debug("Fetching the most recent version", %{owner: owner, repo: repo})

    response =
      send_graphql_query(
        content_source_id,
        """
        query getMostRecentCommit($owner: String!, $repo: String!) {
          repository(owner: $owner, name: $repo) {
            ref(qualifiedName: "refs/heads/main") {
              target {
                ... on Commit {
                  history(first: 1) {
                    edges {
                      node {
                        messageHeadline
                        oid
                        committedDate
                        author {
                          name
                          email
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """
      )

    case response do
      {:ok, %{body: body}} ->
        %{
          "data" => %{
            "repository" => %{
              "ref" => %{
                "target" => %{
                  "history" => %{"edges" => [%{"node" => %{"oid" => commit_sha}} | _]}
                }
              }
            }
          }
        } = body

        commit_sha

      {:error, error} ->
        error
    end
  end

  @impl Glossia.ContentSources.ContentSource
  def update_content(
        _content_source_id,
        %{
          content: []
        }
      ) do
    # Noop
  end

  @impl Glossia.ContentSources.ContentSource
  def update_content(
        content_source_id,
        %{
          title: commit_title,
          description: commit_description,
          version: commit_sha,
          content: content
        } = opts
      ) do
    {client, owner, repo} = get_client_owner_and_repo(content_source_id)

    Logger.debug(
      "Updating the content",
      opts |> Map.merge(%{owner: owner, repo: repo})
    )

    with {:branch, {status, [%{"name" => branch} | _], _}} when status in 200..299 <-
           {:branch,
            Tentacat.get(
              "repos/#{owner}/#{repo}/commits/#{commit_sha}/branches-where-head",
              client
            )},
         {:fetch_head_commit,
          {status, %{"commit" => %{"tree" => %{"sha" => commit_tree_sha}}}, _}}
         when status in 200..299 <-
           {:fetch_head_commit, Tentacat.Commits.find(client, commit_sha, owner, repo)},
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
           {:tree_creation, Tentacat.post("repos/#{owner}/#{repo}/git/trees", client, tree)},
         {:commit_creation, {status, %{"sha" => created_commit_sha, "html_url" => commit_url}, _}}
         when status in 200..299 <-
           {:commit_creation,
            Tentacat.post("repos/#{owner}/#{repo}/git/commits", client, %{
              message: "#{commit_title}\n#{commit_description}",
              parents: [commit_sha],
              tree: created_tree
            })},
         {:reference_update, {status, _, _}} when status in 200..299 <-
           {:reference_update,
            Tentacat.patch(
              "repos/#{owner}/#{repo}/git/refs/heads/#{branch}",
              client,
              %{sha: created_commit_sha, force: false}
            )} do
      {:ok, %{id: created_commit_sha, url: commit_url}}
    else
      {:fetch_head_commit, {_, body, _}} -> {:error, body}
      {:commit_creation, {_, body, _}} -> {:error, body}
      {:branch, {200, [] = _, _}} -> {:error, :newer_version_exists}
      {:branch, {_, body, _}} -> {:error, body}
      {:tree_creation, {_, body, _}} -> {:error, body}
      {:reference_update, {_, body, _}} -> {:error, body}
    end
  end

  @impl Glossia.ContentSources.ContentSource
  def get_content_branch_id(content_source_id, %{version: commit_sha} = opts) do
    {client, owner, repo} = get_client_owner_and_repo(content_source_id)

    Logger.debug(
      "Getting the branch id",
      opts |> Map.merge(%{owner: owner, repo: repo})
    )

    case Tentacat.get(
           "repos/#{owner}/#{repo}/commits/#{commit_sha}/branches-where-head",
           client
         ) do
      {status, [%{"name" => branch} | _], _} when status in 200..299 ->
        branch

      {200, [] = _, _} ->
        nil

      {_, _, _} ->
        nil
    end
  end

  @impl Glossia.ContentSources.ContentSource
  def should_localize?(content_source_id, commit_sha) do
    {client, owner, repo} = get_client_owner_and_repo(content_source_id)

    Logger.debug(
      "Checking if the commit with the sha #{commit_sha} should be localized",
      %{owner: owner, repo: repo}
    )

    case Tentacat.Commits.find(client, commit_sha, owner, repo) do
      {status, payload, _} when status in 200..299 ->
        %{"author" => %{"login" => login}} = payload
        login != Glossia.GitHub.App.bot_handle()

      {_, body, _} ->
        {:error, body}
    end
  end

  @impl Glossia.ContentSources.ContentSource
  def update_state(content_source_id, state, commit_sha, opts \\ []) do
    {client, owner, repo} = get_client_owner_and_repo(content_source_id)

    Logger.debug(
      "Updating the state for commit #{commit_sha} to #{state}",
      %{owner: owner, repo: repo}
    )

    params =
      %{
        state: Atom.to_string(state),
        context:
          if([:prod, :can] |> Enum.member?(Application.get_env(:glossia, :env)),
            do: "Glossia",
            else: "Glossia (Dev)"
          )
      }
      |> Map.merge(Map.new(opts))

    case Tentacat.post(
           "repos/#{owner}/#{repo}/statuses/#{commit_sha}",
           client,
           params
         ) do
      {status, _, _} when status in 200..299 ->
        :ok

      {_, body, response} ->
        {:error, body, response}
    end
  end

  @impl Glossia.ContentSources.ContentSource
  def generate_auth_token(content_source_id) do
    {owner, repo} = get_owner_and_repo(content_source_id)

    Logger.debug(
      "Generating an auth token for the repo",
      %{owner: owner, repo: repo}
    )

    app_jwt_token = Glossia.GitHub.AppToken.generate_and_sign!()
    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    with {:installation, {status, %{"id" => installation_id}, _}} when status in 200..299 <-
           {:installation,
            Tentacat.get(
              "repos/#{owner}/#{repo}/installation",
              client
            )},
         {:access_token, {status, %{"token" => access_token}, _}} when status in 200..299 <-
           {:access_token,
            Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{
              repositories: [repo]
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
  @impl Glossia.ContentSources.ContentSource
  def is_webhook_payload_valid?(req_headers, payload) do
    case signature_from_req_headers(req_headers) do
      nil ->
        false

      signature ->
        is_payload_signature_valid?(signature, payload)
    end
  end

  @impl Glossia.ContentSources.ContentSource
  def get_versions(content_source_id, opts \\ []) do
    # {client, owner, repo} = get_client_owner_and_repo(content_source_id)

    # Logger.debug(
    #   "Getting versions",
    #   %{owner: owner, repo: repo}
    # )

    # {_status, _body, _response} =
    #   Tentacat.get(
    #     "repos/#{owner}/#{repo}/commits",
    #     client,
    #     %{
    #       per_page: Keyword.get(opts, :per_page, 2),
    #       page: Keyword.get(opts, :page, 1)
    #     }
    #   )

    {:ok, []}
  end

  @spec get_access_token_for_installation(
          installation_id :: integer(),
          app_jwk_token :: String.t() | nil
        ) ::
          Tentacat.Client.t()
  defp get_access_token_for_installation(installation_id, app_jwk_token) do
    app_jwt_token =
      if app_jwk_token != nil do
        app_jwk_token
      else
        Glossia.GitHub.AppToken.generate_and_sign!()
      end

    client = Tentacat.Client.new(%{jwt: app_jwt_token})

    {201, %{"token" => access_token}, _} =
      Tentacat.post("app/installations/#{installation_id}/access_tokens", client, %{})

    access_token
  end

  defp get_owner_and_repo(content_source_id) do
    [owner, repo] = content_source_id |> String.split("/")
    {owner, repo}
  end

  defp get_access_token_owner_and_repo(content_source_id) do
    app_jwt_token = Glossia.GitHub.AppToken.generate_and_sign!()

    {200, %{"id" => installation_id}, _} =
      Tentacat.get(
        "repos/#{content_source_id}/installation",
        Tentacat.Client.new(%{jwt: app_jwt_token})
      )

    {owner, repo} = get_owner_and_repo(content_source_id)
    access_token = get_access_token_for_installation(installation_id, app_jwt_token)
    {access_token, owner, repo}
  end

  defp get_client_owner_and_repo(content_source_id) do
    {access_token, owner, repo} = get_access_token_owner_and_repo(content_source_id)
    client = %{access_token: access_token} |> Tentacat.Client.new()
    {client, owner, repo}
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
    Glossia.Secrets.get_in([:github, :app, :webhooks_secret])
  end
end
