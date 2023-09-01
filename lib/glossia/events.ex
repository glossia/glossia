defmodule Glossia.Events do
  use Boundary,
    deps: [Glossia.Foundation.ContentSources.Core, Glossia.Repo, Glossia.Foundation.VirtualMachine.Core],
    exports: [Event]

  # Modules
  alias Glossia.Events.EventWorker
  require Logger

  @doc """
  It proces
  """
  @spec process_event(%{
          access_token: String.t(),
          content_source_access_token: String.t(),
          project_id: number(),
          type: atom(),
          version: String.t(),
          content_source_id: String.t(),
          content_source_platform: atom(),
          project_handle: String.t(),
          account_handle: String.t()
        }) ::
          {:ok, nil} | {:error, any()}
  def process_event(attrs) do
    attrs
    |> EventWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
