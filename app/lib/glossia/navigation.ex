defmodule Glossia.Navigation do
  @moduledoc """
  Behaviour for optional navigation extensions.
  """

  @callback account_nav_sections([map()], map()) :: [map()]

  def account_nav_sections(sections, assigns) do
    case Glossia.Extensions.navigation_extension() do
      nil -> sections
      extension -> extension.account_nav_sections(sections, assigns)
    end
  end
end
