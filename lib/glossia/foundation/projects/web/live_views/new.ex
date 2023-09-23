defmodule Glossia.Foundation.Projects.Web.LiveViews.New do
  use Glossia.Foundation.Application.Web.Helpers.App, :live_view

  def mount(_params, _, socket) do
    {:ok, socket}
  end
end
