defmodule Glossia.Foundation.Utilities do
  use Boundary

  def module_compiled?(module) do
    function_exported?(module, :__info__, 1)
  end
end
