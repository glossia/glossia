defmodule Glossia.Foundation.Accounts.Web do
  use Boundary,
    deps: [
      Glossia.Foundation.Accounts.Core,
      Glossia.Foundation.Auth.Core,
      Glossia.Foundation.Projects.Core,
      Glossia.Foundation.Analytics.Core,
      Glossia.Foundation.Application.Core,
      Glossia.Support.Utilities.Web
    ],
    exports: [Controllers.AuthController, Policies, Auth, Helpers.Auth, Plugs.ResourcesPlug]
end
