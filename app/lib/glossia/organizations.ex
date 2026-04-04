defmodule Glossia.Organizations do
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Accounts.{
    Account,
    Organization,
    OrganizationInvitation,
    OrganizationMembership,
    User
  }

  alias Glossia.Repo

  import Ecto.Query

  # Organization CRUD

  def create_organization(%User{} = user, attrs) do
    handle = attrs["handle"] || attrs[:handle]
    name = attrs["name"] || attrs[:name] || handle

    Tracer.with_span "glossia.organizations.create_organization" do
      Tracer.set_attributes([
        {"glossia.user.id", to_string(user.id)},
        {"glossia.organization.handle", if(is_binary(handle), do: handle, else: "")},
        {"glossia.organization.name", if(is_binary(name), do: name, else: "")}
      ])

      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :account,
        Account.changeset(%Account{}, %{handle: handle, type: "organization", has_access: true})
      )
      |> Ecto.Multi.insert(:organization, fn %{account: account} ->
        %Organization{account_id: account.id}
        |> Organization.changeset(%{name: name})
      end)
      |> Ecto.Multi.insert(:membership, fn %{organization: org} ->
        %OrganizationMembership{user_id: user.id, organization_id: org.id}
        |> OrganizationMembership.changeset(%{role: "admin"})
      end)
      |> Repo.transaction()
    end
  end

  def list_user_organizations(%User{id: user_id}) do
    OrganizationMembership
    |> where(user_id: ^user_id)
    |> preload(organization: :account)
    |> Repo.all()
    |> Enum.map(& &1.organization)
  end

  def get_organization_for_account(%Account{id: account_id, type: "organization"}) do
    Organization
    |> where(account_id: ^account_id)
    |> preload(:account)
    |> Repo.one()
  end

  def get_organization_for_account(_), do: nil

  def get_organization(id) do
    Organization
    |> preload(:account)
    |> Repo.get(id)
  end

  def update_organization(%Organization{} = org, attrs) do
    name = attrs["name"] || attrs[:name]
    visibility = attrs["visibility"] || attrs[:visibility]

    Tracer.with_span "glossia.organizations.update_organization" do
      Tracer.set_attributes([
        {"glossia.organization.id", to_string(org.id)},
        {"glossia.account.id", to_string(org.account_id)},
        {"glossia.organization.set_name", is_binary(name)},
        {"glossia.organization.set_visibility", is_binary(visibility)}
      ])

      org = Repo.preload(org, :account)

      Ecto.Multi.new()
      |> then(fn multi ->
        if name do
          Ecto.Multi.update(multi, :organization, Organization.changeset(org, %{name: name}))
        else
          Ecto.Multi.put(multi, :organization, org)
        end
      end)
      |> then(fn multi ->
        if visibility do
          Ecto.Multi.update(
            multi,
            :account,
            Account.changeset(org.account, %{visibility: visibility})
          )
        else
          Ecto.Multi.put(multi, :account, org.account)
        end
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{organization: organization, account: account}} ->
          {:ok, %{organization | account: account}}

        {:error, _step, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  def delete_organization(%Organization{} = org) do
    Tracer.with_span "glossia.organizations.delete_organization" do
      Tracer.set_attributes([
        {"glossia.organization.id", to_string(org.id)},
        {"glossia.account.id", to_string(org.account_id)}
      ])

      org = Repo.preload(org, :account)
      Repo.delete(org.account)
    end
  end

  # Organization membership management

  def add_member(%Organization{id: org_id}, %User{id: user_id}, role \\ "member") do
    Tracer.with_span "glossia.organizations.add_member" do
      Tracer.set_attributes([
        {"glossia.organization.id", to_string(org_id)},
        {"glossia.user.id", to_string(user_id)},
        {"glossia.member.role", to_string(role)}
      ])

      %OrganizationMembership{user_id: user_id, organization_id: org_id}
      |> OrganizationMembership.changeset(%{role: role})
      |> Repo.insert()
    end
  end

  def remove_member(%Organization{id: org_id}, %User{id: user_id}) do
    Tracer.with_span "glossia.organizations.remove_member" do
      Tracer.set_attributes([
        {"glossia.organization.id", to_string(org_id)},
        {"glossia.user.id", to_string(user_id)}
      ])

      OrganizationMembership
      |> where(organization_id: ^org_id, user_id: ^user_id)
      |> Repo.delete_all()
    end
  end

  def get_membership(%Organization{id: org_id}, %User{id: user_id}) do
    OrganizationMembership
    |> where(organization_id: ^org_id, user_id: ^user_id)
    |> Repo.one()
  end

  def update_member_role(%Organization{} = org, %User{} = target_user, new_role) do
    Tracer.with_span "glossia.organizations.update_member_role" do
      Tracer.set_attributes([
        {"glossia.organization.id", to_string(org.id)},
        {"glossia.user.id", to_string(target_user.id)},
        {"glossia.member.role", to_string(new_role)}
      ])

      case get_membership(org, target_user) do
        nil ->
          {:error, :not_a_member}

        membership ->
          membership
          |> OrganizationMembership.changeset(%{role: new_role})
          |> Repo.update()
      end
    end
  end

  def list_members(%Organization{id: org_id}) do
    OrganizationMembership
    |> where(organization_id: ^org_id)
    |> preload(user: :account)
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def sole_admin?(%Organization{id: org_id}, %User{id: user_id}) do
    admin_count =
      OrganizationMembership
      |> where(organization_id: ^org_id, role: "admin")
      |> Repo.aggregate(:count)

    is_admin =
      OrganizationMembership
      |> where(organization_id: ^org_id, user_id: ^user_id, role: "admin")
      |> Repo.exists?()

    is_admin and admin_count == 1
  end

  # Invitation management

  def list_pending_invitations(%Organization{id: org_id}) do
    now = DateTime.utc_now()

    OrganizationInvitation
    |> where(organization_id: ^org_id, status: "pending")
    |> where([i], i.expires_at > ^now)
    |> preload(:invited_by)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def create_invitation(%Organization{} = org, %User{} = invited_by, attrs) do
    email = attrs["email"] || attrs[:email]
    role = attrs["role"] || attrs[:role] || "member"

    Tracer.with_span "glossia.organizations.create_invitation" do
      Tracer.set_attributes([
        {"glossia.organization.id", to_string(org.id)},
        {"glossia.invited_by.id", to_string(invited_by.id)},
        {"glossia.invitation.role", to_string(role)}
      ])

      existing_user = User |> where(email: ^email) |> Repo.one()

      if existing_user && get_membership(org, existing_user) do
        {:error, :already_member}
      else
        now = DateTime.utc_now()

        pending =
          OrganizationInvitation
          |> where(organization_id: ^org.id, email: ^email, status: "pending")
          |> where([i], i.expires_at > ^now)
          |> Repo.exists?()

        if pending do
          {:error, :already_invited}
        else
          token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
          expires_at = DateTime.add(now, 7, :day)

          result =
            %OrganizationInvitation{
              organization_id: org.id,
              invited_by_id: invited_by.id,
              token: token
            }
            |> OrganizationInvitation.changeset(%{
              email: email,
              role: role,
              expires_at: expires_at
            })
            |> Repo.insert()

          case result do
            {:ok, invitation} ->
              org = Repo.preload(org, :account)
              org_name = org.account.handle

              Glossia.Emails.invitation_email(invitation, org_name)
              |> Glossia.Mailer.deliver()

              {:ok, invitation}

            error ->
              error
          end
        end
      end
    end
  end

  def get_invitation_by_token(token) when is_binary(token) do
    OrganizationInvitation
    |> where(token: ^token)
    |> preload(organization: :account)
    |> Repo.one()
  end

  def get_invitation(%Organization{id: org_id}, invitation_id) do
    with {:ok, id} <- cast_id(invitation_id) do
      OrganizationInvitation
      |> where(id: ^id, organization_id: ^org_id)
      |> Repo.one()
    else
      :error -> nil
    end
  end

  def accept_invitation(%OrganizationInvitation{} = invitation, %User{} = user) do
    Tracer.with_span "glossia.organizations.accept_invitation" do
      Tracer.set_attributes([
        {"glossia.invitation.id", to_string(invitation.id)},
        {"glossia.organization.id", to_string(invitation.organization_id)},
        {"glossia.user.id", to_string(user.id)}
      ])

      cond do
        invitation.status != "pending" ->
          {:error, :already_accepted}

        DateTime.compare(DateTime.utc_now(), invitation.expires_at) == :gt ->
          {:error, :expired}

        true ->
          existing = get_membership_by_org_id(invitation.organization_id, user.id)

          if existing do
            {:error, :already_member}
          else
            Ecto.Multi.new()
            |> Ecto.Multi.update(
              :invitation,
              OrganizationInvitation.changeset(invitation, %{status: "accepted"})
            )
            |> Ecto.Multi.insert(:membership, %OrganizationMembership{
              user_id: user.id,
              organization_id: invitation.organization_id,
              role: invitation.role
            })
            |> Repo.transaction()
          end
      end
    end
  end

  def decline_invitation(%OrganizationInvitation{} = invitation) do
    Tracer.with_span "glossia.organizations.decline_invitation" do
      Tracer.set_attributes([
        {"glossia.invitation.id", to_string(invitation.id)},
        {"glossia.organization.id", to_string(invitation.organization_id)}
      ])

      invitation
      |> OrganizationInvitation.changeset(%{status: "declined"})
      |> Repo.update()
    end
  end

  def revoke_invitation(%OrganizationInvitation{} = invitation) do
    Tracer.with_span "glossia.organizations.revoke_invitation" do
      Tracer.set_attributes([
        {"glossia.invitation.id", to_string(invitation.id)},
        {"glossia.organization.id", to_string(invitation.organization_id)}
      ])

      invitation
      |> OrganizationInvitation.changeset(%{status: "revoked"})
      |> Repo.update()
    end
  end

  defp get_membership_by_org_id(organization_id, user_id) do
    OrganizationMembership
    |> where(organization_id: ^organization_id, user_id: ^user_id)
    |> Repo.one()
  end

  defp cast_id(id) when is_binary(id) do
    case Uniq.UUID.parse(id) do
      {:ok, _info} -> {:ok, id}
      {:error, _} -> :error
    end
  end

  defp cast_id(_), do: :error
end
