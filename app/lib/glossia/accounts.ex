defmodule Glossia.Accounts do
  alias Glossia.Repo

  alias Glossia.Accounts.{
    Account,
    Identity,
    Organization,
    OrganizationMembership,
    User
  }

  import Ecto.Query

  # ----------------------------------------------------------------------------
  # Accounts
  # ----------------------------------------------------------------------------

  def get_account_by_handle(handle) when is_binary(handle) do
    Account
    |> where(handle: ^handle)
    |> Repo.one()
  end

  def list_user_accounts(%User{} = user, params \\ %{}) do
    user_account_id = user.account_id

    org_account_ids =
      OrganizationMembership
      |> where(user_id: ^user.id)
      |> join(:inner, [m], o in Organization, on: o.id == m.organization_id)
      |> select([_m, o], o.account_id)

    query =
      Account
      |> where([a], a.id == ^user_account_id or a.id in subquery(org_account_ids))

    Flop.validate_and_run(query, params, for: Account)
  end

  # ----------------------------------------------------------------------------
  # Users and identities
  # ----------------------------------------------------------------------------

  def get_user(id) do
    User
    |> preload(:account)
    |> Repo.get(id)
  end

  def get_user_by_handle(handle) when is_binary(handle) do
    Account
    |> where(handle: ^handle, type: "user")
    |> Repo.one()
    |> case do
      nil -> nil
      account -> User |> where(account_id: ^account.id) |> Repo.one()
    end
  end

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

  # ----------------------------------------------------------------------------
  # Handles
  # ----------------------------------------------------------------------------

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

  # ----------------------------------------------------------------------------
  # Access management
  # ----------------------------------------------------------------------------

  def grant_access(email) when is_binary(email) do
    case User |> where(email: ^email) |> preload(:account) |> Repo.one() do
      nil ->
        {:error, :not_found}

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
      nil ->
        {:error, :not_found}

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

  # ----------------------------------------------------------------------------
  # Super admin
  # ----------------------------------------------------------------------------

  def set_super_admin(user_id, value \\ true) when is_boolean(value) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> Ecto.Changeset.change(super_admin: value)
        |> Repo.update()
    end
  end

  def super_admin?(%User{super_admin: true}), do: true
  def super_admin?(_), do: false
end
