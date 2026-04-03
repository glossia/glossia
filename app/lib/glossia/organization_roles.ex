defmodule Glossia.OrganizationRoles do
  @moduledoc """
  Extension point for organization role persistence.

  OSS treats roles as optional metadata. Enterprise can persist and enforce them.
  """

  alias Glossia.Accounts.{OrganizationInvitation, OrganizationMembership}

  @callback default_role() :: String.t()
  @callback valid_roles() :: [String.t()]
  @callback normalize_role(term()) :: String.t()

  @callback assign_membership_role(OrganizationMembership.t(), String.t()) ::
              {:ok, OrganizationMembership.t()} | {:error, term()}

  @callback assign_invitation_role(OrganizationInvitation.t(), String.t()) ::
              {:ok, OrganizationInvitation.t()} | {:error, term()}

  @callback attach_membership_role(OrganizationMembership.t()) :: OrganizationMembership.t()
  @callback attach_membership_roles([OrganizationMembership.t()]) :: [OrganizationMembership.t()]

  @callback attach_invitation_role(OrganizationInvitation.t()) :: OrganizationInvitation.t()
  @callback attach_invitation_roles([OrganizationInvitation.t()]) :: [OrganizationInvitation.t()]

  @callback membership_has_role?(OrganizationMembership.t(), String.t()) :: boolean()
  @callback count_memberships_with_role(Ecto.UUID.t(), String.t()) :: non_neg_integer()
end
