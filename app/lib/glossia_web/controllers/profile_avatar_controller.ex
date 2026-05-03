defmodule GlossiaWeb.ProfileAvatarController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Events

  @max_file_size 5_000_000
  @allowed_extensions ~w(.jpg .jpeg .png .gif .webp)
  @allowed_content_types ~w(image/jpeg image/png image/gif image/webp)

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "profile_avatar_update",
         scale: :timer.hours(1),
         limit: 30,
         by: :user,
         format: :text
       ]
       when action in [:update]

  def update(conn, %{"avatar" => %Plug.Upload{} = avatar_upload}) do
    user = conn.assigns.current_user

    with :ok <- Glossia.Authz.authorize(:user_write, user, user),
         :ok <- validate_upload(avatar_upload),
         {:ok, avatar_path} <- store_avatar(user, avatar_upload),
         {:ok, _updated_user} <-
           Accounts.update_user_profile(user, %{"avatar_url" => avatar_path}) do
      Events.emit("user.avatar_updated", user.account, user,
        resource_type: "user",
        resource_id: to_string(user.id),
        resource_path: ~p"/-/settings/profile",
        summary: "Updated profile avatar"
      )

      conn
      |> put_flash(:info, gettext("Profile updated."))
      |> redirect(to: ~p"/-/settings/profile")
    else
      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, gettext("You don't have permission to do that."))
        |> redirect(to: ~p"/-/settings/profile")

      _ ->
        conn
        |> put_flash(:error, gettext("Could not update profile."))
        |> redirect(to: ~p"/-/settings/profile")
    end
  end

  def update(conn, _params) do
    conn
    |> put_flash(:error, gettext("Could not update profile."))
    |> redirect(to: ~p"/-/settings/profile")
  end

  defp validate_upload(%Plug.Upload{} = avatar_upload) do
    ext =
      avatar_upload.filename
      |> to_string()
      |> Path.extname()
      |> String.downcase()

    with :ok <- validate_extension(ext),
         :ok <- validate_content_type(avatar_upload.content_type),
         :ok <- validate_size(avatar_upload.path) do
      :ok
    end
  end

  defp validate_extension(ext) when ext in @allowed_extensions, do: :ok
  defp validate_extension(_ext), do: {:error, :invalid_extension}

  defp validate_content_type(nil), do: :ok
  defp validate_content_type(type) when type in @allowed_content_types, do: :ok
  defp validate_content_type(_type), do: {:error, :invalid_content_type}

  defp validate_size(path) do
    case File.stat(path) do
      {:ok, %{size: size}} when size <= @max_file_size -> :ok
      {:ok, _stat} -> {:error, :too_large}
      {:error, reason} -> {:error, reason}
    end
  end

  defp store_avatar(user, %Plug.Upload{} = avatar_upload) do
    ext = avatar_extension(avatar_upload)
    s3_path = "avatars/users/#{user.id}.#{ext}"

    with {:ok, content} <- File.read(avatar_upload.path),
         {:ok, _result} <-
           Glossia.Storage.upload(s3_path, content,
             content_type: avatar_upload.content_type || content_type_for_extension(ext)
           ) do
      maybe_delete_old_avatar(user.avatar_url, s3_path)
      {:ok, s3_path}
    end
  end

  defp maybe_delete_old_avatar(old_avatar_url, new_s3_path) do
    if is_binary(old_avatar_url) and String.starts_with?(old_avatar_url, "avatars/") and
         old_avatar_url != new_s3_path do
      _ = Glossia.Storage.delete(old_avatar_url)
      :ok
    else
      :ok
    end
  end

  defp avatar_extension(%Plug.Upload{} = avatar_upload) do
    case String.downcase(Path.extname(to_string(avatar_upload.filename))) do
      ".jpg" -> "jpg"
      ".jpeg" -> "jpg"
      ".png" -> "png"
      ".gif" -> "gif"
      ".webp" -> "webp"
      _ -> "jpg"
    end
  end

  defp content_type_for_extension("jpg"), do: "image/jpeg"
  defp content_type_for_extension("png"), do: "image/png"
  defp content_type_for_extension("gif"), do: "image/gif"
  defp content_type_for_extension("webp"), do: "image/webp"
  defp content_type_for_extension(_ext), do: "application/octet-stream"
end
