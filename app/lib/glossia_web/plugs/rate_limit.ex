defmodule GlossiaWeb.Plugs.RateLimit do
  @moduledoc """
  A reusable plug for rate limiting requests using Hammer.

  ## Options

    * `:key_prefix` - prefix for the rate limit bucket key (required)
    * `:scale` - time window in milliseconds (required)
    * `:limit` - max requests allowed in the window (required)
    * `:by` - `:ip` (default) or `:user`
  """

  import Plug.Conn

  def init(opts) do
    %{
      key_prefix: Keyword.fetch!(opts, :key_prefix),
      scale: Keyword.fetch!(opts, :scale),
      limit: Keyword.fetch!(opts, :limit),
      by: Keyword.get(opts, :by, :ip)
    }
  end

  def call(conn, %{key_prefix: prefix, scale: scale, limit: limit, by: by}) do
    key = "#{prefix}:#{bucket_key(conn, by)}"

    case Glossia.RateLimiter.hit(key, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, retry_after_ms} ->
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
  end

  defp bucket_key(conn, :ip) do
    conn.remote_ip |> :inet.ntoa() |> to_string()
  end

  defp bucket_key(conn, :user) do
    case conn.assigns[:current_user] do
      %{id: id} -> "user:#{id}"
      _ -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
