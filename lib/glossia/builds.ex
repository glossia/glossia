defmodule Glossia.Builds do
  # Modules
  alias Glossia.Builds.BuildWorker
  require Logger

  def trigger_build(attrs) do
    attrs
    |> BuildWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
