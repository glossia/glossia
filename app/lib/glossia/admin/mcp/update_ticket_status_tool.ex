defmodule Glossia.Admin.MCP.UpdateTicketStatusTool do
  @moduledoc "Update the status of a support ticket (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Support
  alias Hermes.Server.Response

  schema do
    field :id, :string, required: true, description: "The ticket ID."

    field :status, :string,
      required: true,
      description: "New status: open, in_progress, resolved, or implemented."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user} <- Auth.current_user(frame) do
      ticket = Support.get_ticket!(params["id"])
      status = params["status"]

      resolved_by =
        if status in ~w(resolved implemented), do: user, else: nil

      case Support.update_ticket_status(ticket, status, resolved_by) do
        {:ok, updated_ticket} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                id: updated_ticket.id,
                title: updated_ticket.title,
                status: updated_ticket.status,
                resolved_at: updated_ticket.resolved_at
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
