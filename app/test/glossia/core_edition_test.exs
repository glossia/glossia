defmodule Glossia.CoreEditionTest do
  use ExUnit.Case, async: true

  test "core builds have no enterprise audit modules or children" do
    if System.get_env("GLOSSIA_EDITION", "core") == "core" do
      assert Application.get_env(:glossia, :audit_extension) == nil
      assert Glossia.Extensions.audit_children() == []
      refute Code.ensure_loaded?(GlossiaEnterprise.Audit)
      refute Code.ensure_loaded?(GlossiaEnterprise.Audit.Event)
    end
  end

  test "the core retains a usable no-op domain-event handler" do
    assert :ok = Glossia.Events.NoopHandler.handle_event(nil)
  end
end
