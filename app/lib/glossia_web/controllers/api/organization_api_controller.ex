defmodule GlossiaWeb.Api.OrganizationApiController do
  use GlossiaWeb, :controller

  alias Glossia.ChangesetErrors
  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Auditing
  alias Glossia.Organizations
  alias GlossiaWeb.ApiAuthorization
  alias Glossia.Repo

  def index(conn, _params) do
    case ApiAuthorization.authorize(conn, :organization_read) do
      {:ok, conn} ->
        user = conn.assigns[:current_user]
        orgs = Organizations.list_user_organizations(user)

        json(conn, %{
          organizations:
            Enum.map(orgs, fn org ->
              org = Repo.preload(org, :account)
              %{handle: org.account.handle, name: org.name, visibility: org.account.visibility}
            end)
        })

      {:error, conn} ->
        conn
    end
  end

  def show(conn, %{"handle" => handle}) do
    with_authorized_org(conn, handle, :organization_read, fn conn, org ->
      json(conn, %{
        handle: org.account.handle,
        name: org.name,
        type: "organization",
        visibility: org.account.visibility
      })
    end)
  end

  def create(conn, params) do
    case ApiAuthorization.authorize(conn, :organization_write) do
      {:ok, conn} ->
        user = conn.assigns[:current_user]

        handle = params["handle"]
        name = params["name"] || handle

        case Organizations.create_organization(user, %{"handle" => handle, "name" => name}) do
          {:ok, %{account: account, organization: org}} ->
            Auditing.record("organization.created", account, user,
              resource_type: "organization",
              resource_id: to_string(org.id),
              resource_path: ~p"/#{account.handle}",
              summary: "Created organization \"#{account.handle}\""
            )

            conn
            |> put_status(:created)
            |> json(%{handle: account.handle, name: org.name, type: "organization"})

          {:error, :account, changeset, _} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: ChangesetErrors.to_map(changeset)})

          {:error, _step, changeset, _} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: ChangesetErrors.to_map(changeset)})
        end

      {:error, conn} ->
        conn
    end
  end

  def update(conn, %{"handle" => handle} = params) do
    with_authorized_org(conn, handle, :organization_write, fn conn, org ->
      update_attrs =
        params
        |> Map.take(["name", "visibility"])

      case Organizations.update_organization(org, update_attrs) do
        {:ok, org} ->
          user = conn.assigns[:current_user]

          Auditing.record("organization.updated", org.account, user,
            resource_type: "organization",
            resource_id: to_string(org.id),
            resource_path: ~p"/#{org.account.handle}",
            summary: "Updated organization \"#{org.account.handle}\""
          )

          json(conn, %{
            handle: org.account.handle,
            name: org.name,
            type: "organization",
            visibility: org.account.visibility
          })

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: ChangesetErrors.to_map(changeset)})
      end
    end)
  end

  def delete(conn, %{"handle" => handle}) do
    with_authorized_org(conn, handle, :organization_delete, fn conn, org ->
      case Organizations.delete_organization(org) do
        {:ok, _} ->
          user = conn.assigns[:current_user]

          Auditing.record("organization.deleted", org.account, user,
            resource_type: "organization",
            resource_id: to_string(org.id),
            resource_path: ~p"/#{org.account.handle}",
            summary: "Deleted organization \"#{org.account.handle}\""
          )

          send_resp(conn, :no_content, "")

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: ChangesetErrors.to_map(changeset)})
      end
    end)
  end

  def list_members(conn, %{"handle" => handle}) do
    with_authorized_org(conn, handle, :members_read, fn conn, org ->
      members = Organizations.list_members(org)

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

    with_authorized_org(conn, handle, :members_write, fn conn, org ->
      case Accounts.get_user_by_handle(user_handle) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "User '#{user_handle}' not found"})

        target_user ->
          if Organizations.sole_admin?(org, target_user) do
            conn
            |> put_status(:conflict)
            |> json(%{error: "Cannot remove the only admin of the organization"})
          else
            Organizations.remove_member(org, target_user)

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
    with_authorized_org(conn, handle, :members_read, fn conn, org ->
      invitations = Organizations.list_pending_invitations(org)

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

    with_authorized_org(conn, handle, :members_write, fn conn, org ->
      case Organizations.create_invitation(org, user, params) do
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
          |> json(%{errors: ChangesetErrors.to_map(changeset)})
      end
    end)
  end

  def revoke_invitation(conn, %{"handle" => handle, "invitation_id" => invitation_id}) do
    with_authorized_org(conn, handle, :members_write, fn conn, org ->
      user = conn.assigns[:current_user]

      case Organizations.get_invitation(org, invitation_id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Invitation not found"})

        invitation ->
          case Organizations.revoke_invitation(invitation) do
            {:ok, _} ->
              Auditing.record("member.invitation_revoked", org.account, user,
                resource_type: "invitation",
                resource_id: to_string(invitation.id),
                summary: "Revoked invitation for #{invitation.email}"
              )

              send_resp(conn, :no_content, "")

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: ChangesetErrors.to_map(changeset)})
          end
      end
    end)
  end

  defp with_authorized_org(conn, handle, permission, fun) do
    case Accounts.get_account_by_handle(handle) do
      %Account{type: "organization"} = account ->
        case ApiAuthorization.authorize(conn, permission, account) do
          {:ok, conn} ->
            org = Organizations.get_organization_for_account(account)
            fun.(conn, org)

          {:error, conn} ->
            conn
        end

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Organization '#{handle}' not found"})
    end
  end
end
