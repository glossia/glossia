defmodule GlossiaWeb.Layouts.Auth do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use GlossiaWeb.Helpers.App, :html

  embed_templates "auth/*"
end
