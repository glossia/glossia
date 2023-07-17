defmodule GlossiaWeb.MarketingLayouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use GlossiaWeb, :marketing_html

  embed_templates "marketing_layouts/*"
end
