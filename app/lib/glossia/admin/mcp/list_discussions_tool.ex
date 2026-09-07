defmodule Glossia.Admin.MCP.ListDiscussionsTool do
  @moduledoc "List all discussions in the system (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Discussions
  alias Hermes.Server.Response

  schema do
    field :page, :integer, description: "Page number (1-based). Defaults to 1."
    field :page_size, :integer, description: "Items per page (max 100). Defaults to 50."

    field :status, :string, description: "Optional filter by status: open or closed."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _user} <- Auth.current_user(frame) do
      page = Map.get(params, "page", 1)
      page_size = min(Map.get(params, "page_size", 50), 100)

      flop_params = %{
        page: page,
        page_size: page_size
      }

      flop_params =
        case Map.get(params, "status") do
          nil ->
            flop_params

          status ->
            Map.put(flop_params, :filters, [%{field: :status, op: :==, value: status}])
        end

      case Discussions.list_all_discussions(flop_params) do
        {:ok, {discussions, meta}} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                discussions:
                  Enum.map(discussions, fn discussion ->
                    %{
                      id: discussion.id,
                      number: discussion.number,
                      title: discussion.title,
                      kind: discussion.kind,
                      status: discussion.status,
                      user_email: discussion.user.email,
                      user_name: discussion.user.name,
                      account_handle: discussion.account.handle,
                      inserted_at: discussion.inserted_at
                    }
                  end),
                meta: %{
                  total_count: meta.total_count,
                  total_pages: meta.total_pages,
                  current_page: meta.current_page,
                  page_size: meta.page_size,
                  has_next_page?: meta.has_next_page?,
                  has_previous_page?: meta.has_previous_page?
                }
              })
            )

          {:reply, response, frame}

        {:error, _meta} ->
          response =
            Response.tool()
            |> Response.text(JSON.encode!(%{discussions: [], meta: %{}}))

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
