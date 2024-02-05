defmodule GlossiaWeb.Controllers.DocsHTML do
  use GlossiaWeb.Helpers.Docs, :html

  embed_templates "docs_html/*"
end
