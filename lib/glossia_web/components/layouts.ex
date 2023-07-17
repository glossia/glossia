defmodule GlossiaWeb.Layouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use GlossiaWeb, :app_html
  use GlossiaWeb, :marketing_html

  embed_templates "layouts/*"
end
