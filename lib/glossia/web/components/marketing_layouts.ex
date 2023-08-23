defmodule Glossia.Web.MarketingLayouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Web, :marketing_html

  embed_templates "marketing_layouts/*"
end
