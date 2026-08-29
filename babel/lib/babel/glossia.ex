defmodule Babel.Glossia do
  @moduledoc """
  Client for Glossia's internal read-only database interface.

  Babel authenticates with a short-lived projected Kubernetes service-account
  token. It never receives production Glossia database credentials.
  """

  require Logger

  @default_receive_timeout 30_000

  def configured?(opts \\ []) do
    client = client(opts)
    is_binary(client.base_url) and token_available?(client)
  end

  def query(sql, opts \\ []) when is_binary(sql) do
    body =
      case Keyword.get(opts, :limit) do
        limit when is_integer(limit) and limit > 0 -> %{"query" => sql, "limit" => limit}
        _ -> %{"query" => sql}
      end

    request(:post, "/api/internal/babel/db/query", [json: body], opts)
  end

  defp request(method, path, request_opts, client_opts) do
    client = client(client_opts)

    with {:ok, token} <- fetch_token(client),
         {:ok, url} <- request_url(client.base_url, path) do
      request =
        Req.new(
          [
            method: method,
            url: url,
            auth: {:bearer, token},
            receive_timeout: client.receive_timeout,
            headers: [{"accept", "application/json"}]
          ] ++ request_opts
        )

      case client.request.(request) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: %{"error" => error}}} ->
          Logger.warning("Glossia internal API #{method} #{path} failed: status=#{status}")
          {:error, to_string(error)}

        {:ok, %Req.Response{status: status}} ->
          Logger.warning("Glossia internal API #{method} #{path} failed: status=#{status}")
          {:error, "Glossia returned status #{status}."}

        {:error, reason} ->
          Logger.warning(
            "Glossia internal API #{method} #{path} transport error: #{inspect(reason)}"
          )

          {:error, "Could not reach Glossia."}
      end
    end
  end

  defp fetch_token(%{token: token}) when is_binary(token) and token != "", do: {:ok, token}

  defp fetch_token(%{token_path: token_path}) when is_binary(token_path) and token_path != "" do
    case File.read(token_path) do
      {:ok, contents} ->
        case String.trim(contents) do
          "" -> {:error, "The Glossia workload token file is empty."}
          token -> {:ok, token}
        end

      {:error, reason} ->
        {:error, "Could not read the Glossia workload token: #{:file.format_error(reason)}"}
    end
  end

  defp fetch_token(_client),
    do: {:error, "The Glossia internal API is not configured for this environment."}

  defp request_url(base_url, path) when is_binary(base_url) do
    case URI.parse(base_url) do
      %URI{scheme: scheme, host: host} = base_uri when is_binary(scheme) and is_binary(host) ->
        {:ok, base_uri |> URI.merge(path) |> URI.to_string()}

      _ ->
        {:error, "The Glossia internal API URL is invalid."}
    end
  end

  defp request_url(_base_url, _path),
    do: {:error, "The Glossia internal API is not configured for this environment."}

  defp token_available?(%{token: token}) when is_binary(token) and token != "", do: true

  defp token_available?(%{token_path: token_path})
       when is_binary(token_path) and token_path != "",
       do: File.exists?(token_path)

  defp token_available?(_client), do: false

  defp client(opts) do
    config = Application.get_env(:babel, __MODULE__, [])

    %{
      base_url: configured_option(opts, config, :base_url),
      token: configured_option(opts, config, :token),
      token_path: configured_option(opts, config, :token_path),
      receive_timeout: receive_timeout(configured_option(opts, config, :receive_timeout)),
      request: Keyword.get(opts, :request, &Req.request/1)
    }
  end

  defp configured_option(opts, config, key) do
    if Keyword.has_key?(opts, key), do: Keyword.get(opts, key), else: Keyword.get(config, key)
  end

  defp receive_timeout(timeout) when is_integer(timeout) and timeout > 0, do: timeout
  defp receive_timeout(_timeout), do: @default_receive_timeout
end
