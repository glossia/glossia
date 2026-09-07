defmodule Glossia.SandboxesStartFailureTest do
  use Glossia.DataCase, async: true

  alias Glossia.Repo
  alias Glossia.Sandboxes
  alias Glossia.Sandboxes.Sandbox
  alias Glossia.TestHelpers

  defmodule CreateFailingAdapter do
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

  test "preserves a structured adapter error when sandbox startup fails" do
    user = TestHelpers.create_user("sandbox-start-failure@test.com", "sandbox-start-failure")

    assert {:error, {:sandbox_start_timeout, :runner_connection_timeout}} =
             Sandboxes.create_sandbox(user.account, nil, %{}, adapter: CreateFailingAdapter)

    assert %Sandbox{
             status: "failed",
             error: "{:sandbox_start_timeout, :runner_connection_timeout}"
           } =
             Repo.one!(from sandbox in Sandbox, where: sandbox.account_id == ^user.account.id)
  end
end
