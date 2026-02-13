defmodule GlossiaWeb.LegalHTML do
  use GlossiaWeb, :html

  embed_templates "legal_html/*"

  def format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end

  def document_path(document) do
    case document do
      "terms" -> "/terms"
      "privacy" -> "/privacy"
      "cookies" -> "/cookies"
    end
  end
end
