defmodule Glossia.MCP.Authorization do
  @moduledoc false

  alias Glossia.Accounts
  alias Glossia.Accounts.{Account, User}
  alias Hermes.MCP.Error

  @spec current_user(Hermes.Server.Frame.t()) :: {:ok, %User{}} | {:error, Error.t()}
  def current_user(frame) do
    case frame.assigns[:current_user] do
      %User{} = user -> {:ok, user}
      _ -> {:error, Error.execution("Authentication required")}
    end
  end

  @spec scopes(Hermes.Server.Frame.t()) :: [String.t()]
  def scopes(frame) do
    case frame.assigns[:scopes] do
      scopes when is_list(scopes) -> scopes
      _ -> []
    end
  end

  @spec authorize(Hermes.Server.Frame.t(), Glossia.Policy.action(), any, any) ::
          :ok | {:error, Error.t()}
  def authorize(frame, action, user, object \\ nil) do
    case Glossia.Authz.authorize(action, user, object, scopes: scopes(frame)) do
      :ok ->
        :ok

      {:error, :insufficient_scope, required_scope} ->
        {:error, Error.execution("Insufficient scope (required: #{required_scope})")}

      {:error, :unauthorized} ->
        {:error, Error.execution("Not authorized")}
    end
  end

  @spec fetch_account(String.t()) :: {:ok, %Account{}} | {:error, Error.t()}
  def fetch_account(handle) when is_binary(handle) do
    case Accounts.get_account_by_handle(handle) do
      nil -> {:error, Error.execution("Account '#{handle}' not found")}
      %Account{} = account -> {:ok, account}
    end
  end

  @spec fetch_organization_account(String.t()) :: {:ok, %Account{}} | {:error, Error.t()}
  def fetch_organization_account(handle) when is_binary(handle) do
    case Accounts.get_account_by_handle(handle) do
      %Account{type: "organization"} = account -> {:ok, account}
      _ -> {:error, Error.execution("Organization '#{handle}' not found")}
    end
  end
end
