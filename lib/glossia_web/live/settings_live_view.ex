defmodule GlossiaWeb.LiveViews.SettingsLiveView do
  use GlossiaWeb.Helpers.App, :live_view

  def mount(_params, _, socket) do
    {:ok, socket}
  end

  # def handle_event("validate", %{"project" => attrs}, socket) do
  #   changeset = %Project{} |> Project.changeset(attrs) |> Map.put(:action, :insert)
  #   {:noreply, assign(socket, project_changeset: changeset)}
  # end
end
