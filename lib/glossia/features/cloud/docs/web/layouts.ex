defmodule Glossia.Features.Cloud.Docs.Web.Layouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Features.Cloud.Docs.Web.Helpers, :html

  embed_templates "layouts/*"
end
