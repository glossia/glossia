defmodule Glossia.Sandbox.RunnerTest do
  use ExUnit.Case, async: true

  alias Glossia.Sandbox.Runner
  alias Glossia.Sandbox.SafeCommand

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

  test "allows only constrained headless browser commands" do
    assert {:ok, ["chromium" | _]} =
             SafeCommand.parse(
               "chromium --headless --disable-gpu --dump-dom --virtual-time-budget=5000 https://example.com/es"
             )

    assert {:ok, ["chromium" | resolver_argv]} =
             SafeCommand.parse(
               ~s(chromium "--host-resolver-rules=MAP example.com 203.0.113.10,MAP * ~NOTFOUND" --dump-dom https://example.com)
             )

    assert Enum.any?(resolver_argv, &String.starts_with?(&1, "--host-resolver-rules="))

    assert {:ok, ["chromium", "--headless", "--dump-dom", "about:blank"]} =
             SafeCommand.parse("chromium --headless --dump-dom about:blank")

    assert {:error, :invalid_browser_address} =
             SafeCommand.parse("chromium --headless file:///etc/passwd")

    assert {:error, :invalid_browser_flag} =
             SafeCommand.parse(
               "chromium --headless --remote-debugging-port=9222 https://example.com"
             )

    assert {:error, :invalid_browser_flag} =
             SafeCommand.parse("chromium --headless --no-sandbox https://example.com")

    assert {:error, :invalid_browser_command} =
             SafeCommand.parse("chromium --headless https://example.com; cat secrets")
  end
end
