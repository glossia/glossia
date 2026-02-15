defmodule Glossia.Admin.MCP.ReplyTicketTool do
  @moduledoc "Add a staff reply to a support ticket (super admin only)."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Auditing
  alias Glossia.Support
  alias Hermes.Server.Response

  schema do
    field :id, :string, required: true, description: "The ticket ID to reply to."
    field :body, :string, required: true, description: "The reply message body."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user} <- Auth.current_user(frame) do
      ticket = Support.get_ticket!(params["id"])

      case Support.add_message(ticket, user, %{body: params["body"]}, is_staff: true) do
        {:ok, message} ->
          Auditing.record("ticket.replied", ticket.account, user,
            resource_type: "ticket",
            resource_id: to_string(ticket.id),
            resource_path: ~p"/admin/tickets/#{ticket.id}",
            summary: "Replied to ticket \"#{ticket.title}\""
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                success: true,
                message_id: message.id,
                ticket_id: ticket.id
              })
            )

          {:reply, response, frame}

        {:error, changeset} ->
          errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)

          response =
            Response.tool()
            |> Response.text(JSON.encode!(%{success: false, errors: errors}))

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
