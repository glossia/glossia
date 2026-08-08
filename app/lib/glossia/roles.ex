defmodule Glossia.Roles do
  @moduledoc false

  import Ecto.Query

  alias Glossia.Accounts.{Organization, Role, User, UserRole}
  alias Glossia.Repo

  @instance_scope "instance"
  @organization_scope "organization"

  def super_admin?(%User{user_roles: user_roles} = user) do
    if user_roles_loaded?(user_roles) do
      Enum.any?(user_roles, &instance_super_admin?/1)
    else
      has_instance_role?(user, "super_admin")
    end
  end

  defp user_roles_loaded?(%Ecto.Association.NotLoaded{}), do: false

  defp user_roles_loaded?(user_roles) when is_list(user_roles),
    do: Enum.all?(user_roles, &Ecto.assoc_loaded?(&1.role))

  defp instance_super_admin?(%UserRole{
         organization_id: nil,
         role: %Role{scope: @instance_scope, name: "super_admin"}
       }),
       do: true

  defp instance_super_admin?(_), do: false

  def has_instance_role?(%User{id: user_id}, role_name) do
    UserRole
    |> join(:inner, [user_role], role in assoc(user_role, :role))
    |> where(
      [user_role, role],
      user_role.user_id == ^user_id and is_nil(user_role.organization_id) and
        role.scope == ^@instance_scope and role.name == ^role_name
    )
    |> Repo.exists?()
  end

  def has_organization_role?(%User{id: user_id}, organization, role_name) do
    organization_id = organization_id(organization)

    UserRole
    |> join(:inner, [user_role], role in assoc(user_role, :role))
    |> where(
      [user_role, role],
      user_role.user_id == ^user_id and user_role.organization_id == ^organization_id and
        role.scope == ^@organization_scope and role.name == ^role_name
    )
    |> Repo.exists?()
  end

  def organization_member?(%User{id: user_id}, organization) do
    organization_id = organization_id(organization)

    UserRole
    |> where(user_id: ^user_id, organization_id: ^organization_id)
    |> Repo.exists?()
  end

  def set_super_admin(%User{} = user, enabled?) when is_boolean(enabled?) do
    set_instance_role(user, "super_admin", enabled?)
  end

  def set_instance_role(%User{id: user_id}, role_name, true) do
    with %Role{} = role <- get_role(@instance_scope, role_name) do
      if Repo.exists?(
           from user_role in UserRole,
             where:
               user_role.user_id == ^user_id and user_role.role_id == ^role.id and
                 is_nil(user_role.organization_id)
         ) do
        :ok
      else
        %UserRole{user_id: user_id, role_id: role.id}
        |> UserRole.changeset(%{})
        |> Repo.insert()
        |> case do
          {:ok, _user_role} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
      end
    else
      nil -> {:error, :role_not_found}
    end
  end

  def set_instance_role(%User{id: user_id}, role_name, false) do
    case get_role(@instance_scope, role_name) do
      nil ->
        {:error, :role_not_found}

      role ->
        UserRole
        |> where(
          [user_role],
          user_role.user_id == ^user_id and user_role.role_id == ^role.id and
            is_nil(user_role.organization_id)
        )
        |> Repo.delete_all()

        :ok
    end
  end

  def replace_organization_role(%User{id: user_id}, organization, role_name) do
    organization_id = organization_id(organization)

    with %Role{} = role <- get_role(@organization_scope, role_name) do
      Repo.transaction(fn ->
        UserRole
        |> where(user_id: ^user_id, organization_id: ^organization_id)
        |> Repo.delete_all()

        %UserRole{user_id: user_id, organization_id: organization_id, role_id: role.id}
        |> UserRole.changeset(%{})
        |> Repo.insert!()
      end)
      |> case do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      nil -> {:error, :role_not_found}
    end
  end

  def remove_organization_roles(%User{id: user_id}, organization) do
    organization_id = organization_id(organization)

    UserRole
    |> where(user_id: ^user_id, organization_id: ^organization_id)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Returns the organizations a user is a member of, via their org-scoped
  user roles. A user with no org-scoped role is not a member of any
  organization and gets an empty list.
  """
  @spec list_user_organizations(%User{} | %User{id: Ecto.UUID.t()}) :: [%Organization{}]
  def list_user_organizations(%User{id: user_id}) do
    Organization
    |> join(:inner, [o], user_role in UserRole, on: user_role.organization_id == o.id)
    |> where([_o, user_role], user_role.user_id == ^user_id)
    |> order_by([o, _user_role], asc: o.name)
    |> Repo.all()
  end

  defp get_role(scope, name), do: Repo.get_by(Role, scope: scope, name: name)
  defp organization_id(%Organization{id: id}), do: id
  defp organization_id(id), do: id
end
