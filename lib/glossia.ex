defmodule Glossia do
  use Boundary, deps: [], exports: [App.Endpoint, Foundation.API.Web, Foundation.Utilities.Core.ErrorReporter]
end
