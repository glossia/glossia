defmodule Glossia.Docs.Content.Validator do
  @moduledoc """
  A module that provides utilities to validate the navigation and pages at compile time.
  The validations ensure the integrity of the content and the navigation.
  """

  use Modulex

  defimplementation do
    alias Glossia.Docs.Navigation.Item
    alias Glossia.Docs.Models.Page

    @spec validate(pages :: [Page.t()], navigation :: [Item.t()]) :: any
    def validate(pages, navigation) when is_list(pages) and is_list(navigation) do
      navigation_paths = navigation_paths(navigation)
      page_paths = pages |> Enum.map(& &1.slug)

      orphan_navigation_paths = navigation_paths -- page_paths
      orphan_pages = page_paths -- navigation_paths
      invalid = length(orphan_navigation_paths) != 0 || length(orphan_pages) != 0

      if invalid do
        error_message =
          if length(orphan_navigation_paths) != 0 do
            "The following navigation paths are not associated with any page: #{inspect(orphan_navigation_paths)}\n"
          else
            ""
          end

        error_message =
          if length(orphan_pages) != 0 do
            error_message <>
              "The following pages are not associated with any navigation path: #{inspect(orphan_pages)}\n"
          end

        raise error_message
      end

      # dbg(page_paths)
      # dbg(navigation_paths)
    end

    defp navigation_paths(navigation) when is_list(navigation) do
      navigation
      |> Enum.flat_map(fn %{path: path} = item ->
        paths = [path]

        if Map.has_key?(item, :children) do
          paths ++ navigation_paths(item.children)
        else
          paths
        end
      end)
    end
  end

  defbehaviour do
    alias Glossia.Docs.Navigation.Item
    alias Glossia.Docs.Models.Page

    @callback validate(pages :: [Page.t()], navigation :: [Item.t()]) :: any
  end
end
