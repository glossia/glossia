defmodule Glossia.Accounts do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Glossia.Repo

  alias Glossia.Accounts.{
    Account,
    Credentials,
    Organization,
    OrganizationUser,
    User,
    UserToken
  }

  @type register_organization_attrs :: %{
          handle: String.t()
        }
  @spec register_organization(attrs :: register_organization_attrs()) ::
          {:ok, Organization.t()} | {:error, :account | :organization, Ecto.Changeset.t()}
  def register_organization(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:account, fn repo, _changes ->
      Account.changeset(%Account{}, attrs) |> repo.insert()
    end)
    |> Ecto.Multi.run(:organization, fn repo, %{account: account} ->
      Organization.create_organization_changeset(%{account_id: account.id})
      |> repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: organization, account: _}} -> {:ok, organization}
      {:error, entity, changeset, _} -> {:error, entity, changeset}
    end
  end

  @spec find_and_update_or_create_credential(attrs :: any()) :: {:ok, any()} | {:error, any()}
  def find_and_update_or_create_credential(attrs) do
    case Repo.get_by(Credentials, provider: attrs.provider, provider_id: attrs.provider_id) do
      # We create the credentials
      nil ->
        %Credentials{}
        |> Credentials.changeset(%{
          provider: attrs.provider,
          provider_id: attrs.provider_id,
          token: attrs.token,
          refresh_token: attrs.refresh_token,
          expires_at: attrs.expires_at |> DateTime.from_unix!(:second),
          refresh_token_expires_at: attrs.refresh_token_expires_at,
          user_id: attrs.user_id
        })
        |> Repo.insert()

      # We update the credentials to point to the user
      %Credentials{} = credential ->
        credential
        |> Credentials.changeset(%{
          user_id: attrs.user_id,
          token: attrs.token,
          refresh_token: attrs.refresh_token,
          expires_at: attrs.expires_at |> DateTime.from_unix!(:second),
          refresh_token_expires_at: attrs.refresh_token_expires_at
        })
        |> Repo.update()
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email) |> Repo.preload(:account)
  end

  def get_user_by_id(id) when is_binary(id) do
    Repo.get_by(User, id: id) |> Repo.preload(:account)
  end

  def register_user(attrs) do
    registration_changeset = %User{} |> User.registration_changeset(attrs)

    {email, existing_user} =
      case registration_changeset |> Ecto.Changeset.get_change(:email) do
        nil -> {nil, nil}
        email -> {email, Repo.get_by(User, email: email) |> Repo.preload(:account)}
      end

    registration_changeset =
      case {email, existing_user} do
        {nil, _} ->
          registration_changeset

        {email, nil} ->
          handle = email |> String.split("@") |> hd
          registration_changeset |> Ecto.Changeset.put_assoc(:account, %Account{handle: handle})

        _ ->
          registration_changeset
      end

    registration_changeset |> Repo.insert()
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query) |> Repo.preload(:account)
  end

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  It finds the account with the given handle.
  When not found, it returns nil.
  """
  @spec find_account_by_handle(any) :: Account.t() | nil
  def find_account_by_handle(handle) do
    Account.account_by_handle_query(handle) |> Repo.one()
  end

  @spec get_github_credentials(User.t()) :: Credentials.t() | nil
  def get_github_credentials(user) do
    query =
      from(c in Credentials,
        where: c.user_id == ^user.id,
        where: c.provider == ^:github
      )

    Repo.one(query)
  end

  @spec get_user_account(User.t()) :: Account.t()
  def get_user_account(user) do
    query =
      from(a in Account, join: u in User, on: a.id == u.account_id, where: u.id == ^user.id)

    # All users should have an account
    Repo.one!(query)
  end

  @spec get_user_and_organization_accounts(User.t()) :: [Account.t()]
  def get_user_and_organization_accounts(user) do
    user_account = get_user_account(user)

    user_organization_accounts =
      get_user_organizations(user) |> Repo.preload(:account) |> Enum.map(& &1.account)

    [user_account | user_organization_accounts]
  end

  @spec get_user_organizations(User.t()) :: [Organization.t()]
  def get_user_organizations(user) do
    query =
      from(o in Organization,
        join: ou in OrganizationUser,
        on: ou.organization_id == o.id,
        where: ou.user_id == ^user.id
      )

    Repo.all(query)
  end

  @spec add_user_to_organization(User.t(), Organization.t()) :: OrganizationUser.t()
  def add_user_to_organization(user, organization, role \\ :user) do
    query =
      from(ou in OrganizationUser,
        where: ou.user_id == ^user.id,
        where: ou.organization_id == ^organization.id
      )

    case Repo.one(query) do
      %OrganizationUser{} = organization_user ->
        organization_user

      nil ->
        changeset =
          OrganizationUser.changeset(%OrganizationUser{}, %{
            user_id: user.id,
            organization_id: organization.id,
            role: role
          })

        Repo.insert!(changeset)
    end
  end
end
