defmodule Glossia.Foundation.Localizations.Web do
  # Modules
  use Boundary,
    deps: [],
    exports: [
      API.Controllers.LocalizationRequestController,
      API.Schemas.Checksum.Value,
      API.Schemas.Checksum,
      API.Schemas.CreateResponse,
      API.Schemas.LocalizationRequest,
      API.Schemas.SourceContext,
      API.Schemas.SourceLocalizableContent,
      API.Schemas.TargetContext,
      API.Schemas.TargetLocalizableContent
    ]
end
