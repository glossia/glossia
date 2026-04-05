defmodule Glossia.Changelog do
  defmodule Source do
    @moduledoc false

    @callback all_entries() :: [map()]
  end

  def all_entries, do: Glossia.Extensions.changelog().all_entries()
end

defmodule Glossia.Changelog.Empty do
  @moduledoc false

  @behaviour Glossia.Changelog.Source

  @impl true
  def all_entries, do: []
end
