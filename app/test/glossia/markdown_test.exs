defmodule Glossia.MarkdownTest do
  use ExUnit.Case, async: true

  test "renders tables and language classes" do
    markdown = """
    | Name |
    | ---- |
    | Glossia |

    ```elixir
    :ok
    ```
    """

    assert {:ok, html} = Glossia.Markdown.to_html(markdown)
    assert html =~ "<table>"
    assert html =~ ~s(<code class="language-elixir">)
  end

  test "sanitizes unsafe html by default" do
    assert {:ok, html} = Glossia.Markdown.to_html("<script>alert('x')</script>\n\nSafe")

    refute html =~ "<script"
    assert html =~ "Safe"
  end

  test "supports hard line breaks for legal pages" do
    assert {:ok, html} = Glossia.Markdown.to_html("One\nTwo", breaks: true)

    assert html =~ "One<br />\nTwo"
  end

  test "keeps admonitions compatible with marketing post-processing" do
    html =
      "> [!NOTE]\n> Hello"
      |> Glossia.Markdown.to_html!()
      |> Glossia.MarketingMarkdown.process()
      |> elem(0)

    assert html =~ ~s(<div class="admonition admonition-note">)
    assert html =~ "Hello"
  end
end
