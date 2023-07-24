defmodule Glossia.VM do
  use Boundary, deps: [], exports: []

  @moduledoc """
  It provides utilities to interact with virtualized environments where builds run.
  """

  @spec run_builder() :: any()
  def run_builder() do
    Glossia.VM.Builder.run()
  end
end
