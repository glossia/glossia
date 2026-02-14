defmodule Glossia.MCP.InviteOrganizationMemberTool do
  @moduledoc "Invite a user to an organization by email."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :email, {:required, :string}, description: "Email address to invite."

    field :role, :string,
      description: "Role for the invitee (admin, member, linguist). Defaults to member."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]

      case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
        nil ->
          {:error, Error.execution("Organization '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:members_write, user, account) do
            :ok ->
              org = Accounts.get_organization_for_account(account)

              case Accounts.create_invitation(org, user, params) do
                {:ok, invitation} ->
                  response =
                    Response.tool()
                    |> Response.text(
                      Jason.encode!(%{
                        id: invitation.id,
                        email: invitation.email,
                        role: invitation.role,
                        status: invitation.status,
                        expires_at: invitation.expires_at
                      })
                    )

                  {:reply, response, frame}

                {:error, :already_member} ->
                  {:error, Error.execution("User is already a member of this organization"),
                   frame}

                {:error, :already_invited} ->
                  {:error, Error.execution("A pending invitation already exists for this email"),
                   frame}

                {:error, changeset} ->
                  errors = format_errors(changeset)
                  {:error, Error.execution("Invitation failed: #{errors}"), frame}
              end

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to invite members to '#{handle}'"), frame}
          end
      end
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join(", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
  end
end
