defmodule GlossiaWeb.UploadController do
  use GlossiaWeb, :controller

  alias Glossia.Discussions

  @allowed_extensions ~w(gif jpeg jpg png webp)

  def show(conn, %{"path" => [account_id, "discussions", discussion_id, filename]}) do
    with {:ok, account_id} <- cast_uuid(account_id),
         {:ok, discussion_id} <- cast_uuid(discussion_id),
         {:ok, content_type} <- content_type(filename),
         {:ok, discussion} <- fetch_discussion(account_id, discussion_id),
         :ok <- authorize_discussion(conn, discussion),
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

  defp cast_uuid(segment) do
    case Ecto.UUID.cast(segment) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> :error
    end
  end

  defp fetch_discussion(account_id, discussion_id) do
    case Discussions.get_discussion(discussion_id) do
      %{account_id: ^account_id} = discussion -> {:ok, discussion}
      _ -> :error
    end
  end

  defp authorize_discussion(conn, discussion) do
    if Glossia.Authz.authorize?(:discussion_read, conn.assigns[:current_user], discussion.account) do
      :ok
    else
      :error
    end
  end

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
