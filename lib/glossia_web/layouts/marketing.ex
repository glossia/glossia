defmodule GlossiaWeb.Layouts.Marketing do
  @moduledoc ~S"""
  A module that embeds all the available layouts at compile time.
  """
  use GlossiaWeb.Helpers.Marketing, :html

  embed_templates "marketing/*"
end
