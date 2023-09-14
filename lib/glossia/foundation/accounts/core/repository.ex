defmodule Glossia.Foundation.Accounts.Core.Repository do
  # Modules
  @behaviour __MODULE__.Behaviour
  alias Glossia.Foundation.Accounts.Core.Models.Organization
  alias Glossia.Foundation.Accounts.Core.Models.OrganizationUser
  alias Glossia.Foundation.Accounts.Core.Models.Account
  alias Glossia.Foundation.Accounts.Core.Models.User
  alias Glossia.Foundation.Database.Core.Repo
  import Ecto.Query, only: [from: 2]

  @doc """
  Given a user, it returns the account associated to it.
  """
  @spec get_user_account(User.t()) :: Account.t()
  def get_user_account(user) do
    query = from(a in Account, join: u in User, on: a.id == u.account_id, where: u.id == ^user.id)
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

  defmodule Behaviour do
    @callback get_user_account(User.t()) :: Account.t() | nil
    @callback get_user_and_organization_accounts(User.t()) :: [Account.t()]
    @callback get_user_organizations(User.t()) :: [Organization.t()]
    @callback add_user_to_organization(User.t(), Organization.t(), OrganizationUser.role()) ::
                OrganizationUser.t()
  end
end
