defmodule Glossia.Foundation.API.Web do
  use Boundary,
    deps: [
      Glossia.Foundation.API.Core,
      Glossia.Foundation.Localizations.Core,
      Glossia.Foundation.Accounts.Web
    ],
    exports: [Controllers.Project.LocalizationRequestController]
end
