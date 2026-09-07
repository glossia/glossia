defmodule Glossia.Admin.MCP.GetDiscussionTool do
  @moduledoc "Get a single discussion with its comments (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Admin.MCP.DiscussionHelpers
  alias Hermes.Server.Response

  schema do
    field :id, :string, required: true, description: "The discussion ID."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _user} <- Auth.current_user(frame),
         {:ok, discussion} <- DiscussionHelpers.fetch_discussion(params["id"]) do
      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(%{
            id: discussion.id,
            number: discussion.number,
            title: discussion.title,
            body: discussion.body,
            kind: discussion.kind,
            status: discussion.status,
            metadata: discussion.metadata || %{},
            user_email: discussion.user.email,
            user_name: discussion.user.name,
            account_handle: discussion.account.handle,
            closed_at: discussion.closed_at,
            closed_by:
              if(discussion.closed_by,
                do: %{id: discussion.closed_by.id, name: discussion.closed_by.name},
                else: nil
              ),
            inserted_at: discussion.inserted_at,
            comments:
              Enum.map(discussion.comments, fn c ->
                %{
                  id: c.id,
                  body: c.body,
                  user_name: c.user.name,
                  user_email: c.user.email,
                  inserted_at: c.inserted_at
                }
              end)
          })
        )

      {:reply, response, frame}
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
