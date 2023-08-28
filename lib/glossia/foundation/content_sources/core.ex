defmodule Glossia.Foundation.ContentSources.Core do
  # TODO: GitHub should not be exported directly
  use Boundary, deps: [Glossia.Foundation.Utilities], exports: [ContentSource, GitHub]

  # Modules
  alias Glossia.Foundation.Utilities
  alias Glossia.Foundation.ContentSources.Core.ContentSource
  alias Glossia.Foundation.ContentSources.Core.GitHub

  @doc """
  Given an atom representing the content source and its identifier, it returns a tuple
  with the content source module and an instance of it. If the content source can't be
  found, it returns `nil`.
  """
  @spec new(content_source :: atom(), id :: String.t()) :: {atom(), ContentSource.t()}
  def new(content_source_id, id) do
    case content_source(content_source_id) do
      nil -> raise "Content source #{content_source_id} not found"
      module -> {module, module.new(id)}
    end
  end

  # Private

  @spec content_source(id :: atom()) :: module() | nil
  defp content_source(id) do
    [{:github, GitHub}]
    |> Enum.filter(fn {_, module} -> Utilities.module_compiled?(module) end)
    |> Enum.find(fn {content_source_id, _} -> content_source_id == id end)
    |> case do
      {_, module} -> module
      nil -> nil
    end
  end
end
