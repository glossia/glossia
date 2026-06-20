defmodule GlossiaWeb.UploadController do
  use GlossiaWeb, :controller

  @allowed_extensions ~w(gif jpeg jpg png webp)

  def show(conn, %{"path" => [account_id, "discussions", discussion_id, filename]}) do
    with :ok <- validate_segment(account_id),
         :ok <- validate_segment(discussion_id),
         {:ok, content_type} <- content_type(filename),
         s3_path = "uploads/#{account_id}/discussions/#{discussion_id}/#{filename}",
         {:ok, %{body: body}} <- Glossia.Storage.download(s3_path) do
      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("cache-control", "public, max-age=3600, must-revalidate")
      |> send_resp(200, body)
    else
      _ -> send_resp(conn, 404, "")
    end
  end

  def show(conn, _params), do: send_resp(conn, 404, "")

  defp validate_segment(segment) when is_binary(segment) and segment not in ["", ".", ".."],
    do: :ok

  defp validate_segment(_segment), do: :error

  defp content_type(filename) do
    ext =
      filename
      |> Path.extname()
      |> String.trim_leading(".")
      |> String.downcase()

    if ext in @allowed_extensions do
      {:ok, ext_to_content_type(ext)}
    else
      :error
    end
  end

  defp ext_to_content_type("jpg"), do: "image/jpeg"
  defp ext_to_content_type("jpeg"), do: "image/jpeg"
  defp ext_to_content_type("png"), do: "image/png"
  defp ext_to_content_type("gif"), do: "image/gif"
  defp ext_to_content_type("webp"), do: "image/webp"
end
