defmodule Glossia.OAuth.ResourceOwners do
  @behaviour Boruta.Oauth.ResourceOwners

  alias Glossia.Accounts.{OrganizationMembership, User}
  alias Glossia.Repo
  import Ecto.Query

  @impl Boruta.Oauth.ResourceOwners
  def get_by(username: email) do
    case Repo.one(from u in User, where: u.email == ^email, preload: :account) do
      nil -> {:error, "User not found."}
      user -> {:ok, to_resource_owner(user)}
    end
  end

  def get_by(sub: sub) do
    case Repo.one(from u in User, where: u.id == ^sub, preload: :account) do
      nil -> {:error, "User not found."}
      user -> {:ok, to_resource_owner(user)}
    end
  end

  @impl Boruta.Oauth.ResourceOwners
  def check_password(_resource_owner, _password) do
    {:error, "Password authentication is not supported. Use OAuth login."}
  end

  @impl Boruta.Oauth.ResourceOwners
  def authorized_scopes(resource_owner) do
    # Scopes in the token represent the upper bound of what the client can
    # request on behalf of the user. Actual authorization is enforced at the
    # resource level via Glossia.Policy. Here we compute which scopes this
    # specific user could ever exercise, based on their account ownership
    # and org memberships.
    user_id = resource_owner.sub
    base_scopes = user_scopes()
    org_scopes = org_scopes_for_user(user_id)

    (base_scopes ++ org_scopes)
    |> Enum.uniq_by(& &1.name)
  end

  @impl Boruta.Oauth.ResourceOwners
  def claims(resource_owner, _scope) do
    %{
      "sub" => resource_owner.sub,
      "email" => resource_owner.extra_claims["email"],
      "name" => resource_owner.extra_claims["name"],
      "preferred_username" => resource_owner.extra_claims["handle"]
    }
  end

  # Every user can manage their own account and projects
  defp user_scopes do
    ~w(user:read user:write project:read project:write project:admin project:delete translations:read translations:write translations:admin glossary:read glossary:write glossary:admin)
    |> Enum.map(&to_scope/1)
  end

  # Org scopes depend on the user's highest role across all their orgs
  defp org_scopes_for_user(user_id) do
    roles =
      OrganizationMembership
      |> where(user_id: ^user_id)
      |> select([m], m.role)
      |> Repo.all()

    cond do
      "admin" in roles ->
        ~w(org:read org:write org:admin)
        |> Enum.map(&to_scope/1)

      "member" in roles ->
        ~w(org:read)
        |> Enum.map(&to_scope/1)

      true ->
        []
    end
  end

  defp to_scope(name), do: %Boruta.Oauth.Scope{name: name, label: name}

  defp to_resource_owner(%User{} = user) do
    %Boruta.Oauth.ResourceOwner{
      sub: user.id,
      username: user.email,
      extra_claims: %{
        "email" => user.email,
        "name" => user.name,
        "handle" => user.account.handle
      }
    }
  end
end
