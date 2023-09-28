defmodule Glossia.Features.Cloud.Docs.Web do
  use Boundary,
    deps: [Glossia.Features.Cloud.Docs.Core],
    exports: [Controllers.DocsController]
end
