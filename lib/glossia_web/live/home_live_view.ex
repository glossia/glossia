defmodule GlossiaWeb.LiveViews.HomeLiveView do
  use GlossiaWeb.Helpers.App, :live_view

  def mount(_params, _, socket) do
    {:ok, socket}
  end
end
