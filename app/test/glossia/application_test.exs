defmodule Glossia.ApplicationTest do
  use ExUnit.Case, async: true

  test "includes FunWithFlags in the release" do
    assert :fun_with_flags in Application.spec(:glossia, :included_applications)
  end
end
