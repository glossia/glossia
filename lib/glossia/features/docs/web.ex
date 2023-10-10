defmodule Glossia.Features.Docs.Web do
  use Boundary,
    deps: [Glossia.Features.Docs.Core],
    exports: [Controllers.DocsController]
end
