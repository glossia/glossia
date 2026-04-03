defmodule Glossia.Admin.MCP.CloseDiscussionTool do
  @moduledoc "Close or reopen a discussion (super admin only)."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Admin.MCP.DiscussionHelpers
  alias Glossia.Events
  alias Glossia.Discussions
  alias Hermes.Server.Response

  schema do
    field :id, :string, required: true, description: "The discussion ID."

    field :action, :string,
      required: true,
      description: "Action to perform: close or reopen."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         {:ok, discussion} <- DiscussionHelpers.fetch_discussion(params["id"]) do
      action = params["action"]

      result =
        case action do
          "close" -> Discussions.close_discussion(discussion, user)
          "reopen" -> Discussions.reopen_discussion(discussion)
          _ -> {:error, :invalid_action}
        end

      case result do
        {:ok, updated_discussion} ->
          event_name = if action == "close", do: "discussion.closed", else: "discussion.reopened"
          summary = if action == "close", do: "Closed", else: "Reopened"

          Events.emit(event_name, discussion.account, user,
            resource_type: "discussion",
            resource_id: to_string(discussion.id),
            resource_path: ~p"/admin/discussions/#{discussion.id}",
            summary: "#{summary} discussion \"#{discussion.title}\""
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                id: updated_discussion.id,
                title: updated_discussion.title,
                status: updated_discussion.status,
                closed_at: updated_discussion.closed_at
              })
            )

          {:reply, response, frame}

        {:error, :invalid_action} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{success: false, error: "Invalid action. Use 'close' or 'reopen'."})
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
