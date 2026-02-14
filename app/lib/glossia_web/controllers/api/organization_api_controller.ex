defmodule GlossiaWeb.Api.OrganizationApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Auditing
  alias Glossia.Repo
  import Ecto.Query

  def index(conn, _params) do
    user = conn.assigns[:current_user]
    orgs = Accounts.list_user_organizations(user)

    json(conn, %{
      organizations:
        Enum.map(orgs, fn org ->
          org = Repo.preload(org, :account)
          %{handle: org.account.handle, name: org.name, visibility: org.account.visibility}
        end)
    })
  end

  def show(conn, %{"handle" => handle}) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :org_read, fn org ->
      json(conn, %{
        handle: org.account.handle,
        name: org.name,
        type: "organization",
        visibility: org.account.visibility
      })
    end)
  end

  def create(conn, params) do
    user = conn.assigns[:current_user]

    handle = params["handle"]
    name = params["name"] || handle

    case Accounts.create_organization(user, %{"handle" => handle, "name" => name}) do
      {:ok, %{account: account, organization: org}} ->
        conn
        |> put_status(:created)
        |> json(%{handle: account.handle, name: org.name, type: "organization"})

      {:error, :account, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})

      {:error, _step, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def update(conn, %{"handle" => handle} = params) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :org_write, fn org ->
      update_attrs =
        params
        |> Map.take(["name", "visibility"])

      case Accounts.update_organization(org, update_attrs) do
        {:ok, org} ->
          json(conn, %{
            handle: org.account.handle,
            name: org.name,
            type: "organization",
            visibility: org.account.visibility
          })

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    end)
  end

  def delete(conn, %{"handle" => handle}) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :org_delete, fn org ->
      case Accounts.delete_organization(org) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    end)
  end

  def list_members(conn, %{"handle" => handle}) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :members_read, fn org ->
      members = Accounts.list_members(org)

      json(conn, %{
        members:
          Enum.map(members, fn membership ->
            %{
              handle: membership.user.account.handle,
              email: membership.user.email,
              role: membership.role,
              joined_at: membership.inserted_at
            }
          end)
      })
    end)
  end

  def remove_member(conn, %{"handle" => handle, "user_handle" => user_handle}) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :members_write, fn org ->
      case Accounts.get_user_by_handle(user_handle) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "User '#{user_handle}' not found"})

        target_user ->
          if Accounts.sole_admin?(org, target_user) do
            conn
            |> put_status(:conflict)
            |> json(%{error: "Cannot remove the only admin of the organization"})
          else
            Accounts.remove_member(org, target_user)

            Auditing.record("member.removed", org.account, user,
              resource_type: "member",
              resource_id: to_string(target_user.id),
              summary: "Removed #{user_handle} from the organization"
            )

            send_resp(conn, :no_content, "")
          end
      end
    end)
  end

  def list_invitations(conn, %{"handle" => handle}) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :members_read, fn org ->
      invitations = Accounts.list_pending_invitations(org)

      json(conn, %{
        invitations:
          Enum.map(invitations, fn inv ->
            %{
              id: inv.id,
              email: inv.email,
              role: inv.role,
              status: inv.status,
              expires_at: inv.expires_at
            }
          end)
      })
    end)
  end

  def create_invitation(conn, %{"handle" => handle} = params) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :members_write, fn org ->
      case Accounts.create_invitation(org, user, params) do
        {:ok, invitation} ->
          Auditing.record("member.invited", org.account, user,
            resource_type: "invitation",
            resource_id: to_string(invitation.id),
            summary: "Invited #{invitation.email} as #{invitation.role}"
          )

          conn
          |> put_status(:created)
          |> json(%{
            id: invitation.id,
            email: invitation.email,
            role: invitation.role,
            status: invitation.status,
            expires_at: invitation.expires_at
          })

        {:error, :already_member} ->
          conn
          |> put_status(:conflict)
          |> json(%{error: "User is already a member of this organization"})

        {:error, :already_invited} ->
          conn
          |> put_status(:conflict)
          |> json(%{error: "A pending invitation already exists for this email"})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    end)
  end

  def revoke_invitation(conn, %{"handle" => handle, "invitation_id" => invitation_id}) do
    user = conn.assigns[:current_user]

    with_authorized_org(conn, user, handle, :members_write, fn org ->
      case Accounts.get_invitation(org, invitation_id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Invitation not found"})

        invitation ->
          case Accounts.revoke_invitation(invitation) do
            {:ok, _} ->
              send_resp(conn, :no_content, "")

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: format_changeset_errors(changeset)})
          end
      end
    end)
  end

  defp with_authorized_org(conn, user, handle, permission, fun) do
    case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Organization '#{handle}' not found"})

      account ->
        case Glossia.Policy.authorize(permission, user, account) do
          :ok ->
            org = Accounts.get_organization_for_account(account)
            fun.(org)

          {:error, :unauthorized} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "Not authorized"})
        end
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
