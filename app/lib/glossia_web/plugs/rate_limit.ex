defmodule GlossiaWeb.Plugs.RateLimit do
  @moduledoc """
  A reusable plug for rate limiting requests using Hammer.

  ## Options

    * `:key_prefix` - prefix for the rate limit bucket key (required)
    * `:scale` - time window in milliseconds (required)
    * `:limit` - max requests allowed in the window (required)
    * `:by` - `:ip` (default), `:user`, `:token`, `:account`, `:client_id`, or a list
    * `:format` - `:json` (default) or `:text`
  """

  import Plug.Conn

  def init(opts) do
    %{
      key_prefix: Keyword.fetch!(opts, :key_prefix),
      scale: Keyword.fetch!(opts, :scale),
      limit: Keyword.fetch!(opts, :limit),
      by: Keyword.get(opts, :by, :ip),
      format: Keyword.get(opts, :format, :json)
    }
  end

  def call(conn, %{key_prefix: prefix, scale: scale, limit: limit, by: by, format: format}) do
    keys =
      by
      |> List.wrap()
      |> Enum.map(&bucket_key(conn, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&"#{prefix}:#{&1}")
      |> Enum.uniq()

    case hit_all(keys, scale, limit) do
      {:allow, _count} ->
        emit_telemetry(conn, prefix, by, :allow, limit, scale)
        conn

      {:deny, retry_after_ms} ->
        emit_telemetry(conn, prefix, by, :deny, limit, scale)
        rate_limited(conn, retry_after_ms, format)
    end
  end

  defp hit_all([], scale, limit), do: Glossia.RateLimiter.hit("rate_limit:unknown", scale, limit)

  defp hit_all(keys, scale, limit) do
    Enum.reduce_while(keys, {:allow, 0}, fn key, _acc ->
      case Glossia.RateLimiter.hit(key, scale, limit) do
        {:allow, count} -> {:cont, {:allow, count}}
        {:deny, retry_after_ms} -> {:halt, {:deny, retry_after_ms}}
      end
    end)
  end

  defp rate_limited(conn, retry_after_ms, :text) do
    retry_after = ceil(retry_after_ms / 1_000)

    conn
    |> put_resp_header("retry-after", Integer.to_string(retry_after))
    |> send_resp(:too_many_requests, "Rate limit exceeded")
    |> halt()
  end

  defp rate_limited(conn, retry_after_ms, _format) do
    retry_after = ceil(retry_after_ms / 1_000)

    conn
    |> put_resp_header("retry-after", Integer.to_string(retry_after))
    |> put_status(:too_many_requests)
    |> Phoenix.Controller.json(%{
      error: "too_many_requests",
      error_description: "Rate limit exceeded"
    })
    |> halt()
  end

  defp bucket_key(conn, :ip) do
    GlossiaWeb.ClientIP.value(conn)
  end

  defp bucket_key(conn, :user) do
    case conn.assigns[:current_user] do
      %{id: id} -> "user:#{id}"
      _ -> "ip:#{GlossiaWeb.ClientIP.value(conn)}"
    end
  end

  defp bucket_key(conn, :token) do
    case conn.assigns[:current_token] do
      %{id: id} when not is_nil(id) -> "token:#{id}"
      _ -> bucket_key(conn, :user)
    end
  end

  defp bucket_key(conn, :account) do
    case conn.assigns[:account] do
      %{id: id} -> "account:#{id}"
      _ -> nil
    end
  end

  defp bucket_key(conn, :client_id) do
    case conn.params["client_id"] do
      value when is_binary(value) and value != "" -> "client:#{value}"
      _ -> nil
    end
  end

  defp bucket_key(_conn, _), do: nil

  defp emit_telemetry(conn, prefix, by, decision, limit, scale) do
    :telemetry.execute(
      [:glossia, :rate_limit, :decision],
      %{count: 1},
      %{
        decision: decision,
        key_prefix: prefix,
        by: List.wrap(by),
        method: conn.method,
        path: conn.request_path,
        limit: limit,
        scale_ms: scale
      }
    )
  end
end
