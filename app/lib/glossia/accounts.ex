defmodule Glossia.Accounts do
  alias Glossia.Repo
  alias Glossia.Accounts.{Account, Organization, OrganizationMembership, Project, User, Identity}
  import Ecto.Query

  def find_or_create_user_from_oauth(provider, %{user: user_info, token: token_info}) do
    provider_uid = to_string(user_info["sub"])

    case get_identity(provider, provider_uid) do
      nil -> create_user_from_oauth(provider, user_info, token_info)
      identity -> update_identity_tokens(identity, token_info)
    end
  end

  defp get_identity(provider, provider_uid) do
    Identity
    |> where(provider: ^to_string(provider), provider_uid: ^provider_uid)
    |> preload(user: :account)
    |> Repo.one()
  end

  defp create_user_from_oauth(provider, user_info, token_info) do
    handle =
      generate_handle(
        user_info["preferred_username"] || user_info["nickname"] || user_info["name"]
      )

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:account, Account.changeset(%Account{}, %{handle: handle, type: "user"}))
    |> Ecto.Multi.insert(:user, fn %{account: account} ->
      %User{account_id: account.id}
      |> User.changeset(%{
        email: user_info["email"],
        name: user_info["name"],
        avatar_url: user_info["picture"]
      })
    end)
    |> Ecto.Multi.insert(:identity, fn %{user: user} ->
      %Identity{user_id: user.id}
      |> Identity.changeset(%{
        provider: to_string(provider),
        provider_uid: to_string(user_info["sub"]),
        provider_token: token_info["access_token"],
        provider_refresh_token: token_info["refresh_token"]
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, account: account}} ->
        {:ok, %{user | account: account}}

      {:error, _step, changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp update_identity_tokens(identity, token_info) do
    identity
    |> Identity.changeset(%{
      provider_token: token_info["access_token"],
      provider_refresh_token: token_info["refresh_token"]
    })
    |> Repo.update()
    |> case do
      {:ok, _identity} -> {:ok, identity.user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def generate_handle(nil), do: generate_random_handle()

  def generate_handle(username) do
    base =
      username
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9-]/, "-")
      |> String.replace(~r/-+/, "-")
      |> String.trim("-")
      |> String.slice(0, 35)

    if base == "" do
      generate_random_handle()
    else
      ensure_unique_handle(base)
    end
  end

  defp ensure_unique_handle(base) do
    if Repo.exists?(from a in Account, where: a.handle == ^base) do
      suffix =
        :crypto.strong_rand_bytes(3) |> Base.url_encode64(padding: false) |> String.downcase()

      ensure_unique_handle("#{String.slice(base, 0, 31)}-#{suffix}")
    else
      base
    end
  end

  defp generate_random_handle do
    suffix =
      :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false) |> String.downcase()

    "user-#{suffix}"
  end

  def get_user(id) do
    User
    |> preload(:account)
    |> Repo.get(id)
  end

  # Access management

  def grant_access(email) when is_binary(email) do
    case User |> where(email: ^email) |> preload(:account) |> Repo.one() do
      nil -> {:error, :not_found}

      user ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(:user, User.changeset(user, %{has_access: true}))
        |> Ecto.Multi.update(:account, Account.changeset(user.account, %{has_access: true}))
        |> Repo.transaction()
        |> case do
          {:ok, %{user: user}} -> {:ok, user}
          {:error, _step, changeset, _changes} -> {:error, changeset}
        end
    end
  end

  def revoke_access(email) when is_binary(email) do
    case User |> where(email: ^email) |> preload(:account) |> Repo.one() do
      nil -> {:error, :not_found}

      user ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(:user, User.changeset(user, %{has_access: false}))
        |> Ecto.Multi.update(:account, Account.changeset(user.account, %{has_access: false}))
        |> Repo.transaction()
        |> case do
          {:ok, %{user: user}} -> {:ok, user}
          {:error, _step, changeset, _changes} -> {:error, changeset}
        end
    end
  end

  # Organization CRUD

  def create_organization(%User{} = user, attrs) do
    handle = attrs["handle"] || attrs[:handle]
    name = attrs["name"] || attrs[:name] || handle

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

  def list_user_organizations(%User{id: user_id}) do
    OrganizationMembership
    |> where(user_id: ^user_id)
    |> preload(organization: :account)
    |> Repo.all()
    |> Enum.map(& &1.organization)
  end

  def list_user_accounts(%User{} = user) do
    org_accounts =
      list_user_organizations(user)
      |> Enum.map(& &1.account)

    [user.account | org_accounts]
  end

  # Organization membership management

  def add_member(%Organization{id: org_id}, %User{id: user_id}, role \\ "member") do
    %OrganizationMembership{user_id: user_id, organization_id: org_id}
    |> OrganizationMembership.changeset(%{role: role})
    |> Repo.insert()
  end

  def remove_member(%Organization{id: org_id}, %User{id: user_id}) do
    OrganizationMembership
    |> where(organization_id: ^org_id, user_id: ^user_id)
    |> Repo.delete_all()
  end

  def get_membership(%Organization{id: org_id}, %User{id: user_id}) do
    OrganizationMembership
    |> where(organization_id: ^org_id, user_id: ^user_id)
    |> Repo.one()
  end

  # Project CRUD

  def create_project(%Account{id: account_id}, attrs) do
    %Project{account_id: account_id}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def get_project(%Account{id: account_id}, handle) do
    Project
    |> where(account_id: ^account_id, handle: ^handle)
    |> preload(:account)
    |> Repo.one()
  end
end
