defmodule GlossiaWeb.AvatarController do
  use GlossiaWeb, :controller

  @doc """
  Serves project avatars from S3, proxying the response to avoid CORS issues.
  The avatar is stored at `avatars/{handle}/projects/{project_handle}.{ext}` in S3.
  We try common image extensions and serve the first match.
  """
  def project(conn, %{"handle" => handle, "project_handle" => project_handle}) do
    extensions = ["png", "jpg", "jpeg", "gif", "webp"]

    result =
      Enum.find_value(extensions, fn ext ->
        s3_path = "avatars/#{handle}/projects/#{project_handle}.#{ext}"

        case Glossia.Storage.download(s3_path) do
          {:ok, %{body: body}} -> {ext, body}
          _ -> nil
        end
      end)

    case result do
      {ext, body} ->
        content_type = ext_to_content_type(ext)

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=3600, must-revalidate")
        |> send_resp(200, body)

      nil ->
        send_resp(conn, 404, "")
    end
  end

  @doc """
  Serves user avatars from S3.
  The avatar is stored at `avatars/users/{user_id}.{ext}` in S3.
  """
  def user(conn, %{"user_id" => user_id}) do
    extensions = ["png", "jpg", "jpeg", "gif", "webp"]

    result =
      Enum.find_value(extensions, fn ext ->
        s3_path = "avatars/users/#{user_id}.#{ext}"

        case Glossia.Storage.download(s3_path) do
          {:ok, %{body: body}} -> {ext, body}
          _ -> nil
        end
      end)

    case result do
      {ext, body} ->
        content_type = ext_to_content_type(ext)

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=3600, must-revalidate")
        |> send_resp(200, body)

      nil ->
        send_resp(conn, 404, "")
    end
  end

  defp ext_to_content_type("jpg"), do: "image/jpeg"
  defp ext_to_content_type("jpeg"), do: "image/jpeg"
  defp ext_to_content_type("png"), do: "image/png"
  defp ext_to_content_type("gif"), do: "image/gif"
  defp ext_to_content_type("webp"), do: "image/webp"
  defp ext_to_content_type(_), do: "application/octet-stream"
end
