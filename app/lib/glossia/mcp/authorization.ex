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
    with :ok <- rate_limit(frame, action, object),
         :ok <- Glossia.Authz.authorize(action, user, object, scopes: scopes(frame)) do
      :ok
    else
      {:error, :rate_limited, retry_after_ms} ->
        retry_after = ceil(retry_after_ms / 1_000)
        {:error, Error.execution("Rate limit exceeded. Retry in #{retry_after}s.")}

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

  defp rate_limit(frame, action, object) do
    {key_prefix, limit} = action_limit(action)
    actor_key = actor_key(frame)
    account_suffix = account_suffix(object)
    key = "#{key_prefix}:#{actor_key}#{account_suffix}"

    case Glossia.RateLimiter.hit(key, :timer.minutes(1), limit) do
      {:allow, _count} -> :ok
      {:deny, retry_after_ms} -> {:error, :rate_limited, retry_after_ms}
    end
  end

  defp action_limit(action) when is_atom(action) do
    scope = Glossia.Authz.required_scope!(action)

    cond do
      String.ends_with?(scope, ":read") -> {"mcp_tool_read", 120}
      String.ends_with?(scope, ":admin") -> {"mcp_tool_admin", 15}
      String.ends_with?(scope, ":delete") -> {"mcp_tool_write", 30}
      String.ends_with?(scope, ":write") -> {"mcp_tool_write", 30}
      true -> {"mcp_tool", 60}
    end
  end

  defp actor_key(frame) do
    case frame.assigns[:current_token] do
      %{id: id} when not is_nil(id) ->
        "token:#{id}"

      _ ->
        case frame.assigns[:current_user] do
          %User{id: id} -> "user:#{id}"
          _ -> "anonymous"
        end
    end
  end

  defp account_suffix(%Account{id: id}), do: ":account:#{id}"
  defp account_suffix(%{account_id: id}) when not is_nil(id), do: ":account:#{id}"
  defp account_suffix(_), do: ""
end
