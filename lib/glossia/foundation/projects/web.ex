defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [
      Plugs.RedirectToProjectIfNeededPlug,
      Plugs.SaveLastVisitedProjectPlug,
      Plugs.ResourcesPlug,
      Controllers.ProjectController
    ],
    deps: [
      Glossia.Foundation.Projects.Core,
      Glossia.Foundation.Accounts.Web,
      Glossia.Foundation.Accounts.Core,
      Glossia.Foundation.Application.Core
    ]
end
