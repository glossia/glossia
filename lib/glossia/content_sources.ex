defmodule Glossia.ContentSources do
  @moduledoc false

  alias Glossia.ContentSources.Platforms.GitHub

  @doc ~S"""
  Given the atom representing a content source platform,
  it returns the module that implements the content source platform.
  """
  @spec get_platform_module(platform :: atom()) :: module() | nil
  def get_platform_module(platform) do
    get_platform_modules()
    |> Enum.find(fn {platform_id, _} -> platform_id == platform end)
    |> case do
      {_, module} -> module
      nil -> nil
    end
  end

  defp get_platform_modules() do
    [{:github, GitHub}]
  end
end
