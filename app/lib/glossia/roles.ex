defmodule Glossia.Roles do
  @moduledoc false

  import Ecto.Query

  alias Glossia.Accounts.{Organization, Role, RoleAssignment, User}
  alias Glossia.Repo

  @instance_scope "instance"
  @organization_scope "organization"

  def super_admin?(%User{} = user), do: has_instance_role?(user, "super_admin")

  def has_instance_role?(%User{id: user_id}, role_name) do
    RoleAssignment
    |> join(:inner, [assignment], role in assoc(assignment, :role))
    |> where(
      [assignment, role],
      assignment.user_id == ^user_id and is_nil(assignment.organization_id) and
        role.scope == ^@instance_scope and role.name == ^role_name
    )
    |> Repo.exists?()
  end

  def has_organization_role?(%User{id: user_id}, organization, role_name) do
    organization_id = organization_id(organization)

    RoleAssignment
    |> join(:inner, [assignment], role in assoc(assignment, :role))
    |> where(
      [assignment, role],
      assignment.user_id == ^user_id and assignment.organization_id == ^organization_id and
        role.scope == ^@organization_scope and role.name == ^role_name
    )
    |> Repo.exists?()
  end

  def organization_member?(%User{id: user_id}, organization) do
    organization_id = organization_id(organization)

    RoleAssignment
    |> where(user_id: ^user_id, organization_id: ^organization_id)
    |> Repo.exists?()
  end

  def set_super_admin(%User{} = user, enabled?) when is_boolean(enabled?) do
    set_instance_role(user, "super_admin", enabled?)
  end

  def set_instance_role(%User{id: user_id}, role_name, true) do
    with %Role{} = role <- get_role(@instance_scope, role_name) do
      if Repo.exists?(
           from assignment in RoleAssignment,
             where:
               assignment.user_id == ^user_id and assignment.role_id == ^role.id and
                 is_nil(assignment.organization_id)
         ) do
        :ok
      else
        %RoleAssignment{user_id: user_id, role_id: role.id}
        |> RoleAssignment.changeset(%{})
        |> Repo.insert()
        |> case do
          {:ok, _assignment} -> :ok
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
        RoleAssignment
        |> where(
          [assignment],
          assignment.user_id == ^user_id and assignment.role_id == ^role.id and
            is_nil(assignment.organization_id)
        )
        |> Repo.delete_all()

        :ok
    end
  end

  def replace_organization_role(%User{id: user_id}, organization, role_name) do
    organization_id = organization_id(organization)

    with %Role{} = role <- get_role(@organization_scope, role_name) do
      Repo.transaction(fn ->
        RoleAssignment
        |> where(user_id: ^user_id, organization_id: ^organization_id)
        |> Repo.delete_all()

        %RoleAssignment{user_id: user_id, organization_id: organization_id, role_id: role.id}
        |> RoleAssignment.changeset(%{})
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

    RoleAssignment
    |> where(user_id: ^user_id, organization_id: ^organization_id)
    |> Repo.delete_all()

    :ok
  end

  defp get_role(scope, name), do: Repo.get_by(Role, scope: scope, name: name)
  defp organization_id(%Organization{id: id}), do: id
  defp organization_id(id), do: id
end
