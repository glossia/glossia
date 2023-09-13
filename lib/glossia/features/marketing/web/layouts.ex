defmodule Glossia.Features.Marketing.Web.Layouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Foundation.Application.Web, :marketing_html

  embed_templates "layouts/*"
end
