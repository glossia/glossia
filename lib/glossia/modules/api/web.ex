defmodule Glossia.Modules.API.Web do
  use Boundary,
    deps: [Glossia.Web, Glossia.Modules.API.Core, Glossia.Modules.Localizations.Core],
    exports: [Controllers.Project.LocalizationRequestController]
end
