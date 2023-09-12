defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [Plugs.AssignProjectFromURLPlug],
    deps: [Glossia.Foundation.Projects.Core]
end
