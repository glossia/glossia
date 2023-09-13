defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [Plugs.AssignProjectFromURLPlug, Controllers.ProjectController],
    deps: [Glossia.Foundation.Projects.Core]
end
