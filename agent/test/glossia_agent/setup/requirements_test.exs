defmodule GlossiaAgent.Setup.RequirementsTest do
  use ExUnit.Case, async: true

  alias GlossiaAgent.Setup.Requirements

  test "passes when required framework sources are present" do
    glossia_md = """
    +++
    [[content]]
    source = "priv/gettext/**/*.po"
    targets = ["es"]
    output = "priv/gettext/{lang}/{relpath}"
    +++
    """

    hints = [
      %{
        framework: "phoenix",
        summary: "Phoenix gettext",
        required_sources: ["priv/gettext/**/*.po"]
      }
    ]

    assert :ok = Requirements.validate_glossia(glossia_md, hints)
  end

  test "fails when required framework sources are missing" do
    glossia_md = """
    +++
    [[content]]
    source = "docs/**/*.md"
    targets = ["es"]
    output = "docs/i18n/{lang}/{relpath}"
    +++
    """

    hints = [
      %{
        framework: "phoenix",
        summary: "Phoenix gettext",
        required_sources: ["priv/gettext/**/*.po"]
      }
    ]

    assert {:error, reason} = Requirements.validate_glossia(glossia_md, hints)
    assert String.contains?(reason, "priv/gettext/**/*.po")
  end
end
