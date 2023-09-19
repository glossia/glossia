defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [
      Plugs.AssignProjectFromURLPlug,
      Plugs.RedirectToProjectIfNeededPlug,
      Plugs.SaveLastVisitedProjectPlug,
      Plugs.AssignProjectFromURLPlug,
      Controllers.ProjectController
    ],
    deps: [Glossia.Foundation.Projects.Core, Glossia.Foundation.Accounts.Web, Glossia.Foundation.Accounts.Core]
end
