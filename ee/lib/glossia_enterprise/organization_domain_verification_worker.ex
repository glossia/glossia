defmodule GlossiaEnterprise.OrganizationDomainVerificationWorker do
  @moduledoc "Renews organization domain ownership while the verification record remains present."
  use Oban.Worker, queue: :default, max_attempts: 3
  import Ecto.Query
  alias Glossia.Accounts.{Organization, OrganizationMembership, User}
  alias Glossia.Repo
  alias GlossiaEnterprise.OrganizationAuthentication

  def perform(%Oban.Job{args: %{"organization_id" => id}}) do
    renew(id)
  end

  def perform(%Oban.Job{}) do
    cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

    Repo.all(
      from o in Organization,
        where: not is_nil(o.auth_provider) and o.auth_domain_verified_at > ^cutoff,
        select: o.id
    )
    |> Enum.map(&new(%{"organization_id" => &1}))
    |> Oban.insert_all()

    :ok
  end

  def renew(id, resolver \\ &OrganizationAuthentication.lookup/1) do
    organization = Repo.get(Organization, id)

    admin =
      Repo.one(
        from u in User,
          join: m in OrganizationMembership,
          on: m.user_id == u.id,
          where: m.organization_id == ^id and m.role == "admin",
          limit: 1
      )

    if organization && admin && organization.auth_provider && organization.auth_domain_verified_at do
      case OrganizationAuthentication.verify(organization, admin, resolver, via: "scheduled") do
        {:ok, _} -> :ok
        {:error, :verification_failed} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
  end
end
