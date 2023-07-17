defmodule GlossiaWeb.MarketingComponents do
  @moduledoc """
  It provides marketing components
  """
  use Boundary, deps: [GlossiaWeb.Gettext]

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import GlossiaWeb.Gettext
end
