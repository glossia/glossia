defmodule Glossia.TranslationSessions.EngineRecoveryWorker do
  @moduledoc "Schedules bounded recovery on the latest healthy translation engine release."

  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [period: 240, states: [:available, :scheduled, :executing, :retryable]]

  require Logger

  alias Glossia.TranslationSessions.{EngineRecovery, EngineRelease}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case EngineRelease.ready_release() do
      {:ok, release} ->
        EngineRecovery.candidates(release)
        |> Enum.reduce_while(:ok, fn session, :ok ->
          case EngineRecovery.schedule(session, release) do
            {:ok, _continuation} -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      :not_ready ->
        :ok

      {:error, reason} ->
        Logger.warning("Translation engine recovery could not verify the deployed release")
        {:error, reason}
    end
  end
end
