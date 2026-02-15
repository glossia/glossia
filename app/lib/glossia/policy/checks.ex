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
  Authorization for collection endpoints (no object).
  """
  def collection(_subject, nil), do: true
  def collection(_subject, _object), do: false

  @doc """
  Subject's account does not have access (used as a deny check for write actions).
  """
  def no_access(nil, _object), do: false

  def no_access(%User{account: %Account{has_access: has_access}}, _object)
      when is_boolean(has_access),
      do: not has_access

  def no_access(%User{account_id: account_id}, _object) do
    Account
    |> where(id: ^account_id)
    |> select([a], a.has_access)
    |> Repo.one() != true
  end

  def no_access(_, _object), do: false

  @doc """
  User is accessing their own user-account resources.
  The object must have an `account_id` or be an Account struct
  whose associated user matches the subject.
  """
  def self(%User{id: user_id}, %User{id: user_id}), do: true
  def self(%User{account_id: account_id}, %{account_id: account_id}), do: true
  def self(%User{account_id: account_id}, %Account{id: account_id}), do: true
  def self(_, _), do: false

  @doc """
  User owns the account that owns the resource.
  Works for resources that have an `account_id` field or are Account structs.
  The account must be a user-type account owned by the subject.
  """
  def account_owner(%User{account_id: account_id}, %Account{id: account_id, type: "user"}),
    do: true

  def account_owner(%User{account_id: account_id}, %{account_id: account_id}) do
    case get_account_type(account_id) do
      "user" -> true
      _ -> false
    end
  end

  def account_owner(_, _), do: false

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

  defp resolve_organization_id(%Account{id: account_id, type: "organization"}) do
    get_organization_id_for_account(account_id)
  end

  defp resolve_organization_id(%Account{}), do: nil
  defp resolve_organization_id(_), do: nil

  defp get_account_type(account_id) do
    Account
    |> where(id: ^account_id)
    |> select([a], a.type)
    |> Repo.one()
  end

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
