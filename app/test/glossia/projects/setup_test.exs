defmodule Glossia.Projects.SetupTest do
  use Glossia.DataCase, async: false
  use Mimic

  alias Glossia.Accounts.Project
  alias Glossia.Github.Installations
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

    def download_file(_sandbox_id, "/workspace/glossia-setup-changes.json") do
      {:ok,
       JSON.encode!(%{
         version: 1,
         files: [
           %{path: "GLOSSIA.md", status: "added"},
           %{path: "src/i18n/en.json", status: "modified"}
         ]
       })}
    end

    def download_file(_sandbox_id, "/workspace/repo/GLOSSIA.md") do
      {:ok, "# Glossia\n"}
    end

    def download_file(_sandbox_id, "/workspace/repo/src/i18n/en.json") do
      {:ok, ~s({"hello":"Hello"})}
    end

    def download_file(_sandbox_id, _path), do: {:error, :enoent}

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

  test "creates a pull request from every setup change" do
    user = TestHelpers.create_user("setup-pr@test.com", "setup-pr")

    {:ok, installation} =
      Installations.create_installation(user.account, %{
        github_installation_id: 42,
        github_account_login: "glossia",
        github_account_type: "Organization",
        github_account_id: 4242
      })

    {:ok, project} =
      Projects.create_project_from_github(user.account, installation.id, %{
        handle: "setup-pr-project",
        name: "Setup Pull Request Project",
        github_repo_full_name: "glossia/demo",
        github_repo_default_branch: "main",
        setup_target_languages: ["es", "fr"]
      })

    test_pid = self()

    Mimic.expect(Glossia.Github.App, :installation_token, 2, fn 42 ->
      {:ok, "github-token"}
    end)

    Mimic.expect(Glossia.Github.Client, :get_ref, fn "glossia/demo",
                                                     "heads/main",
                                                     "github-token" ->
      {:ok, %{"object" => %{"sha" => "base-commit-sha"}}}
    end)

    Mimic.expect(Glossia.Github.Client, :get_commit, fn "glossia/demo",
                                                        "base-commit-sha",
                                                        "github-token" ->
      {:ok, %{"tree" => %{"sha" => "base-tree-sha"}}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_blob, 2, fn "glossia/demo",
                                                            %{
                                                              content: content,
                                                              encoding: "base64"
                                                            },
                                                            "github-token" ->
      {:ok, decoded} = Base.decode64(content)
      sha = :crypto.hash(:sha, decoded) |> Base.encode16(case: :lower)
      {:ok, %{"sha" => sha}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_tree, fn "glossia/demo",
                                                         %{
                                                           base_tree: "base-tree-sha",
                                                           tree: entries
                                                         },
                                                         "github-token" ->
      send(test_pid, {:tree_entries, entries})
      {:ok, %{"sha" => "new-tree-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_commit, fn "glossia/demo",
                                                           %{
                                                             message:
                                                               "feat: set up Glossia localization",
                                                             tree: "new-tree-sha",
                                                             parents: ["base-commit-sha"]
                                                           },
                                                           "github-token" ->
      {:ok, %{"sha" => "new-commit-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_branch, fn "glossia/demo",
                                                           "glossia/setup-localization",
                                                           "new-commit-sha",
                                                           "github-token" ->
      {:ok, %{}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_pull_request, fn "glossia/demo",
                                                                 params,
                                                                 "github-token" ->
      send(test_pid, {:pull_request_params, params})
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/1"}}
    end)

    assert :ok = Setup.run(project.id)

    assert_received {:tree_entries, entries}
    assert Enum.map(entries, & &1.path) == ["GLOSSIA.md", "src/i18n/en.json"]
    assert Enum.all?(entries, &(&1.type == "blob"))

    assert_received {:pull_request_params, params}
    assert params.title == "feat: set up Glossia localization"
    assert params.head == "glossia/setup-localization"
    assert params.base == "main"
    assert params.body =~ "Target languages: es, fr."
    assert params.body =~ "`GLOSSIA.md`"
    assert params.body =~ "`src/i18n/en.json`"
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
