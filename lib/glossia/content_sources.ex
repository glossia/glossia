defmodule Glossia.ContentSources do
  @moduledoc false

  alias Glossia.ContentSources.GitHub

  @doc ~S"""
  Given a content source platform, it returns the module that represents it.
  """
  @spec content_source(platform :: atom()) :: module() | nil
  def content_source(platform) do
    content_sources()
    |> Enum.find(fn {content_source_platform, _} -> content_source_platform == platform end)
    |> case do
      {_, module} -> module
      nil -> nil
    end
  end

  defp content_sources() do
    [{:github, GitHub}]
  end
end
