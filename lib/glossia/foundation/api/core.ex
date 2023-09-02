defmodule Glossia.Foundation.API.Core do
  use Boundary, deps: [Glossia.Foundation.Utilities.Core], exports: [Schemas.LocalizationRequest.CreateResponse]
end
