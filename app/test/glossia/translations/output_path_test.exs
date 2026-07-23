defmodule Glossia.Translations.OutputPathTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Format
  alias Glossia.Translations.OutputPath

  describe "Format.detect/1" do
    test "maps extensions to formats (case-insensitive), mirroring the CLI" do
      assert Format.detect("docs/guide.md") == "markdown"
      assert Format.detect("readme.markdown") == "markdown"
      assert Format.detect("data.json") == "json"
      assert Format.detect("config.yaml") == "yaml"
      assert Format.detect("messages.po") == "po"
      assert Format.detect("notes.txt") == "text"
      assert Format.detect("file.POT") == "po"
      assert Format.detect("file.YML") == "yaml"
    end

    test "distinguishes built-in paths from custom extensions" do
      assert Format.supported_path?("notes.txt")
      assert Format.supported_path?("guide.MARKDOWN")
      refute Format.supported_path?("guide.custom")
    end

    test "structured?/1 classifies json/yaml/po as structured" do
      for f <- ~w(json yaml po), do: assert(Format.structured?(f))
      for f <- ~w(markdown text), do: refute(Format.structured?(f))
    end
  end

  describe "OutputPath.expand_output/2" do
    test "expands placeholders" do
      got =
        OutputPath.expand_output("i18n/{lang}/{relpath}", %{
          lang: "es",
          locale: "es",
          relpath: "docs/guide.md",
          basename: "guide",
          ext: "md"
        })

      assert got == "i18n/es/docs/guide.md"
    end

    test "normalizes backslashes and collapses slashes" do
      got =
        OutputPath.expand_output("out\\{lang}\\{basename}.{ext}", %{
          lang: "de",
          locale: "de",
          relpath: "docs\\guide.md",
          basename: "guide",
          ext: "md"
        })

      assert got == "out/de/guide.md"
    end
  end

  describe "OutputPath.build_output_path/6" do
    test "uses a glob mapping template relative to the match base" do
      assert {:ok, "docs/i18n/es/guide.md"} =
               OutputPath.build_output_path(
                 "docs/i18n/{locale}/*.md",
                 nil,
                 nil,
                 "es",
                 "guide.md",
                 "guide.md"
               )
    end

    test "appends the default output file for directory targets (pot -> po)" do
      assert {:ok, "priv/gettext/es/LC_MESSAGES/errors.po"} =
               OutputPath.build_output_path(
                 "priv/gettext/{locale}/LC_MESSAGES",
                 nil,
                 nil,
                 "es",
                 "errors.pot",
                 "errors.pot"
               )
    end

    test "falls back to the target_path template, preserving the source parent" do
      assert {:ok, "docs/i18n/de/nested/guide.md"} =
               OutputPath.build_output_path(
                 nil,
                 nil,
                 "docs/i18n/{locale}",
                 "de",
                 "nested/guide.md",
                 "nested/guide.md"
               )
    end

    test "errors when no template is available" do
      assert {:error, _} =
               OutputPath.build_output_path(nil, nil, nil, "es", "guide.md", "guide.md")
    end
  end
end
