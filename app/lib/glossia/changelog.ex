defmodule Glossia.Changelog do
  defmodule Source do
    @moduledoc false

    @callback all_entries() :: [map()]
  end

  def all_entries, do: Glossia.Extensions.changelog().all_entries()
end
