defmodule GlossiaWeb.OgImageController do
  use GlossiaWeb, :controller
  alias Glossia.OgImage

  plug :uncacheable

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "og_image",
    scale: :timer.minutes(1),
    limit: 30,
    by: :ip,
    format: :text

  def marketing(conn, params), do: serve(conn, params)
  def account(conn, params), do: serve(conn, params)
  def project(conn, params), do: serve(conn, params)

  defp serve(conn, %{"hash" => filename, "d" => token}) do
    with {:ok, %{attrs: attrs, day: day}} <- OgImage.verify_attrs(token),
         true <- filename == OgImage.hash(attrs, day) <> ".jpg" do
      # The verified hash is the entire object identity. Arbitrary route aliases
      # or query parameters cannot multiply stored objects or browser renders.
      key = "og/images/#{filename}"

      case OgImage.fetch_or_generate(key, attrs, day) do
        {:ok, bytes} when byte_size(bytes) > 0 ->
          conn
          |> put_resp_content_type("image/jpeg", nil)
          |> put_resp_header("cache-control", "public, max-age=86400, immutable")
          |> put_resp_header("etag", ~s("#{filename}"))
          |> put_resp_header("x-content-type-options", "nosniff")
          |> send_resp(200, bytes)

        {:error, :expired} ->
          invalid(conn)

        _ ->
          conn
          |> put_resp_header("cache-control", "no-store")
          |> put_resp_header("retry-after", "60")
          |> send_resp(503, "Image temporarily unavailable")
      end
    else
      _ -> invalid(conn)
    end
  end

  defp serve(conn, _), do: invalid(conn)

  defp invalid(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(404, "Image not found")
  end

  defp uncacheable(conn, _opts), do: put_resp_header(conn, "cache-control", "no-store")
end
