defmodule Glossia.Modules.API.Web do
  use Boundary, deps: [Glossia.Modules.API.Core], exports: [Controllers.Project.LocalizationRequestController]
end
