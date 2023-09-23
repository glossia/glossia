defmodule Glossia.Foundation.Projects.Web do
  use Boundary,
    exports: [
      Controllers.ProjectController,
      Plugs.RedirectToProjectIfNeededPlug,
      Plugs.ResourcesPlug,
      Plugs.SaveLastVisitedProjectPlug
    ],
    deps: [
      Glossia.Foundation.Accounts.Core,
      Glossia.Foundation.Accounts.Web,
      Glossia.Foundation.Application.Core,
      Glossia.Foundation.ContentSources.Core,
      Glossia.Foundation.Projects.Core,
      Glossia.Foundation.ContentSources.Core
    ]
end
