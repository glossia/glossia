defmodule Glossia.Navigation do
  @moduledoc """
  Behaviour for optional navigation extensions.
  """

  @callback account_nav_sections([map()], map()) :: [map()]

  def account_nav_sections(sections, assigns) do
    Glossia.Extensions.navigation_extension().account_nav_sections(sections, assigns)
  end
end

defmodule Glossia.Navigation.Empty do
  @moduledoc false

  @behaviour Glossia.Navigation

  @impl true
  def account_nav_sections(sections, _assigns), do: sections
end
