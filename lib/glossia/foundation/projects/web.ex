defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [Plugs.AssignProjectFromURLPlug, Plugs.RedirectToDefaultProjectPlug, Controllers.ProjectController],
    deps: [Glossia.Foundation.Projects.Core]
end
