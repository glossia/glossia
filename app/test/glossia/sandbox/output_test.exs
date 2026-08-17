defmodule Glossia.Sandbox.OutputTest do
  use ExUnit.Case, async: true

  alias Glossia.Sandbox.Output

  test "truncates command output at a valid Unicode boundary" do
    assert Output.truncate("a😀b", 4) == "a"
    assert Output.truncate("a😀b", 5) == "a😀"
    assert String.valid?(Output.truncate("a😀b", 4))
  end
end
