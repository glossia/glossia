defmodule BabelWeb.OAuth.AuthorizeHTML do
  use BabelWeb, :html
  use Noora

  embed_templates "authorize_html/*"
end
