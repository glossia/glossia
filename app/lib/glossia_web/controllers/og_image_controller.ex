defmodule GlossiaWeb.OgImageController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.OgImage

  def marketing(conn, %{"category" => category, "hash" => hash} = params) do
    s3_path = "og/marketing/#{category}/#{hash}"
    fallback = %{title: category, description: "", category: category}
    attrs = decode_attrs(params, fallback)
    serve_og_image(conn, s3_path, attrs)
  end

  def account(conn, %{"handle" => handle, "hash" => hash} = params) do
    s3_path = "og/app/#{handle}/#{hash}"
    fallback = %{title: handle, description: "", category: "account"}
    attrs = decode_attrs(params, fallback)
    serve_og_image(conn, s3_path, attrs)
  end

  def project(conn, %{"handle" => handle, "project" => project, "hash" => hash} = params) do
    s3_path = "og/app/#{handle}/#{project}/#{hash}"
    fallback = %{title: project, description: "", category: "project"}
    attrs = decode_attrs(params, fallback)
    serve_og_image(conn, s3_path, attrs)
  end

  defp decode_attrs(%{"d" => token}, fallback) when is_binary(token) do
    case OgImage.verify_attrs(token) do
      {:ok, attrs} -> attrs
      _ -> fallback
    end
  end

  defp decode_attrs(_params, fallback), do: fallback

  defp serve_og_image(conn, s3_path, attrs) do
    case OgImage.fetch_or_generate(s3_path, attrs) do
      {:ok, bytes} when byte_size(bytes) > 0 ->
        conn
        |> put_resp_content_type("image/jpeg")
        |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
        |> send_resp(200, bytes)

      {:ok, _empty} ->
        Logger.error("OG image generation returned empty bytes for: #{s3_path}")
        fallback_redirect(conn)

      {:error, reason} ->
        Logger.error("OG image serve failed for #{s3_path}: #{inspect(reason)}")
        fallback_redirect(conn)
    end
  end

  defp fallback_redirect(conn) do
    conn
    |> put_resp_header("cache-control", "no-cache")
    |> redirect(to: "/images/logo-squared.jpg")
  end
end
