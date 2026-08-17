defmodule Glossia.Quality.DOMTest do
  use ExUnit.Case, async: true

  alias Glossia.Quality.DOM

  test "extracts language, visible text, and absolute alternate links" do
    html = """
    Chromium startup noise
    <!DOCTYPE html>
    <html lang='es-MX'>
      <head>
        <title>Cuenta &amp; perfil</title>
        <link rel="alternate" hreflang="en" href="/account" />
        <link rel="alternate" hreflang="PT_BR" href="/pt-br/account" />
      </head>
      <body>
        <h1>Tu cuenta</h1>
        <script>secret()</script>
        <p>Administra tu perfil.</p>
        <a hreflang=fr href=https://example.com/fr/account>Français</a>
      </body>
    </html>
    Chromium shutdown noise
    """

    parsed = DOM.parse(html, "https://example.com/es/account")

    assert parsed.title == "Cuenta & perfil"
    assert parsed.document_locale == "es-mx"
    assert parsed.visible_text =~ "Tu cuenta"
    assert parsed.visible_text =~ "Administra tu perfil."
    refute parsed.visible_text =~ "secret"
    refute parsed.visible_text =~ "Cuenta & perfil"
    refute parsed.visible_text =~ "shutdown noise"
    assert parsed.alternate_links["en"] == "https://example.com/account"
    assert parsed.alternate_links["fr"] == "https://example.com/fr/account"
    assert parsed.alternate_links["pt-br"] == "https://example.com/pt-br/account"
    assert byte_size(parsed.content_hash) == 64
  end

  test "splits normalized visible text into stable blocks" do
    assert DOM.text_blocks(" First   block \n\nSecond block\nFirst block ") == [
             "First block",
             "Second block"
           ]
  end

  test "truncates large documents on a valid Unicode boundary" do
    parsed =
      DOM.parse(
        "<html><body>#{String.duplicate("á", 100_001)}</body></html>",
        "https://example.com"
      )

    assert String.valid?(parsed.visible_text)
    assert byte_size(parsed.visible_text) <= 200_000
  end
end
