defmodule Glossia.Foundation.Accounts.Web.Layouts do
  @moduledoc """
  A module that embeds all the available layouts at compile time.
  """
  use Glossia.Foundation.Application.Web.Helpers.App, :html

  embed_templates "layouts/*"
end
