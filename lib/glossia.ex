defmodule Glossia do
  use Boundary, deps: [], exports: [Endpoint, Foundation.API.Web, Foundation.Utilities.Core.ErrorReporter]
end
