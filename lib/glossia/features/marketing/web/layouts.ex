defmodule Glossia.Features.Marketing.Web.Layouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Features.Marketing.Web.Helpers, :html

  embed_templates "layouts/*"
end
