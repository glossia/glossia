defmodule Glossia.Github.Installations do
  @moduledoc false

  alias Glossia.Accounts.GithubInstallation
  alias Glossia.Events
  alias Glossia.Repo

  import Ecto.Query

  def create_installation(account, attrs) do
    %GithubInstallation{}
    |> GithubInstallation.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:account, account)
    |> Repo.insert()
  end

  def get_installation_for_account(account_id) do
    from(i in GithubInstallation,
      where: i.account_id == ^account_id,
      order_by: [desc: i.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def list_installations_for_account(account_id) do
    from(i in GithubInstallation, where: i.account_id == ^account_id)
    |> Repo.all()
  end

  @doc """
  Returns all GitHub installations accessible to a user across all their accounts
  (personal account + organization memberships). This enables Vercel-like repo
  discovery where users see repos from all their GitHub orgs regardless of which
  Glossia account they are creating a project in.
  """
  def list_installations_for_user(user) do
    user_account_id = user.account_id

    org_account_ids =
      from(m in Glossia.Accounts.OrganizationMembership,
        where: m.user_id == ^user.id,
        join: o in Glossia.Accounts.Organization,
        on: o.id == m.organization_id,
        select: o.account_id
      )

    from(i in GithubInstallation,
      where: i.account_id == ^user_account_id or i.account_id in subquery(org_account_ids),
      where: is_nil(i.suspended_at)
    )
    |> Repo.all()
  end

  def get_installation_by_github_id(github_installation_id) do
    Repo.get_by(GithubInstallation, github_installation_id: github_installation_id)
  end

  def delete_installation(%GithubInstallation{} = installation, opts \\ []) do
    Repo.delete(installation)
    |> case do
      {:ok, deleted} = ok ->
        if actor = Keyword.get(opts, :actor) do
          account = Repo.preload(deleted, :account).account

          Events.emit("github_installation.deleted", account, actor,
            resource_type: "github_installation",
            resource_id: to_string(deleted.id),
            summary: "Disconnected GitHub account #{deleted.github_account_login}",
            via: Keyword.get(opts, :via)
          )
        end

        ok

      other ->
        other
    end
  end

  def delete_installation_by_github_id(github_installation_id) do
    case get_installation_by_github_id(github_installation_id) do
      nil -> {:error, :not_found}
      installation -> Repo.delete(installation)
    end
  end

  def suspend_installation(installation) do
    installation
    |> Ecto.Changeset.change(suspended_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  def unsuspend_installation(installation) do
    installation
    |> Ecto.Changeset.change(suspended_at: nil)
    |> Repo.update()
  end
end
