defmodule Glossia.Accounts.Repository do
  use Modulex

  defimplementation do
    # Modules
    alias Glossia.Accounts.Models.Account
    alias Glossia.Accounts.Models.Credentials
    alias Glossia.Accounts.Models.Organization
    alias Glossia.Accounts.Models.OrganizationUser
    alias Glossia.Accounts.Models.User
    alias Glossia.Accounts.Models.UserToken
    alias Glossia.Repo
    import Ecto.Query, only: [from: 2]

    @doc """
    Given a user, it returns the account associated to it.
    """
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

    def get_github_credentials(user) do
      query =
        from(c in Credentials,
          where: c.user_id == ^user.id,
          where: c.provider == ^:github
        )

      Repo.one(query)
    end
  end

  defbehaviour do
    alias Glossia.Accounts.Models.Credentials
    alias Glossia.Accounts.Models.User
    alias Glossia.Accounts.Models.Organization
    alias Glossia.Accounts.Models.OrganizationUser
    alias Glossia.Accounts.Models.Account

    @callback get_user_account(User.t()) :: Account.t() | nil
    @callback get_user_and_organization_accounts(User.t()) :: [Account.t()]
    @callback get_user_organizations(User.t()) :: [Organization.t()]
    @callback add_user_to_organization(User.t(), Organization.t()) ::
                OrganizationUser.t()
    @callback add_user_to_organization(User.t(), Organization.t(), OrganizationUser.role()) ::
                OrganizationUser.t()
    @callback get_github_credentials(User.t()) :: Credentials.t() | nil
  end
end
