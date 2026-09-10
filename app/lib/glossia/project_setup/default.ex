defmodule Glossia.ProjectSetup.Default do
  @moduledoc """
  Default `Glossia.ProjectSetup` — treats every new project as ready.

  Flips the project's `setup_status` straight to `"completed"` and returns
  `:ok`. `retry/1` is a no-op for the same reason: nothing was scheduled to
  fail.
  """

  @behaviour Glossia.ProjectSetup

  alias Glossia.Projects

  @impl true
  def start(project) do
    case Projects.update_project_setup_status(project, "completed") do
      {:ok, _project} -> :ok
      {:error, _reason} = error -> error
    end
  end

  @impl true
  def retry(_project_id), do: :ok
end
