defmodule Babel.OAuth.ResourceOwners do
  @moduledoc false

  @behaviour Boruta.Oauth.ResourceOwners

  alias Babel.Accounts
  alias Babel.Accounts.Account

  @operations_read_scope "operations:read"
  @operations_write_scope "operations:write"

  @impl Boruta.Oauth.ResourceOwners
  def get_by(username: email) when is_binary(email) do
    case Accounts.get_account_by_email(email) do
      nil -> {:error, "Account not found."}
      account -> {:ok, to_resource_owner(account)}
    end
  end

  def get_by(sub: sub) when is_binary(sub) do
    case Integer.parse(sub) do
      {id, ""} -> get_resource_owner(id)
      _ -> {:error, "Account not found."}
    end
  end

  @impl Boruta.Oauth.ResourceOwners
  def check_password(_resource_owner, _password) do
    {:error, "Password authentication is not supported. Use Pomerium authentication."}
  end

  @impl Boruta.Oauth.ResourceOwners
  def authorized_scopes(_resource_owner) do
    [
      %Boruta.Oauth.Scope{name: @operations_read_scope, label: "Read Babel operations"},
      %Boruta.Oauth.Scope{name: @operations_write_scope, label: "Manage Babel operations"}
    ]
  end

  @impl Boruta.Oauth.ResourceOwners
  def claims(resource_owner, _scope) do
    resource_owner.extra_claims
    |> Map.put("sub", resource_owner.sub)
  end

  defp get_resource_owner(id) do
    case Accounts.get_account(id) do
      nil -> {:error, "Account not found."}
      account -> {:ok, to_resource_owner(account)}
    end
  end

  defp to_resource_owner(%Account{} = account) do
    %Boruta.Oauth.ResourceOwner{
      sub: Integer.to_string(account.id),
      username: account.email,
      extra_claims: %{"email" => account.email, "name" => account.name}
    }
  end
end
