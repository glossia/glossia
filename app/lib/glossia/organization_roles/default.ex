defmodule Glossia.OrganizationRoles.Default do
  @moduledoc false

  @behaviour Glossia.OrganizationRoles

  alias Glossia.Accounts.{OrganizationInvitation, OrganizationMembership}

  @default_role "member"

  @impl true
  def default_role, do: @default_role

  @impl true
  def valid_roles, do: [@default_role]

  @impl true
  def normalize_role(_role), do: @default_role

  @impl true
  def assign_membership_role(%OrganizationMembership{} = membership, _role) do
    {:ok, %{membership | role: @default_role}}
  end

  @impl true
  def assign_invitation_role(%OrganizationInvitation{} = invitation, _role) do
    {:ok, %{invitation | role: @default_role}}
  end

  @impl true
  def attach_membership_role(%OrganizationMembership{} = membership) do
    %{membership | role: membership.role || @default_role}
  end

  @impl true
  def attach_membership_roles(memberships), do: Enum.map(memberships, &attach_membership_role/1)

  @impl true
  def attach_invitation_role(%OrganizationInvitation{} = invitation) do
    %{invitation | role: invitation.role || @default_role}
  end

  @impl true
  def attach_invitation_roles(invitations), do: Enum.map(invitations, &attach_invitation_role/1)

  @impl true
  def membership_has_role?(%OrganizationMembership{}, role), do: role == @default_role

  @impl true
  def count_memberships_with_role(_organization_id, role),
    do: if(role == @default_role, do: 1, else: 0)
end
