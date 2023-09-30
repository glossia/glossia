defmodule Glossia.Foundation.Localizations.Web do
  # Modules
  use Boundary,
    deps: [],
    exports: [
      API.Controllers.LocalizationController,
      API.Schemas.Checksum.Value,
      API.Schemas.Checksum,
      API.Schemas.CreateResponse,
      API.Schemas.Localization,
      API.Schemas.SourceContext,
      API.Schemas.SourceLocalizableContent,
      API.Schemas.TargetContext,
      API.Schemas.TargetLocalizableContent
    ]
end
