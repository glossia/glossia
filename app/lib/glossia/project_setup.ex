defmodule Glossia.ProjectSetup do
  @moduledoc """
  Automated project onboarding seam.

  In the open-source build a new project is immediately marked as ready — no
  agent, no sandbox, no repo introspection. The person who created it adds
  `L10N.md` (and any other configuration) to the repository by hand.

  A downstream build swaps this behaviour for one that starts an agent inside
  an isolated sandbox to draft the configuration and open a pull request.
  Configure through:

      config :glossia, :project_setup, module: MyApp.ProjectSetup

  or set `GLOSSIA_PROJECT_SETUP_MODULE` at runtime.
  """

  alias Glossia.Accounts.Project

  @callback start(Project.t()) :: :ok | {:error, term()}
  @callback retry(project_id :: integer()) :: :ok | {:error, term()}

  def impl do
    :glossia
    |> Application.get_env(:project_setup, [])
    |> Keyword.get(:module, Glossia.ProjectSetup.Default)
  end

  def start(project), do: impl().start(project)
  def retry(project_id), do: impl().retry(project_id)
end
