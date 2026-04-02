defmodule Glossia.Navigation.Default do
  @moduledoc false

  @behaviour Glossia.Navigation

  @impl true
  def account_nav_items(_assigns), do: []
end
