defmodule Glossia.Sandbox.LocalAdapterTest do
  use Glossia.DataCase, async: true

  alias Glossia.{Sandboxes, TestHelpers}
  alias Glossia.Sandbox.LocalAdapter
  alias Glossia.Sandboxes.Sandbox

  test "local workspaces support file operations and remove their files on deletion" do
    user = TestHelpers.create_user("local-workspace@example.test", "local-workspace")

    assert {:ok, sandbox} =
             Sandboxes.create_sandbox(user.account, nil, %{}, adapter: LocalAdapter)

    id = to_string(sandbox.id)
    assert sandbox.backend_ref == Atom.to_string(node())
    on_exit(fn -> LocalAdapter.local_call(id, :delete) end)
    assert {:ok, repo} = LocalAdapter.repo_path(id)
    assert :ok = LocalAdapter.upload_file(id, Path.join(repo, "hello.txt"), "Hello")
    assert {:ok, "Hello"} = LocalAdapter.download_file(id, Path.join(repo, "hello.txt"))

    assert {:ok, %{"stdout" => "Hello", "exitCode" => 0}} =
             LocalAdapter.execute(id, "cat hello.txt", cwd: repo)

    assert {:error, :path_outside_sandbox} =
             LocalAdapter.upload_file(id, Path.join(repo, "../../outside.txt"), "No")

    assert :ok = LocalAdapter.delete_file(id, Path.join(repo, "hello.txt"))
    assert {:error, :enoent} = LocalAdapter.download_file(id, Path.join(repo, "hello.txt"))
    assert :ok = LocalAdapter.delete(id)
    refute File.exists?(repo)
    assert :ok = LocalAdapter.delete(id)
  end

  test "an unreachable owner leaves deletion retryable instead of reporting success" do
    user = TestHelpers.create_user("remote-workspace@example.test", "remote-workspace")

    sandbox =
      %Sandbox{}
      |> Sandbox.changeset(%{
        account_id: user.account.id,
        status: "ready",
        backend: "local",
        backend_ref: "unavailable@other-host"
      })
      |> Repo.insert!()

    assert {:error, :sandbox_owner_unavailable} = LocalAdapter.repo_path(to_string(sandbox.id))
    assert {:error, :sandbox_owner_unavailable} = LocalAdapter.delete(to_string(sandbox.id))
    assert {:error, _} = Sandboxes.destroy_sandbox(sandbox, adapter: LocalAdapter)
    assert Repo.get!(Sandbox, sandbox.id).status == "terminating"
  end
end
