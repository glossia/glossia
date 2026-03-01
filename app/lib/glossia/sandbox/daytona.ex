defmodule Glossia.Sandbox.Daytona do
  @moduledoc """
  Daytona-based sandbox adapter for production.

  Implements the five primitive sandbox operations by delegating to
  `Glossia.Daytona`. Agent session orchestration lives in `Glossia.Sandbox`.
  """

  @behaviour Glossia.Sandbox

  require Logger

  @impl true
  def create(params) do
    daytona_params = %{
      language: Map.get(params, :language, "node"),
      ephemeral: Map.get(params, :ephemeral, true),
      auto_stop_interval: Map.get(params, :auto_stop_interval, 0),
      labels: Map.get(params, :labels, %{})
    }

    case Glossia.Daytona.create_sandbox(daytona_params) do
      {:ok, %{"id" => id}} ->
        Logger.info("Daytona sandbox created: #{id}")
        {:ok, id}

      {:error, _} = err ->
        err
    end
  end

  @impl true
  def execute(sandbox_id, command, _opts \\ []) do
    Glossia.Daytona.execute(sandbox_id, %{command: command})
  end

  @impl true
  def upload_file(sandbox_id, remote_path, content) do
    Glossia.Daytona.upload_file(sandbox_id, remote_path, content)
  end

  @impl true
  def download_file(sandbox_id, remote_path) do
    Glossia.Daytona.download_file(sandbox_id, remote_path)
  end

  @impl true
  def delete(sandbox_id) do
    case Glossia.Daytona.delete_sandbox(sandbox_id) do
      :ok ->
        Logger.info("Daytona sandbox deleted: #{sandbox_id}")
        :ok

      {:error, _} = err ->
        Logger.warning("Failed to delete Daytona sandbox #{sandbox_id}: #{inspect(err)}")
        err
    end
  end
end
