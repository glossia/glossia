defmodule Glossia.Web.AppLayouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Web, :app_html

  embed_templates "app_layouts/*"
end