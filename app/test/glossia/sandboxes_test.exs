defmodule Glossia.SandboxesTest do
  use Glossia.DataCase, async: false

  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.Sandboxes
  alias Glossia.Sandboxes.{Sandbox, SandboxSession}
  alias Glossia.TestHelpers

  defmodule FakeAdapter do
    @behaviour Glossia.Sandbox

    def create(params), do: {:ok, to_string(params[:id] || params["id"])}
    def execute(_sandbox_id, _command, _opts), do: {:ok, result("ok")}
    def delete(_sandbox_id), do: :ok
    def download_file(_sandbox_id, _path), do: {:ok, ""}
    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/repo"}
    def start_agent_session(_sandbox_id, _caller, _opts), do: {:ok, self()}

    defp result(stdout) do
      %{"exitCode" => 0, "stdout" => stdout, "stderr" => "", "timedOut" => false}
    end
  end

  defmodule DeleteFailingAdapter do
    @behaviour Glossia.Sandbox

    def create(params), do: {:ok, to_string(params[:id] || params["id"])}
    def execute(_sandbox_id, _command, _opts), do: {:ok, %{}}
    def delete(_sandbox_id), do: {:error, :delete_failed}
    def download_file(_sandbox_id, _path), do: {:ok, ""}
    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/repo"}
    def start_agent_session(_sandbox_id, _caller, _opts), do: {:ok, self()}
  end

  defmodule DeleteNotFoundAdapter do
    @behaviour Glossia.Sandbox

    def create(params), do: {:ok, to_string(params[:id] || params["id"])}
    def execute(_sandbox_id, _command, _opts), do: {:ok, %{}}
    def delete(_sandbox_id), do: {:error, :not_found}
    def download_file(_sandbox_id, _path), do: {:ok, ""}
    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/repo"}
    def start_agent_session(_sandbox_id, _caller, _opts), do: {:ok, self()}
  end

  test "creates a sandbox, executes commands, manages files, and destroys it" do
    user = TestHelpers.create_user("sandbox-context@test.com", "sandbox-context")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "sandbox-project",
        name: "Sandbox Project"
      })

    assert {:ok, sandbox} =
             Sandboxes.create_sandbox(user.account, project, %{
               purpose: "translation",
               labels: %{"workflow" => "translate"}
             })

    assert sandbox.status == "ready"
    assert sandbox.project_id == project.id
    assert sandbox.backend_ref == "cluster:#{node()}"
    assert sandbox.labels["workflow"] == "translate"

    assert %SandboxSession{status: "open"} =
             Repo.one!(from s in SandboxSession, where: s.sandbox_id == ^sandbox.id)

    assert {:ok, %{"exitCode" => 0, "stdout" => "hello"}} =
             Sandboxes.execute_sandbox(sandbox, "printf hello")

    assert :ok = Sandboxes.write_file(sandbox, "notes/output.txt", "ciao")
    assert {:ok, "ciao"} = Sandboxes.read_file(sandbox, "notes/output.txt")
    assert {:error, :path_outside_sandbox} = Sandboxes.read_file(sandbox, "../secret.txt")

    {:ok, repo_path} = Glossia.Sandbox.ClusterAdapter.repo_path(to_string(sandbox.id))
    outside_path = Path.join(System.tmp_dir!(), "glossia-secret-#{System.unique_integer()}")
    File.write!(outside_path, "secret")
    File.ln_s!(outside_path, Path.join(repo_path, "leak"))

    assert {:error, :path_outside_sandbox} = Sandboxes.read_file(sandbox, "repo/leak")

    File.rm(outside_path)

    assert {:ok, terminated} = Sandboxes.destroy_sandbox(sandbox, reason: "test_done")
    assert terminated.status == "terminated"

    assert %SandboxSession{status: "closed", close_reason: "test_done"} =
             Repo.one!(from s in SandboxSession, where: s.sandbox_id == ^sandbox.id)
  end

  test "enforces account ownership when fetching sandboxes" do
    owner = TestHelpers.create_user("sandbox-owner@test.com", "sandbox-owner")
    outsider = TestHelpers.create_user("sandbox-outsider@test.com", "sandbox-outsider")

    assert {:ok, sandbox} = Sandboxes.create_sandbox(owner.account)

    assert Sandboxes.get_sandbox(owner.account, to_string(sandbox.id)).id == sandbox.id
    assert Sandboxes.get_sandbox(outsider.account, to_string(sandbox.id)) == nil

    assert {:ok, _terminated} = Sandboxes.destroy_sandbox(sandbox, reason: "test_done")
  end

  test "returns changeset errors for invalid sandbox attributes" do
    user = TestHelpers.create_user("sandbox-invalid@test.com", "sandbox-invalid")

    assert {:error, %Ecto.Changeset{} = changeset} =
             Sandboxes.create_sandbox(user.account, nil, %{labels: "not-a-map"},
               adapter: FakeAdapter
             )

    assert errors_on(changeset)[:labels]
  end

  test "enforces account active sandbox quota" do
    sandbox_config = Application.get_env(:glossia, Glossia.Sandbox, [])

    Application.put_env(
      :glossia,
      Glossia.Sandbox,
      Keyword.put(sandbox_config, :max_active_per_account, 1)
    )

    on_exit(fn -> Application.put_env(:glossia, Glossia.Sandbox, sandbox_config) end)

    user = TestHelpers.create_user("sandbox-quota@test.com", "sandbox-quota")

    assert {:ok, sandbox} = Sandboxes.create_sandbox(user.account, nil, %{}, adapter: FakeAdapter)

    assert {:error, :sandbox_quota_exceeded} =
             Sandboxes.create_sandbox(user.account, nil, %{}, adapter: FakeAdapter)

    assert {:ok, _terminated} = Sandboxes.destroy_sandbox(sandbox, adapter: FakeAdapter)
  end

  test "blocks public operations against project setup sandboxes" do
    user = TestHelpers.create_user("sandbox-project-setup@test.com", "sandbox-project-setup")

    assert {:ok, sandbox} =
             Sandboxes.create_sandbox(user.account, nil, %{purpose: "project_setup"},
               adapter: FakeAdapter
             )

    assert {:error, :sandbox_operation_not_allowed} = Sandboxes.read_file(sandbox, "config.json")
    assert {:error, :sandbox_operation_not_allowed} = Sandboxes.execute_sandbox(sandbox, "pwd")

    assert {:error, :sandbox_operation_not_allowed} =
             Sandboxes.write_file(sandbox, "config.json", "{}")

    assert {:error, :sandbox_operation_not_allowed} =
             Sandboxes.delete_file(sandbox, "config.json")

    assert {:ok, _terminated} = Sandboxes.destroy_sandbox(sandbox, adapter: FakeAdapter)
  end

  test "microsandbox adapter rejects unsafe public input before invoking msb" do
    assert {:error, :shell_syntax_not_supported} =
             Glossia.Sandbox.MicrosandboxAdapter.execute("sandbox-id", "echo ok; whoami")

    assert {:error, :shell_syntax_not_supported} =
             Glossia.Sandbox.MicrosandboxAdapter.execute("sandbox-id", "echo ok\nwhoami")

    assert {:error, :path_outside_sandbox} =
             Glossia.Sandbox.MicrosandboxAdapter.execute("sandbox-id", "pwd", cwd: "/")

    assert {:error, :path_outside_sandbox} =
             Glossia.Sandbox.MicrosandboxAdapter.download_file("sandbox-id", "/etc/passwd")
  end

  test "keeps delete failures retryable and reaps them later" do
    user = TestHelpers.create_user("sandbox-delete-retry@test.com", "sandbox-delete-retry")

    assert {:ok, sandbox} =
             Sandboxes.create_sandbox(user.account, nil, %{purpose: "delete_retry"},
               adapter: FakeAdapter
             )

    assert {:error, :delete_failed} =
             Sandboxes.destroy_sandbox(sandbox,
               adapter: DeleteFailingAdapter,
               reason: "test_done"
             )

    retryable = Repo.get!(Sandbox, sandbox.id)
    assert retryable.status == "terminating"
    assert retryable.terminated_at == nil
    assert retryable.error =~ "delete_failed"

    assert [{:ok, terminated}] =
             Sandboxes.reap_expired_sandboxes(DateTime.utc_now(),
               adapter: FakeAdapter,
               delete_retry_after_ms: 0
             )

    assert terminated.status == "terminated"

    assert %SandboxSession{status: "closed", close_reason: "deadline"} =
             Repo.one!(from s in SandboxSession, where: s.sandbox_id == ^sandbox.id)
  end

  test "treats missing backend deletes as idempotent success" do
    user =
      TestHelpers.create_user("sandbox-delete-not-found@test.com", "sandbox-delete-not-found")

    assert {:ok, sandbox} =
             Sandboxes.create_sandbox(user.account, nil, %{purpose: "delete_not_found"},
               adapter: FakeAdapter
             )

    assert {:ok, terminated} =
             Sandboxes.destroy_sandbox(sandbox,
               adapter: DeleteNotFoundAdapter,
               reason: "already_deleted"
             )

    assert terminated.status == "terminated"

    assert %SandboxSession{status: "closed", close_reason: "already_deleted"} =
             Repo.one!(from s in SandboxSession, where: s.sandbox_id == ^sandbox.id)
  end

  test "treats sandboxes owned by stale cluster nodes as missing backends" do
    user = TestHelpers.create_user("sandbox-stale-owner@test.com", "sandbox-stale-owner")

    assert {:ok, sandbox} =
             Sandboxes.create_sandbox(user.account, nil, %{purpose: "stale_owner"},
               adapter: FakeAdapter
             )

    stale_owner = "cluster:stale-node-#{System.unique_integer([:positive])}@127.0.0.1"

    sandbox =
      sandbox
      |> Sandbox.changeset(%{backend_ref: stale_owner})
      |> Repo.update!()

    assert {:ok, terminated} =
             Sandboxes.destroy_sandbox(sandbox,
               adapter: Glossia.Sandbox.ClusterAdapter,
               reason: "stale_owner"
             )

    assert terminated.status == "terminated"

    assert %SandboxSession{status: "closed", close_reason: "stale_owner"} =
             Repo.one!(from s in SandboxSession, where: s.sandbox_id == ^sandbox.id)
  end
end
