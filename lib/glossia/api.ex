defmodule Glossia.API do
  use Boundary, deps: [Glossia.Version], exports: [Schemas.LocalizationRequest.CreateResponse]
end
