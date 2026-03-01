defmodule Glossia.Admin.MCP.CommentDiscussionTool do
  @moduledoc "Add a comment to a discussion (super admin only)."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Admin.MCP.DiscussionHelpers
  alias Glossia.Auditing
  alias Glossia.Discussions
  alias Hermes.Server.Response

  schema do
    field :id, :string, required: true, description: "The discussion ID to comment on."
    field :body, :string, required: true, description: "The comment body."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         {:ok, discussion} <- DiscussionHelpers.fetch_discussion(params["id"]) do
      case Discussions.add_comment(discussion, user, %{body: params["body"]}) do
        {:ok, comment} ->
          Auditing.record("discussion.commented", discussion.account, user,
            resource_type: "discussion",
            resource_id: to_string(discussion.id),
            resource_path: ~p"/admin/discussions/#{discussion.id}",
            summary: "Commented on discussion \"#{discussion.title}\""
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                success: true,
                comment_id: comment.id,
                discussion_id: discussion.id
              })
            )

          {:reply, response, frame}

        {:error, changeset} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                success: false,
                errors: DiscussionHelpers.changeset_errors(changeset)
              })
            )

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
