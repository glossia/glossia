defmodule GlossiaWeb.Layouts.App do
  @moduledoc ~S"""
  A module that embeds all the available layouts at compile time.
  """
  use GlossiaWeb.Helpers.App, :html

  embed_templates "app/*"
end
