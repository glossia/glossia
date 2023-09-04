defmodule Glossia do
  use Boundary,
    deps: [],
    exports: [Application.Endpoint, Foundation.API.Web, Foundation.Utilities.Core.ErrorReporter]
end
