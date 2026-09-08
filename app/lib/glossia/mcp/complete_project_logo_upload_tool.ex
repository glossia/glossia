defmodule Glossia.MCP.CompleteProjectLogoUploadTool do
  @moduledoc """
  Finalize a project logo upload started with `start_project_logo_upload`.

  Given the staging key returned by start, verifies the object exists with an
  allowed content type matching the key extension and a valid size, copies it
  to the canonical avatar location, deletes the staging object and any
  previously-served extensions for the same project, then persists the new
  avatar path on the project.
  """

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.ChangesetErrors
  alias Glossia.MCP.Authorization, as: Auth
  alias Glossia.Projects
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  require Logger

  @allowed_content_types ~w(image/jpeg image/png image/gif image/webp)
  @allowed_extensions ~w(jpg jpeg png gif webp)
  @max_size_bytes 5_000_000

  schema do
    field :handle, {:required, :string}, description: "Account handle that owns the project."

    field :project_handle, {:required, :string}, description: "Project handle within the account."

    field :key, {:required, :string},
      description:
        "Staging key returned by start_project_logo_upload. Must belong to the same project."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]
    project_handle = params["project_handle"]
    staging_key = params["key"]

    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :project_write, user, account),
         {:ok, project} <- fetch_project(account, project_handle),
         {:ok, ext} <- validate_key(staging_key, account, project),
         {:ok, headers} <- head_object(staging_key),
         :ok <- validate_size(headers),
         :ok <- validate_content_type(headers, ext),
         canonical_key = canonical_key(account, project, ext),
         :ok <- copy_object(staging_key, canonical_key),
         {:ok, updated} <-
           Projects.update_project(project, %{"avatar_url" => canonical_key},
             actor: user,
             via: :mcp
           ) do
      cleanup_staging(staging_key)
      cleanup_stale_avatars(account, project, ext)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(%{
            handle: account.handle,
            project_handle: updated.handle,
            avatar_url: updated.avatar_url,
            public_url:
              GlossiaWeb.Endpoint
              |> Phoenix.VerifiedRoutes.url(
                ~p"/avatars/#{account.handle}/projects/#{updated.handle}"
              )
          })
        )

      {:reply, response, frame}
    else
      {:error, %Error{} = error} ->
        {:error, error, frame}

      {:error, :key_mismatch} ->
        {:error,
         Error.execution(
           "key does not belong to this project. Use the key returned by start_project_logo_upload."
         ), frame}

      {:error, :object_missing} ->
        {:error,
         Error.execution("Upload not found at key. Confirm the PUT succeeded and try again."),
         frame}

      {:error, :missing_size} ->
        {:error,
         Error.execution("Storage did not report the uploaded file size; refusing to complete."),
         frame}

      {:error, :too_large} ->
        {:error, Error.execution("Uploaded file exceeds the #{@max_size_bytes} byte limit."),
         frame}

      {:error, :missing_content_type} ->
        {:error, Error.execution("Storage did not report a content type for the uploaded file."),
         frame}

      {:error, :content_type_mismatch} ->
        {:error,
         Error.execution(
           "Uploaded content type does not match the extension declared at start_project_logo_upload."
         ), frame}

      {:error, :unsupported_content_type} ->
        {:error,
         Error.execution(
           "Uploaded content type is not allowed. Allowed: #{Enum.join(@allowed_content_types, ", ")}"
         ), frame}

      {:error, :copy_failed} ->
        {:error, Error.execution("Could not move uploaded file into place."), frame}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error,
         Error.execution("Validation failed: #{ChangesetErrors.to_inline_string(changeset)}"),
         frame}
    end
  end

  defp fetch_project(account, project_handle) do
    case Projects.get_project(account, project_handle) do
      nil -> {:error, Error.execution("Project '#{project_handle}' not found")}
      project -> {:ok, project}
    end
  end

  defp validate_key(key, account, project) when is_binary(key) do
    prefix = "pending-avatars/#{account.id}/projects/#{project.id}/"
    remainder = String.replace_prefix(key, prefix, "")

    with true <- String.starts_with?(key, prefix),
         false <- remainder == key,
         false <- String.contains?(remainder, "/"),
         [_token, ext] <- String.split(remainder, ".", parts: 2),
         ext = String.downcase(ext),
         true <- ext in @allowed_extensions do
      {:ok, ext}
    else
      _ -> {:error, :key_mismatch}
    end
  end

  defp validate_key(_, _, _), do: {:error, :key_mismatch}

  defp head_object(key) do
    case Glossia.Storage.head(key) do
      {:ok, headers} -> {:ok, headers}
      _ -> {:error, :object_missing}
    end
  end

  defp validate_size(headers) do
    case header(headers, "content-length") do
      nil ->
        {:error, :missing_size}

      value ->
        case Integer.parse(value) do
          {size, ""} when size in 1..@max_size_bytes -> :ok
          {size, ""} when size > @max_size_bytes -> {:error, :too_large}
          _ -> {:error, :too_large}
        end
    end
  end

  defp validate_content_type(headers, ext) do
    case header(headers, "content-type") do
      nil ->
        {:error, :missing_content_type}

      value ->
        cond do
          value not in @allowed_content_types -> {:error, :unsupported_content_type}
          value != content_type_for_extension(ext) -> {:error, :content_type_mismatch}
          true -> :ok
        end
    end
  end

  defp content_type_for_extension("jpg"), do: "image/jpeg"
  defp content_type_for_extension("jpeg"), do: "image/jpeg"
  defp content_type_for_extension("png"), do: "image/png"
  defp content_type_for_extension("gif"), do: "image/gif"
  defp content_type_for_extension("webp"), do: "image/webp"

  defp canonical_key(account, project, ext) do
    ext = if ext == "jpeg", do: "jpg", else: ext
    "avatars/#{account.handle}/projects/#{project.handle}.#{ext}"
  end

  defp copy_object(source, destination) do
    case Glossia.Storage.copy(source, destination) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "Project logo copy failed source=#{source} dest=#{destination}: #{inspect(reason)}"
        )

        {:error, :copy_failed}
    end
  end

  defp cleanup_staging(staging_key) do
    case Glossia.Storage.delete(staging_key) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "Project logo staging cleanup failed key=#{staging_key}: #{inspect(reason)}"
        )

        :ok
    end
  end

  defp cleanup_stale_avatars(account, project, kept_ext) do
    kept = if kept_ext == "jpeg", do: "jpg", else: kept_ext

    Enum.each(@allowed_extensions -- [kept], fn ext ->
      key = "avatars/#{account.handle}/projects/#{project.handle}.#{ext}"

      case Glossia.Storage.delete(key) do
        {:ok, _} -> :ok
        {:error, _} -> :ok
      end
    end)
  end

  defp header(headers, name) do
    downcased = String.downcase(name)

    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(to_string(k)) == downcased, do: to_string(v)
    end)
  end
end
