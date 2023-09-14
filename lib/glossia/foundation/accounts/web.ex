defmodule Glossia.Foundation.Accounts.Web do
  use Boundary,
    deps: [
      Glossia.Foundation.Accounts.Core,
      Glossia.Foundation.Auth.Core,
      Glossia.Foundation.Projects.Core,
      Glossia.Foundation.Analytics.Core
    ],
    exports: [Controllers.AuthController, Resources, Policies, Auth, Helpers.Auth]
end
