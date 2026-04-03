defmodule Glossia.Auditing.DefaultSink do
  @moduledoc false

  @behaviour Glossia.Auditing.Sink

  require Logger

  @impl true
  def record(%{name: name, account: account, user: user, opts: opts}) do
    actor_handle = user_actor_handle(user)
    actor_email = user_actor_email(user)
    user_id = user_actor_id(user)

    Logger.info(fn ->
      JSON.encode!(%{
        type: "audit_event",
        name: name,
        account_id: to_string(account.id),
        user_id: if(user_id == "", do: nil, else: user_id),
        actor_handle: if(actor_handle == "", do: nil, else: actor_handle),
        actor_email: if(actor_email == "", do: nil, else: actor_email),
        resource_type: opts[:resource_type],
        resource_id: opts[:resource_id],
        resource_path: opts[:resource_path],
        summary: opts[:summary],
        duration_ms: opts[:duration_ms],
        metadata: opts[:metadata]
      })
    end)

    :ok
  end

  @impl true
  def list_events(_account_id, _opts \\ []), do: []

  defp user_actor_id(nil), do: ""
  defp user_actor_id(%{id: id}), do: to_string(id)

  defp user_actor_handle(nil), do: ""

  defp user_actor_handle(%{account: %{handle: handle}}) when is_binary(handle),
    do: handle

  defp user_actor_handle(_user), do: ""

  defp user_actor_email(nil), do: ""
  defp user_actor_email(%{email: email}) when is_binary(email), do: email
  defp user_actor_email(_user), do: ""
end
