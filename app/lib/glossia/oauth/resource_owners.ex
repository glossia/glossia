defmodule Glossia.OAuth.ResourceOwners do
  @behaviour Boruta.Oauth.ResourceOwners

  alias Glossia.Accounts.User
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
  def authorized_scopes(_resource_owner) do
    # Keep this derived from `Glossia.Policy` so scope discovery (`/.well-known/*`),
    # OAuth consent, the REST API, and the MCP server cannot drift.
    Glossia.Policy.list_rules()
    |> Enum.map(fn rule -> to_scope("#{rule.object}:#{rule.action}") end)
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
