defmodule Glossia.Github.Client do
  @moduledoc false

  require Logger

  @github_api_url "https://api.github.com"

  def list_installation_repos(access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)
    per_page = Keyword.get(opts, :per_page, 100)
    page = Keyword.get(opts, :page, 1)

    case api_get(
           "#{api_url}/installation/repositories?per_page=#{per_page}&page=#{page}",
           access_token
         ) do
      {:ok, %{"repositories" => repos, "total_count" => total}} ->
        {:ok, %{repositories: repos, total_count: total}}

      {:error, _} = err ->
        err
    end
  end

  def list_user_repos(access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)
    per_page = Keyword.get(opts, :per_page, 100)
    page = Keyword.get(opts, :page, 1)
    sort = Keyword.get(opts, :sort, "pushed")

    case api_get(
           "#{api_url}/user/repos?per_page=#{per_page}&page=#{page}&sort=#{sort}&affiliation=owner,collaborator,organization_member",
           access_token
         ) do
      {:ok, repos} when is_list(repos) ->
        {:ok, %{repositories: repos, total_count: length(repos)}}

      {:error, _} = err ->
        err
    end
  end

  def get_repo(full_name, access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)

    case api_get("#{api_url}/repos/#{full_name}", access_token) do
      {:ok, repo} -> {:ok, repo}
      {:error, _} = err -> err
    end
  end

  def create_pull_request(full_name, params, access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)
    url = "#{api_url}/repos/#{full_name}/pulls"

    api_post(url, params, access_token)
  end

  def create_branch(full_name, branch_name, sha, access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)
    url = "#{api_url}/repos/#{full_name}/git/refs"

    api_post(url, %{ref: "refs/heads/#{branch_name}", sha: sha}, access_token)
  end

  def get_ref(full_name, ref, access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)

    api_get("#{api_url}/repos/#{full_name}/git/ref/#{ref}", access_token)
  end

  def list_commits(full_name, access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)
    per_page = Keyword.get(opts, :per_page, 30)
    page = Keyword.get(opts, :page, 1)
    sha = Keyword.get(opts, :sha, nil)

    query = "per_page=#{per_page}&page=#{page}"
    query = if sha, do: query <> "&sha=#{sha}", else: query

    api_get("#{api_url}/repos/#{full_name}/commits?#{query}", access_token)
  end

  def create_or_update_file(full_name, path, params, access_token, opts \\ []) do
    api_url = Keyword.get(opts, :api_url, @github_api_url)
    url = "#{api_url}/repos/#{full_name}/contents/#{path}"

    api_put(url, params, access_token)
  end

  defp api_get(url, access_token) do
    case Glossia.HTTP.new()
         |> Req.get(url: url, headers: headers(access_token)) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp api_post(url, body, access_token) do
    case Glossia.HTTP.new()
         |> Req.post(url: url, json: body, headers: headers(access_token)) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:error, {:api_error, status, resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp api_put(url, body, access_token) do
    case Glossia.HTTP.new()
         |> Req.put(url: url, json: body, headers: headers(access_token)) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:error, {:api_error, status, resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp headers(access_token) do
    [
      {"authorization", "token #{access_token}"},
      {"accept", "application/vnd.github+json"},
      {"x-github-api-version", "2022-11-28"}
    ]
  end
end
