defmodule Glossia.Foundation.ContentSources.Web do
  use Boundary, deps: [Glossia.Foundation.ContentSources.Core], exports: [Plug]
end
