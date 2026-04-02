defmodule Glossia.Navigation do
  @moduledoc """
  Behaviour for optional navigation extensions.
  """

  @callback account_nav_items(map()) :: [map()]
end
