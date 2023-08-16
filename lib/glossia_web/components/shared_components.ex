defmodule GlossiaWeb.SharedComponents do
  @moduledoc """
  A set of components that are shared across all the layouts
  """

  # Modules
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import GlossiaWeb.Gettext

  def marketing_fonts(assigns) do
    ~H"""
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&display=swap"
      rel="stylesheet"
    />
    """
  end
end
