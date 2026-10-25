defmodule Glossia.Push.Deliver do
  @moduledoc "ID-only, expiry-aware delivery. At most five provider attempts, including snoozes."
  use Oban.Worker, queue: :push, max_attempts: 5
  alias Glossia.Push
  alias Glossia.Push.{APNs, FCM, Message}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) when attempt <= 5 do
    with {:ok, installation, destination, expires_at} <- Push.delivery_context(args),
         {:ok, data} <- Message.data(destination, installation.id) do
      # FCM credential exchange may take time. Recheck the exact source, current
      # scopes, membership, token and expiry AFTER it, immediately before I/O.
      authorized? = fn ->
        case Push.delivery_context(args) do
          {:ok, current, ^destination, _} ->
            current.token_digest == installation.token_digest and
              current.oauth_client_id == installation.oauth_client_id

          _ ->
            false
        end
      end

      opts = [
        expires_at: expires_at,
        notification_id: args["notification_id"],
        authorized?: authorized?
      ]

      result =
        case installation.platform do
          "ios" -> APNs.deliver(installation, Message.apns(data), opts)
          "android" -> FCM.deliver(installation, Message.fcm(data), opts)
        end

      result(result, installation, expires_at, attempt)
    else
      {:error, reason} -> {:cancel, reason}
    end
  end

  def perform(_), do: {:cancel, :attempts_exhausted}

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}), do: min(5 * Integer.pow(2, min(attempt, 7)), 600)

  defp result(:ok, _, _, _), do: :ok

  defp result({:invalid_token, opts}, installation, _, _) do
    Push.retire_invalidated(installation, opts)
    {:cancel, :token_invalidated}
  end

  defp result({:error, reason}, _, _, _), do: {:cancel, reason}
  defp result({:retry, _}, _, _, attempt) when attempt >= 5, do: {:cancel, :attempts_exhausted}

  defp result({:retry, seconds}, _, expires_at, attempt) do
    delay = max(seconds || backoff(%Oban.Job{attempt: attempt}), 1)

    if DateTime.compare(DateTime.add(DateTime.utc_now(), delay), expires_at) == :lt,
      do: {:snooze, delay},
      else: {:cancel, :expired}
  end
end
