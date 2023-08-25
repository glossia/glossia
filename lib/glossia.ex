defmodule Glossia do
  use Boundary, deps: [], exports: [ErrorReporter, Endpoint, Foundation.API.Web]
end
