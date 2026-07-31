defmodule Glossia.Analytics.IdentityTest do
  use ExUnit.Case, async: true

  alias Glossia.Analytics.Identity

  @ip "203.0.113.10"
  @ua "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/120.0"
  @project "11111111-1111-1111-1111-111111111111"
  @date ~D[2026-07-31]

  test "is a stable unsigned 64-bit integer for the same inputs and day" do
    id = Identity.visitor_id(@ip, @ua, @project, @date)

    assert is_integer(id)
    assert id >= 0
    assert id < Bitwise.bsl(1, 64)
    assert id == Identity.visitor_id(@ip, @ua, @project, @date)
  end

  test "rotates daily so the same visitor is unlinkable across days" do
    today = Identity.visitor_id(@ip, @ua, @project, @date)
    tomorrow = Identity.visitor_id(@ip, @ua, @project, Date.add(@date, 1))

    refute today == tomorrow
  end

  test "is scoped per project" do
    a = Identity.visitor_id(@ip, @ua, @project, @date)
    b = Identity.visitor_id(@ip, @ua, "22222222-2222-2222-2222-222222222222", @date)

    refute a == b
  end

  test "changes with the IP and the user agent" do
    base = Identity.visitor_id(@ip, @ua, @project, @date)

    refute base == Identity.visitor_id("198.51.100.7", @ua, @project, @date)
    refute base == Identity.visitor_id(@ip, "a different agent", @project, @date)
  end
end
