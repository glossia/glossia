defmodule Glossia.Foundation.Builds.Core do
  # Modules
  alias Glossia.Foundation.Builds.Core.BuildWorker
  require Logger
  use Boundary,
  deps: [
    Glossia.Foundation.ContentSources.Core,
    Glossia.Foundation.Database.Core,
    Glossia.Foundation.VirtualMachine.Core
  ],
  exports: [Build]

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
