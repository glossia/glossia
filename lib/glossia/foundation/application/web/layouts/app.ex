defmodule Glossia.Foundation.Application.Web.Layouts.App do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Foundation.Application.Web.Helpers.App, :html

  embed_templates "app/*"
end
