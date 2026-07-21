defmodule Glossia.Projects.SetupStartTimeoutTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.Project
  alias Glossia.LLMModels
  alias Glossia.Projects
  alias Glossia.Projects.Setup
  alias Glossia.Repo
  alias Glossia.TestHelpers

  defmodule SandboxStartTimeoutAdapter do
    @behaviour Glossia.Sandbox

    def create(_params), do: {:error, {:sandbox_start_timeout, :runner_connection_timeout}}
    def execute(_sandbox_id, _command, _opts), do: {:error, :not_found}
    def delete(_sandbox_id), do: :ok
    def download_file(_sandbox_id, _path), do: {:error, :not_found}
    def upload_file(_sandbox_id, _path, _content), do: {:error, :not_found}
    def delete_file(_sandbox_id, _path), do: {:error, :not_found}
    def repo_path(_sandbox_id), do: {:error, :not_found}
    def start_agent_session(_sandbox_id, _caller, _opts), do: {:error, :not_found}
  end

  test "shows a retryable message when the setup environment times out while starting" do
    user = TestHelpers.create_user("setup-start-timeout@test.com", "setup-start-timeout")

    assert {:ok, _model} =
             LLMModels.create_model(user.account, user, %{
               handle: "setup-model",
               model: "openai:gpt-4o-mini",
               api_key: "test-api-key"
             })

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "setup-start-timeout",
        name: "Setup Start Timeout",
        github_repo_full_name: "glossia/setup-start-timeout",
        github_repo_default_branch: "main",
        setup_target_languages: ["es"]
      })

    assert {:error, {:sandbox_start_timeout, :runner_connection_timeout}} =
             Setup.run(project.id, sandbox_adapter: SandboxStartTimeoutAdapter)

    updated = Repo.get!(Project, project.id)
    assert updated.setup_status == "failed"

    assert updated.setup_error ==
             "The setup environment took too long to start. Please retry setup."
  end
end
