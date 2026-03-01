defmodule GlossiaWeb.OgImageController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.OgImage

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "og_image",
    scale: :timer.minutes(1),
    limit: 30,
    by: :ip,
    format: :text

  def marketing(conn, %{"category" => category, "hash" => hash} = params) do
    s3_path = "og/marketing/#{category}/#{hash}"

    with {:ok, attrs} <- decode_attrs(params),
         :ok <- validate_hash(attrs, hash) do
      serve_og_image(conn, s3_path, attrs)
    else
      _ -> fallback_redirect(conn)
    end
  end

  def account(conn, %{"handle" => handle, "hash" => hash} = params) do
    s3_path = "og/app/#{handle}/#{hash}"

    with {:ok, attrs} <- decode_attrs(params),
         :ok <- validate_hash(attrs, hash) do
      serve_og_image(conn, s3_path, attrs)
    else
      _ -> fallback_redirect(conn)
    end
  end

  def project(conn, %{"handle" => handle, "project" => project, "hash" => hash} = params) do
    s3_path = "og/app/#{handle}/#{project}/#{hash}"

    with {:ok, attrs} <- decode_attrs(params),
         :ok <- validate_hash(attrs, hash) do
      serve_og_image(conn, s3_path, attrs)
    else
      _ -> fallback_redirect(conn)
    end
  end

  defp decode_attrs(%{"d" => token}) when is_binary(token) do
    case OgImage.verify_attrs(token) do
      {:ok, attrs} -> {:ok, attrs}
      _ -> {:error, :invalid_token}
    end
  end

  defp decode_attrs(_params), do: {:error, :missing_token}

  defp validate_hash(attrs, route_hash) do
    expected_hash = OgImage.hash(attrs)
    actual_hash = normalize_hash(route_hash)

    if actual_hash == expected_hash do
      :ok
    else
      {:error, :invalid_hash}
    end
  end

  defp normalize_hash(hash) when is_binary(hash) do
    hash
    |> String.split(".", parts: 2)
    |> List.first()
  end

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
    |> redirect(to: ~p"/images/logo-squared.jpg")
  end
end
