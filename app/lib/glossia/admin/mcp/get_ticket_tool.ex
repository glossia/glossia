defmodule Glossia.Admin.MCP.GetTicketTool do
  @moduledoc "Get a single support ticket with its messages (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Support
  alias Hermes.Server.Response

  schema do
    field :id, :string, required: true, description: "The ticket ID."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _user} <- Auth.current_user(frame) do
      ticket = Support.get_ticket!(params["id"])

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(%{
            id: ticket.id,
            title: ticket.title,
            description: ticket.description,
            type: ticket.type,
            status: ticket.status,
            user_email: ticket.user.email,
            user_name: ticket.user.name,
            account_handle: ticket.account.handle,
            resolved_at: ticket.resolved_at,
            resolved_by:
              if(ticket.resolved_by,
                do: %{id: ticket.resolved_by.id, name: ticket.resolved_by.name},
                else: nil
              ),
            inserted_at: ticket.inserted_at,
            messages:
              Enum.map(ticket.messages, fn m ->
                %{
                  id: m.id,
                  body: m.body,
                  is_staff: m.is_staff,
                  user_name: m.user.name,
                  user_email: m.user.email,
                  inserted_at: m.inserted_at
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
