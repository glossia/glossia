defmodule Glossia.Admin.MCP.Authorization do
  @moduledoc false

  alias Glossia.Accounts.User
  alias Hermes.MCP.Error

  @spec current_user(Hermes.Server.Frame.t()) :: {:ok, %User{}} | {:error, Error.t()}
  def current_user(frame) do
    case frame.assigns[:current_user] do
      %User{super_admin: true} = user ->
        case rate_limit(user.id) do
          :ok ->
            {:ok, user}

          {:error, retry_after_ms} ->
            retry_after = ceil(retry_after_ms / 1_000)
            {:error, Error.execution("Rate limit exceeded. Retry in #{retry_after}s.")}
        end

      %User{} ->
        {:error, Error.execution("Super admin access required")}

      _ ->
        {:error, Error.execution("Authentication required")}
    end
  end

  defp rate_limit(user_id) do
    key = "admin_mcp_tool:user:#{user_id}"

    case Glossia.RateLimiter.hit(key, :timer.minutes(1), 60) do
      {:allow, _count} -> :ok
      {:deny, retry_after_ms} -> {:error, retry_after_ms}
    end
  end
end
