defmodule Glossia.Foundation.ContentSources do
  use Boundary, deps: [Glossia.Foundation.Utilities], exports: [ContentSource, GitHub]

  # Modules
  alias Glossia.Foundation.Utilities
  alias Glossia.Foundation.ContentSources.ContentSource
  alias Glossia.Foundation.ContentSources.GitHub

  @doc """
  It returns all the content sources available at runtime.
  """
  @spec content_source(id :: atom()) :: ContentSource.t() | nil
  def content_source(id) do
    [{:github, GitHub}]
    |> Enum.filter(fn {_, module} -> Utilities.module_compiled?(module) end)
    |> Enum.find(fn {content_source_id, _} -> content_source_id == id end)
    |> case do
      {_, module} -> module
      nil -> nil
    end
  end
end
