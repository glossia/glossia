defmodule Glossia.Modules.API do
  use Boundary, deps: [Glossia.Modules.Localizations], exports: [Web, Core]
end
