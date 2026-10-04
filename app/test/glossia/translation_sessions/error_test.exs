defmodule Glossia.TranslationSessions.ErrorTest do
  use ExUnit.Case, async: true

  alias Glossia.TranslationSessions.Error

  @sources_error "sources must be a mapping of source patterns to target path templates"

  test "explains how to fix a sources list" do
    message = Error.describe({:planning_failed, @sources_error})

    assert message =~ "L10N.md"
    assert message =~ "define sources as a mapping"
    assert message =~ "then retry"
    refute message =~ "planning_failed"
  end

  test "unknown planning failures do not expose repository output" do
    message = Error.describe({:planning_failed, "private repository content"})

    assert message =~ "locale overlays"
    refute message =~ "private repository content"
  end

  test "unknown failures do not expose internal terms or secrets" do
    message = Error.describe({:clone_failed, "secret-token"})

    assert message =~ "session ID"
    refute message =~ "secret-token"
    refute message =~ "clone_failed"
  end

  test "normalizes the legacy planning error without evaluating stored terms" do
    legacy = "Translation failed: #{inspect({:planning_failed, @sources_error})}"

    assert Error.display(legacy) == Error.describe({:planning_failed, @sources_error})

    assert Error.display("Translation failed: {:planning_failed, \"private content\"}") ==
             Error.describe({:planning_failed, nil})

    assert Error.display("Translation failed: {:clone_failed, \"secret-token\"}") ==
             Error.describe(nil)
  end

  test "preserves already humanized errors" do
    message = "The model provider rejected the configured credentials. Check them and retry."
    assert Error.display(message) == message
  end
end
