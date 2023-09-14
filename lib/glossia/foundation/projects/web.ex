defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [Plugs.AssignProjectFromURLPlug, Plugs.RedirectToDefaultProjectWhenAuthenticatedPlug, Controllers.ProjectController],
    deps: [Glossia.Foundation.Projects.Core, Glossia.Foundation.Accounts.Web]
end
