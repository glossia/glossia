defmodule Glossia.Foundation.Accounts.Web do
  use Boundary,
    deps: [Glossia.Web, Glossia.Foundation.Application.Web, Glossia.Foundation.Accounts.Core, Glossia.Foundation.Auth.Core],
    exports: [Controllers.AuthController]
end
