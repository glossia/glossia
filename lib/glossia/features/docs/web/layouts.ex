defmodule Glossia.Features.Docs.Web.Layouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Features.Docs.Web.Helpers, :html

  embed_templates "layouts/*"
end
