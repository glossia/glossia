defmodule GlossiaWeb.Layouts.Docs do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use GlossiaWeb.Helpers.Docs, :html

  embed_templates "docs/*"
end
