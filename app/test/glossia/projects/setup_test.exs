defmodule Glossia.Projects.SetupTest do
  use Glossia.DataCase, async: false

  alias Glossia.Accounts.Project
  alias Glossia.Projects
  alias Glossia.Projects.Setup
  alias Glossia.Repo
  alias Glossia.Sandboxes.Sandbox
  alias Glossia.TestHelpers

  defmodule FakeAdapter do
    @behaviour Glossia.Sandbox

    def create(params), do: {:ok, to_string(params[:id] || params["id"])}

    def execute(_sandbox_id, _command, _opts) do
      {:ok, %{"exitCode" => 0, "stdout" => "ok", "stderr" => "", "timedOut" => false}}
    end

    def delete(sandbox_id) do
      send(self(), {:sandbox_deleted, sandbox_id})
      :ok
    end

    def download_file(_sandbox_id, path) do
      if String.ends_with?(path, "L10N.md") do
        {:ok, "# L10N\n"}
      else
        {:error, :enoent}
      end
    end

    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/workspace/repo"}

    def start_agent_session(_sandbox_id, caller, _opts) do
      Task.start(fn -> send(caller, {:agent_done, :completed}) end)
    end
  end

  defmodule ClaimRaceAdapter do
    @behaviour Glossia.Sandbox

    def create(params) do
      if project_id = params[:project_id] || params["project_id"] do
        project = Glossia.Repo.get!(Glossia.Accounts.Project, project_id)
        Glossia.Projects.update_project_sandbox_id(project, "replacement-sandbox")
      end

      {:ok, to_string(params[:id] || params["id"])}
    end

    def execute(_sandbox_id, _command, _opts) do
      {:ok, %{"exitCode" => 0, "stdout" => "ok", "stderr" => "", "timedOut" => false}}
    end

    def delete(sandbox_id) do
      send(self(), {:sandbox_deleted, sandbox_id})
      :ok
    end

    def download_file(_sandbox_id, _path), do: {:error, :enoent}
    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/workspace/repo"}
    def start_agent_session(_sandbox_id, _caller, _opts), do: {:error, :not_reached}
  end

  defmodule SupersedingAdapter do
    @behaviour Glossia.Sandbox

    def create(params), do: {:ok, to_string(params[:id] || params["id"])}

    def execute(_sandbox_id, _command, _opts) do
      {:ok, %{"exitCode" => 0, "stdout" => "ok", "stderr" => "", "timedOut" => false}}
    end

    def delete(sandbox_id) do
      send(self(), {:sandbox_deleted, sandbox_id})
      :ok
    end

    def download_file(_sandbox_id, _path), do: {:error, :enoent}
    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/workspace/repo"}

    def start_agent_session(_sandbox_id, _caller, opts) do
      project = Glossia.Repo.get!(Glossia.Accounts.Project, Keyword.fetch!(opts, :project_id))
      Glossia.Projects.update_project_sandbox_id(project, "replacement-sandbox")
      {:error, :agent_start_failed}
    end
  end

  setup do
    sandbox_config = Application.get_env(:glossia, Glossia.Sandbox, [])
    setup_config = Application.get_env(:glossia, Glossia.Projects.Setup, [])

    Application.put_env(
      :glossia,
      Glossia.Sandbox,
      Keyword.put(sandbox_config, :adapter, FakeAdapter)
    )

    Application.put_env(
      :glossia,
      Glossia.Projects.Setup,
      Keyword.put(setup_config, :minimax_api_key, "test-minimax-key")
    )

    on_exit(fn ->
      Application.put_env(:glossia, Glossia.Sandbox, sandbox_config)
      Application.put_env(:glossia, Glossia.Projects.Setup, setup_config)
    end)

    :ok
  end

  test "runs setup in a sandbox and clears the project sandbox id" do
    user = TestHelpers.create_user("setup-sandbox@test.com", "setup-sandbox")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "setup-project",
        name: "Setup Project",
        github_repo_full_name: "glossia/demo",
        github_repo_default_branch: "main",
        setup_target_languages: ["es"]
      })

    assert :ok = Setup.run(project.id)

    updated = Repo.get!(Project, project.id)
    assert updated.setup_status == "completed"
    assert updated.setup_error == nil
    assert updated.setup_sandbox_id == nil

    assert %Sandbox{status: "terminated"} =
             Repo.one!(from s in Sandbox, where: s.project_id == ^project.id)
  end

  test "best-effort deletes a missing persisted sandbox id before creating a new one" do
    user = TestHelpers.create_user("setup-missing-sandbox@test.com", "setup-missing-sandbox")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "setup-missing-project",
        name: "Setup Missing Project",
        github_repo_full_name: "glossia/missing-demo",
        setup_target_languages: ["fr"]
      })

    missing_id = "missing-sandbox-id"
    Projects.update_project_sandbox_id(project, missing_id)

    assert :ok = Setup.run(project.id)
    assert_received {:sandbox_deleted, ^missing_id}
  end

  test "does not replace a sandbox id claimed by another setup run" do
    Application.put_env(
      :glossia,
      Glossia.Sandbox,
      adapter: ClaimRaceAdapter,
      enabled: true,
      max_active_per_account: 3,
      default_ttl_seconds: 3600
    )

    user = TestHelpers.create_user("setup-claim-race@test.com", "setup-claim-race")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "setup-claim-race-project",
        name: "Setup Claim Race Project",
        github_repo_full_name: "glossia/claim-race",
        setup_target_languages: ["de"]
      })

    assert {:error, :setup_already_running} = Setup.run(project.id)

    updated = Repo.get!(Project, project.id)
    assert updated.setup_sandbox_id == "replacement-sandbox"
    assert updated.setup_status == "running"
    assert_received {:sandbox_deleted, sandbox_id}
    refute sandbox_id == "replacement-sandbox"
  end

  test "failed setup cleanup only clears the sandbox id it owns" do
    Application.put_env(
      :glossia,
      Glossia.Sandbox,
      adapter: SupersedingAdapter,
      enabled: true,
      max_active_per_account: 3,
      default_ttl_seconds: 3600
    )

    user = TestHelpers.create_user("setup-cleanup-race@test.com", "setup-cleanup-race")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "setup-cleanup-race-project",
        name: "Setup Cleanup Race Project",
        github_repo_full_name: "glossia/cleanup-race",
        setup_target_languages: ["it"]
      })

    assert {:error, :agent_start_failed} = Setup.run(project.id)

    updated = Repo.get!(Project, project.id)
    assert updated.setup_sandbox_id == "replacement-sandbox"
    assert updated.setup_status == "running"
    assert_received {:sandbox_deleted, sandbox_id}
    refute sandbox_id == "replacement-sandbox"
  end
end
