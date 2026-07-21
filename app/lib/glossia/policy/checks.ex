defmodule Glossia.Policy.Checks do
  @moduledoc false

  alias Glossia.Accounts.{Account, OrganizationMembership, User}
  alias Glossia.Repo
  import Ecto.Query

  @doc """
  Subject is authenticated (non-nil user).
  """
  def authenticated(%User{}, _object), do: true
  def authenticated(_, _object), do: false

  @doc """
  Subject is a super admin.
  """
  def super_admin(%User{super_admin: true}, _object), do: true
  def super_admin(_, _object), do: false

  @doc """
  Authorization for collection endpoints (no object).
  """
  def collection(_subject, nil), do: true
  def collection(_subject, _object), do: false

  @doc """
  User is accessing their own user resource.
  """
  def self(%User{id: user_id}, %User{id: user_id}), do: true
  def self(_, _), do: false

  @doc """
  User has "admin" role in the org that owns the resource.
  """
  def organization_admin(nil, _object), do: false

  def organization_admin(%User{id: user_id}, object) do
    case resolve_organization_id(object) do
      nil -> false
      org_id -> has_membership?(user_id, org_id, "admin")
    end
  end

  @doc """
  User has any role (admin or member) in the org that owns the resource.
  """
  def organization_member(nil, _object), do: false

  def organization_member(%User{id: user_id}, object) do
    case resolve_organization_id(object) do
      nil -> false
      org_id -> has_membership?(user_id, org_id)
    end
  end

  defp resolve_organization_id(%{account_id: account_id}) do
    get_organization_id_for_account(account_id)
  end

  defp resolve_organization_id(%Account{id: account_id}) do
    get_organization_id_for_account(account_id)
  end

  defp resolve_organization_id(_), do: nil

  defp get_organization_id_for_account(account_id) do
    Glossia.Accounts.Organization
    |> where(account_id: ^account_id)
    |> select([o], o.id)
    |> Repo.one()
  end

  defp has_membership?(user_id, organization_id, role) do
    OrganizationMembership
    |> where(user_id: ^user_id, organization_id: ^organization_id, role: ^role)
    |> Repo.exists?()
  end

  defp has_membership?(user_id, organization_id) do
    OrganizationMembership
    |> where(user_id: ^user_id, organization_id: ^organization_id)
    |> Repo.exists?()
  end

  @doc """
  The account has public visibility. Any subject (including nil/anonymous) can read.
  """
  def public_account(_subject, %Account{visibility: "public"}), do: true
  def public_account(_, _), do: false
end
