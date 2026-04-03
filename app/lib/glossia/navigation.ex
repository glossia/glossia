defmodule Glossia.Navigation do
  @moduledoc """
  Behaviour for optional navigation extensions.
  """

  @callback account_nav_sections([map()], map()) :: [map()]
end
