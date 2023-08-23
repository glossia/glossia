defmodule Glossia.Foundation.API.Web do
  use Boundary,
    deps: [Glossia.Web, Glossia.Foundation.API.Core, Glossia.Foundation.Localizations.Core],
    exports: [Controllers.Project.LocalizationRequestController]
end
