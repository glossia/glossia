defmodule Glossia.Admin.MCP.ListTicketsTool do
  @moduledoc "List all support tickets in the system (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Support
  alias Hermes.Server.Response

  schema do
    field :page, :integer, description: "Page number (1-based). Defaults to 1."
    field :page_size, :integer, description: "Items per page (max 100). Defaults to 50."

    field :status, :string,
      description: "Optional filter by status: open, in_progress, resolved, or implemented."
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

      case Support.list_all_tickets(flop_params) do
        {:ok, {tickets, meta}} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                tickets:
                  Enum.map(tickets, fn t ->
                    %{
                      id: t.id,
                      title: t.title,
                      type: t.type,
                      status: t.status,
                      user_email: t.user.email,
                      user_name: t.user.name,
                      account_handle: t.account.handle,
                      inserted_at: t.inserted_at
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
            |> Response.text(JSON.encode!(%{tickets: [], meta: %{}}))

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
