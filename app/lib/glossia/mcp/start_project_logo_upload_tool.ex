defmodule Glossia.MCP.StartProjectLogoUploadTool do
  @moduledoc """
  Begin a project logo upload by returning a presigned URL the client can PUT
  the image bytes to. The URL points to a private staging key that is not
  served publicly. Follow up with `complete_project_logo_upload` using the
  returned key to move the object into the canonical location and persist it
  on the project.
  """

  use Hermes.Server.Component, type: :tool

  alias Glossia.MCP.Authorization, as: Auth
  alias Glossia.Projects
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  @allowed_content_types ~w(image/jpeg image/png image/gif image/webp)
  @max_size_bytes 5_000_000
  @expires_in 300

  schema do
    field :handle, {:required, :string}, description: "Account handle that owns the project."

    field :project_handle, {:required, :string},
      description: "Project handle within the account."

    field :content_type, {:required, :string},
      description:
        "MIME type of the image being uploaded. One of: image/jpeg, image/png, image/gif, image/webp."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]
    project_handle = params["project_handle"]
    content_type = params["content_type"]

    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :project_write, user, account),
         {:ok, project} <- fetch_project(account, project_handle),
         {:ok, ext} <- extension_for(content_type),
         key = staging_key(account, project, ext),
         {:ok, url} <-
           Glossia.Storage.presigned_url(key, method: :put, expires_in: @expires_in) do
      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(%{
            upload_url: url,
            method: "PUT",
            key: key,
            content_type: content_type,
            max_size_bytes: @max_size_bytes,
            expires_in: @expires_in,
            instructions:
              "PUT the image bytes to upload_url with the Content-Type header set to content_type. " <>
                "Body must be at most max_size_bytes. Then call complete_project_logo_upload with the same key."
          })
        )

      {:reply, response, frame}
    else
      {:error, %Error{} = error} -> {:error, error, frame}
      {:error, :unsupported_content_type} -> {:error, unsupported_content_type_error(), frame}
      {:error, reason} -> {:error, Error.execution("Could not start upload: #{inspect(reason)}"), frame}
    end
  end

  defp fetch_project(account, project_handle) do
    case Projects.get_project(account, project_handle) do
      nil -> {:error, Error.execution("Project '#{project_handle}' not found")}
      project -> {:ok, project}
    end
  end

  defp extension_for("image/jpeg"), do: {:ok, "jpg"}
  defp extension_for("image/png"), do: {:ok, "png"}
  defp extension_for("image/gif"), do: {:ok, "gif"}
  defp extension_for("image/webp"), do: {:ok, "webp"}
  defp extension_for(_), do: {:error, :unsupported_content_type}

  defp staging_key(account, project, ext) do
    token =
      16
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    "pending-avatars/#{account.id}/projects/#{project.id}/#{token}.#{ext}"
  end

  defp unsupported_content_type_error do
    Error.execution(
      "Unsupported content_type. Allowed: #{Enum.join(@allowed_content_types, ", ")}"
    )
  end
end
