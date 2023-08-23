defmodule Glossia.Modules.API.Core do
  use Boundary, exports: [Schemas.LocalizationRequest.CreateResponse]
end
