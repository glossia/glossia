defmodule Glossia.Sandbox.RunnerTest do
  use ExUnit.Case, async: true

  alias Glossia.Sandbox.Runner

  test "closes standard input for shell commands" do
    sandbox_id = Ecto.UUID.generate()
    root_path = Path.join(System.tmp_dir!(), "glossia-runner-test-#{sandbox_id}")

    {:ok, runner} = Runner.start_link(sandbox_id: sandbox_id, root_path: root_path)

    assert {:ok, %{"exitCode" => 0, "stdout" => "closed"}} =
             GenServer.call(
               runner,
               {:execute_shell, "if IFS= read -r value; then printf open; else printf closed; fi",
                timeout_ms: 1_000},
               2_000
             )

    assert :ok = GenServer.call(runner, :delete)
  end
end
