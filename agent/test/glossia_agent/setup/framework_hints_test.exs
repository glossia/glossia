defmodule GlossiaAgent.Setup.FrameworkHintsTest do
  use ExUnit.Case, async: true

  alias GlossiaAgent.Setup.FrameworkHints

  test "detects phoenix and gettext requirements" do
    tree = [
      "mix.exs",
      "lib/demo_web/router.ex",
      "priv/gettext/en/LC_MESSAGES/default.po"
    ]

    key_files = %{
      "mix.exs" => """
      defmodule Demo.MixProject do
        def project, do: []
        defp deps, do: [{:phoenix, "~> 1.8"}]
      end
      """
    }

    hints = FrameworkHints.detect(tree, key_files)

    assert [
             %{
               framework: "phoenix",
               required_sources: ["priv/gettext/**/*.po"]
             }
           ] = hints
  end

  test "returns no hints for non-phoenix repositories" do
    tree = ["README.md", "docs/index.md"]
    key_files = %{"README.md" => "# Docs"}

    assert [] = FrameworkHints.detect(tree, key_files)
  end
end
