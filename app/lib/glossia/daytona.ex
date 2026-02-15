defmodule Glossia.Daytona do
  @moduledoc false

  # -- Config helpers -------------------------------------------------------

  defp config do
    Application.get_env(:glossia, __MODULE__, [])
  end

  defp fetch_api_key(opts) do
    case Keyword.get(opts, :api_key) do
      key when is_binary(key) and key != "" ->
        {:ok, key}

      _ ->
        case config() |> Keyword.get(:api_key) do
          key when is_binary(key) and key != "" -> {:ok, key}
          _ -> {:error, :not_configured}
        end
    end
  end

  defp api_url(opts) do
    Keyword.get(opts, :api_url) || Keyword.get(config(), :api_url, "https://app.daytona.io/api")
  end

  defp proxy_url(opts) do
    Keyword.get(opts, :proxy_url) ||
      Keyword.get(config(), :proxy_url, "https://proxy.app.daytona.io")
  end

  defp build_req(api_key, base_url, req_options) do
    [url: base_url, headers: [{"authorization", "Bearer #{api_key}"}]]
    |> Keyword.merge(req_options)
    |> Glossia.HTTP.new()
  end

  # -- Sandbox CRUD ---------------------------------------------------------

  @doc """
  Creates a new sandbox.

  ## Params

    * `:language` - sandbox language/image (e.g. `"python"`, `"node"`)
    * `:cpu` - number of CPUs (optional)
    * `:memory` - memory in MB (optional)
    * `:disk` - disk in MB (optional)
    * `:env_vars` - map of environment variables (optional)
    * `:labels` - map of labels (optional)
    * `:ephemeral` - whether the sandbox is ephemeral (optional)
    * `:auto_stop_interval` - auto-stop interval in minutes (optional, 0 = never)

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def create_sandbox(params, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = api_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      body =
        %{}
        |> maybe_put(:language, Map.get(params, :language))
        |> maybe_put(:cpu, Map.get(params, :cpu))
        |> maybe_put(:memory, Map.get(params, :memory))
        |> maybe_put(:disk, Map.get(params, :disk))
        |> maybe_put(:envVars, Map.get(params, :env_vars))
        |> maybe_put(:labels, Map.get(params, :labels))
        |> maybe_put(:ephemeral, Map.get(params, :ephemeral))
        |> maybe_put(:autoStopInterval, Map.get(params, :auto_stop_interval))

      case Req.post(build_req(api_key, url, req_options), url: "/sandbox", json: body) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Gets a sandbox by ID.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def get_sandbox(sandbox_id, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = api_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      case Req.get(build_req(api_key, url, req_options), url: "/sandbox/#{sandbox_id}") do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Lists all sandboxes.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def list_sandboxes(opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = api_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      case Req.get(build_req(api_key, url, req_options), url: "/sandbox") do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Deletes a sandbox by ID.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def delete_sandbox(sandbox_id, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = api_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      case Req.delete(build_req(api_key, url, req_options), url: "/sandbox/#{sandbox_id}") do
        {:ok, %Req.Response{status: status}} when status in 200..299 ->
          :ok

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Starts a stopped sandbox.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def start_sandbox(sandbox_id, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = api_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      case Req.post(build_req(api_key, url, req_options), url: "/sandbox/#{sandbox_id}/start") do
        {:ok, %Req.Response{status: status}} when status in 200..299 ->
          :ok

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Stops a running sandbox.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def stop_sandbox(sandbox_id, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = api_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      case Req.post(build_req(api_key, url, req_options), url: "/sandbox/#{sandbox_id}/stop") do
        {:ok, %Req.Response{status: status}} when status in 200..299 ->
          :ok

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  # -- Command execution (Toolbox API) --------------------------------------

  @doc """
  Executes a command inside a sandbox via the Toolbox proxy API.

  ## Params

    * `:command` - the command to run (required)
    * `:cwd` - working directory (optional)
    * `:timeout` - command timeout in seconds (optional)
    * `:env` - map of environment variables (optional)

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def execute(sandbox_id, params, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = proxy_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      body =
        %{command: Map.fetch!(params, :command)}
        |> maybe_put(:cwd, Map.get(params, :cwd))
        |> maybe_put(:timeout, Map.get(params, :timeout))
        |> maybe_put(:env, Map.get(params, :env))

      case Req.post(build_req(api_key, url, req_options),
             url: "/toolbox/#{sandbox_id}/process/execute",
             json: body
           ) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  # -- File operations (Toolbox API) ----------------------------------------

  @doc """
  Uploads a file to a sandbox via the Toolbox proxy API.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def upload_file(sandbox_id, remote_path, file_content, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = proxy_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      encoded_path = URI.encode(remote_path)

      case Req.post(build_req(api_key, url, req_options),
             url: "/toolbox/#{sandbox_id}/files/upload?path=#{encoded_path}",
             body: file_content,
             headers: [{"content-type", "application/octet-stream"}]
           ) do
        {:ok, %Req.Response{status: status}} when status in 200..299 ->
          :ok

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Downloads a file from a sandbox via the Toolbox proxy API.

  ## Options

    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to Req (useful for testing)
  """
  def download_file(sandbox_id, remote_path, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      url = proxy_url(opts)
      req_options = Keyword.get(opts, :req_options, [])

      encoded_path = URI.encode(remote_path)

      case Req.get(build_req(api_key, url, req_options),
             url: "/toolbox/#{sandbox_id}/files/download?path=#{encoded_path}"
           ) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  # -- Helpers --------------------------------------------------------------

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
