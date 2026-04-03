defmodule Glossia.Navigation.Default do
  @moduledoc false

  @behaviour Glossia.Navigation

  @impl true
  def account_nav_sections(sections, _assigns), do: sections
end
