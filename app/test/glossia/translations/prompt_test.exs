defmodule Glossia.Translations.PromptTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Prompt

  defp base(overrides) do
    Map.merge(
      %{
        format: "markdown",
        source_language: "English",
        language: "Spanish",
        locale: "es"
      },
      overrides
    )
  end

  describe "build_system_prompt/1 for prose formats" do
    test "emits the localization-engine preamble" do
      prompt = Prompt.build_system_prompt(base(%{}))

      assert prompt ==
               """
               You are a professional localization engine.
               Translate the content from English to Spanish (es).
               Preserve code blocks, inline code, URLs, placeholders, lists, and headings.
               Copy every Glossia protected token marker byte-for-byte exactly once.
               Return only the translated content. Do not add commentary or markdown fences.
               Preserve the Markdown document structure exactly: retain every heading, block quote, list item, paragraph, and their order.
               Do not combine, split, omit, or add Markdown blocks, even when making the translated prose read naturally.\
               """
    end

    test "adds a structured-output rule for json/yaml" do
      assert Prompt.build_system_prompt(base(%{format: "json"})) =~
               "Return valid json only. Do not wrap the output in markdown fences."

      assert Prompt.build_system_prompt(base(%{format: "yaml"})) =~
               "Return valid yaml only. Do not wrap the output in markdown fences."
    end

    test "does not add a structured-output rule for text/markdown" do
      refute Prompt.build_system_prompt(base(%{format: "text"})) =~ "Return valid"
      refute Prompt.build_system_prompt(base(%{format: "markdown"})) =~ "Return valid"
    end

    test "notes preserved frontmatter only when requested" do
      assert Prompt.build_system_prompt(base(%{frontmatter_preserved: true})) =~
               "Frontmatter is preserved separately. Do not add new frontmatter."

      refute Prompt.build_system_prompt(base(%{frontmatter_preserved: false})) =~
               "Frontmatter is preserved separately"
    end

    test "requires complete non-empty metadata blocks" do
      prompt = Prompt.build_system_prompt(base(%{segment_kind: "frontmatter"}))

      assert prompt =~ "Return the complete block, including every delimiter"
      assert prompt =~ "Never return an empty response for a non-empty metadata block."
    end

    test "requires exact Markdown text recovery markers" do
      prompt = Prompt.build_system_prompt(base(%{segment_kind: "markdown_text_markers"}))

      assert prompt =~ "@@GLOSSIA-TEXT-<number>-START@@"
      assert prompt =~ "Copy every marker byte-for-byte exactly once"
    end

    test "appends a non-blank custom prompt, trimmed" do
      prompt = Prompt.build_system_prompt(base(%{custom_prompt: "  Use the formal register.  "}))
      assert prompt =~ "\nUse the formal register."
      refute Prompt.build_system_prompt(base(%{custom_prompt: "   "})) =~ "register"
    end

    test "appends project context and locale-override blocks" do
      prompt =
        Prompt.build_system_prompt(
          base(%{context_body: "Brand voice is warm.", locale_override_body: "Prefer vosotros."})
        )

      assert prompt =~ "\n\nProject context:\nBrand voice is warm."
      assert prompt =~ "\n\nLocale-specific instructions for Spanish:\nPrefer vosotros."
    end

    test "appends resolved organization context" do
      prompt =
        Prompt.build_system_prompt(
          base(%{server_context_body: "Required terminology:\n- Account → Cuenta"})
        )

      assert prompt =~
               "\n\nOrganization context for Spanish:\nRequired terminology:\n- Account → Cuenta"
    end

    test "omits empty context blocks" do
      prompt = Prompt.build_system_prompt(base(%{context_body: "   ", locale_override_body: ""}))
      refute prompt =~ "Project context:"
      refute prompt =~ "Locale-specific instructions"
    end
  end

  describe "build_system_prompt/1 for PO" do
    test "emits the gettext ruleset with the locale plural forms" do
      prompt = Prompt.build_system_prompt(base(%{format: "po"}))

      assert prompt =~ "You are a professional translator specializing in software localization."
      assert prompt =~ "You translate Gettext PO template files from English to Spanish (es)."
      assert prompt =~ "1. The first entry must be the PO header."
      assert prompt =~ "2. The header must include Language: es."
      assert prompt =~ "4. The header must include Plural-Forms: nplurals=2; plural=n != 1;."
      assert prompt =~ "10. Keep each msgstr on a single line"
    end

    test "uses the correct plural-forms table per locale" do
      assert Prompt.build_system_prompt(base(%{format: "po", locale: "ja"})) =~
               "Plural-Forms: nplurals=1; plural=0;"

      assert Prompt.build_system_prompt(base(%{format: "po", locale: "ru"})) =~
               "Plural-Forms: nplurals=3; plural=n%10==1"

      assert Prompt.build_system_prompt(base(%{format: "po", locale: "de"})) =~
               "Plural-Forms: nplurals=2; plural=n != 1;"
    end

    test "still appends context/locale-override blocks" do
      prompt =
        Prompt.build_system_prompt(base(%{format: "po", context_body: "Keep it concise."}))

      assert prompt =~ "\n\nProject context:\nKeep it concise."
    end

    test "appends resolved organization context" do
      prompt =
        Prompt.build_system_prompt(
          base(%{format: "po", server_context_body: "Organization voice:\n- Formality: formal"})
        )

      assert prompt =~
               "\n\nOrganization context for Spanish:\nOrganization voice:\n- Formality: formal"
    end

    test "scopes rules to the supplied catalog segment" do
      first =
        Prompt.build_system_prompt(base(%{format: "po", segment_index: 1, segment_count: 3}))

      assert first =~ "segment 1 of 3"
      assert first =~ "Preserve every supplied entry and its order"
      assert first =~ "This segment contains the PO header"

      later =
        Prompt.build_system_prompt(base(%{format: "po", segment_index: 2, segment_count: 3}))

      assert later =~ "segment 2 of 3"
      assert later =~ "Do not add a PO header"
      refute later =~ "This segment contains the PO header"
    end
  end

  describe "build_user_prompt/5" do
    test "carries the source content" do
      prompt = Prompt.build_user_prompt("English", "es", "Spanish", "Hello, world.")

      assert prompt ==
               """
               Translate the following content from English to Spanish (es).

               Hello, world.\
               """
    end

    test "appends the previous validation error on retry" do
      prompt =
        Prompt.build_user_prompt("English", "es", "Spanish", "Hello.", "invalid YAML at line 2")

      assert prompt =~
               "\n\nThe reassembled document previously failed validation: invalid YAML at line 2"

      assert prompt =~ "Return a corrected translation of only this supplied segment."
    end

    test "adds Markdown structure repair guidance after a structure validation error" do
      prompt =
        Prompt.build_user_prompt(
          "English",
          "de",
          "German",
          "## Heading\n\nParagraph.",
          "translated Markdown changed the document structure at document.1"
        )

      assert prompt =~ "Do not alter the Markdown structure."
      assert prompt =~ "Keep every heading, block quote, list item, paragraph, and its order"
    end

    test "ignores a blank previous error" do
      refute Prompt.build_user_prompt("English", "es", "Spanish", "Hello.", "  ") =~
               "reassembled document previously failed validation"
    end

    test "identifies bounded document segments" do
      prompt =
        Prompt.build_user_prompt(
          "English",
          "es",
          "Spanish",
          "Hello.",
          nil,
          %{kind: "content", index: 2, count: 3}
        )

      assert prompt =~ "Translate segment 2 of 3"
      assert prompt =~ "Return only this segment."
    end

    test "limits frontmatter translation to human-readable values" do
      prompt =
        Prompt.build_user_prompt(
          "English",
          "es",
          "Spanish",
          ~s(%{title: "Hello"}),
          nil,
          %{kind: "frontmatter", index: 1, count: 2}
        )

      assert prompt =~ "Translate only the human-readable string values"
      assert prompt =~ "Return the complete frontmatter block."
      assert prompt =~ "Preserve its syntax, keys, identifiers, dates, and delimiters exactly."
      assert prompt =~ "Do not return an empty response."
    end

    test "limits Markdown marker recovery to delimited prose" do
      prompt =
        Prompt.build_user_prompt(
          "English",
          "es",
          "Spanish",
          "@@GLOSSIA-TEXT-1-START@@Hello@@GLOSSIA-TEXT-1-END@@",
          nil,
          %{kind: "markdown_text_markers", index: 1, count: 1}
        )

      assert prompt =~ "Translate only the prose between matching @@GLOSSIA-TEXT-<number>-START@@"
      assert prompt =~ "Return every marker exactly once."
    end
  end
end
