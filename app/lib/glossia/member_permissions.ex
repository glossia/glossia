defmodule Glossia.MemberPermissions do
  @moduledoc "Organization member permissions grouped by product area."
  import Ecto.Query
  alias Glossia.Accounts.{Account, Organization, OrganizationMembership, User}
  alias Glossia.Repo

  @domains ~w(account organization project voice members glossary discussion ticket llm_model translation analytics toki api_credentials)

  def available_scopes do
    Glossia.Authz.available_scopes()
    |> Enum.filter(fn scope -> hd(String.split(scope, ":")) in @domains end)
    |> Enum.reject(
      &(&1 in ~w(organization:admin organization:claim organization:delete members:write api_credentials:read api_credentials:write llm_model:write))
    )
  end

  def groups, do: Enum.group_by(available_scopes(), &hd(String.split(&1, ":"))) |> Enum.sort()

  def basic_scopes,
    do:
      ~w(account:read organization:read project:read voice:read glossary:read discussion:read ticket:read translation:read analytics:read toki:read toki:write)

  def decision(action, user, object, opts \\ [])

  def decision(action, %User{} = user, object, opts) do
    if Glossia.Roles.super_admin?(user) do
      :legacy
    else
      scoped_decision(action, user, object, opts)
    end
  end

  def decision(_, _, _, _), do: :legacy

  defp scoped_decision(action, user, object, opts) do
    context =
      case Keyword.fetch(opts, :membership_context) do
        {:ok, context} -> context
        :error -> organization_id(object)
      end

    case context do
      nil ->
        :legacy

      organization_id ->
        membership =
          case organization_id do
            {:membership, membership} -> membership
            id -> Repo.get_by(OrganizationMembership, organization_id: id, user_id: user.id)
          end

        case membership do
          %OrganizationMembership{role: "admin"} ->
            :legacy

          %OrganizationMembership{scopes: scopes} when is_list(scopes) ->
            if Glossia.Authz.required_scope(action) in scopes and
                 Glossia.Authz.required_scope(action) in available_scopes(),
               do: :allow,
               else: :deny

          _ ->
            :legacy
        end
    end
  end

  def context(user, object) do
    id = organization_id(object)

    membership =
      if user && id,
        do: Repo.get_by(OrganizationMembership, organization_id: id, user_id: user.id)

    if id, do: {:membership, membership}, else: nil
  end

  def update(organization, actor, target, scopes) do
    cond do
      not Glossia.Roles.has_organization_role?(actor, organization, "admin") ->
        {:error, :unauthorized}

      not is_list(scopes) or Enum.any?(scopes, &(&1 not in available_scopes())) ->
        {:error, :invalid_scopes}

      true ->
        case Repo.get_by(OrganizationMembership,
               organization_id: organization.id,
               user_id: target.id
             ) do
          nil ->
            {:error, :not_a_member}

          %OrganizationMembership{role: "admin"} ->
            {:error, :administrator}

          membership ->
            membership
            |> OrganizationMembership.changeset(%{scopes: Enum.uniq(scopes)})
            |> Repo.update()
            |> case do
              {:ok, updated} ->
                organization = Repo.preload(organization, :account)

                Glossia.Events.emit("member.permissions_updated", organization.account, actor,
                  resource_type: "member",
                  resource_id: target.id,
                  summary: "Updated organization member permissions"
                )

                {:ok, updated}

              error ->
                error
            end
        end
    end
  end

  defp organization_id(%Organization{id: id}), do: id
  defp organization_id(%Account{id: id}), do: account_organization_id(id)
  defp organization_id(%User{}), do: nil
  defp organization_id(%{organization_id: id}), do: id

  defp organization_id(%{project_id: id}) do
    Repo.one(
      from p in Glossia.Accounts.Project,
        join: o in Organization,
        on: o.account_id == p.account_id,
        where: p.id == ^id,
        select: o.id
    )
  end

  defp organization_id(%{account_id: id}), do: account_organization_id(id)
  defp organization_id(_), do: nil

  defp account_organization_id(id),
    do: Repo.one(from o in Organization, where: o.account_id == ^id, select: o.id)
end
