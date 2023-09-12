defmodule Glossia.Foundation.Accounts.Web do
  use Boundary,
    deps: [Glossia.Web, Glossia.Foundation.Application.Web, Glossia.Foundation.Accounts.Core, Glossia.Foundation.Auth.Core, Glossia.Foundation.Projects.Core],
    exports: [Controllers.AuthController, Resources, Policies]
end
