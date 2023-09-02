defmodule Glossia.Foundation.Utilities.Core do
  use Boundary, deps: [], exports: [Release, Version, Mailer]

  def module_compiled?(module) do
    function_exported?(module, :__info__, 1)
  end
end
