defmodule GlossiaWeb.LegalHTML do
  use GlossiaWeb, :html

  embed_templates "legal_html/*"

  def format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end

  def document_title(document) do
    case document do
      "terms" -> gettext("Terms of Service")
      "privacy" -> gettext("Privacy Policy")
      "cookies" -> gettext("Cookie Policy")
      "acceptable-use" -> gettext("Acceptable Use")
      "imprint" -> gettext("Legal Notice")
    end
  end

  def document_path(document) do
    case document do
      "terms" -> locale_path(~p"/terms")
      "privacy" -> locale_path(~p"/privacy")
      "cookies" -> locale_path(~p"/cookies")
      "acceptable-use" -> locale_path(~p"/acceptable-use")
      "imprint" -> locale_path(~p"/imprint")
    end
  end

  def version_path(document, date) do
    date = Date.to_iso8601(date)

    case document do
      "terms" -> locale_path(~p"/terms/#{date}")
      "privacy" -> locale_path(~p"/privacy/#{date}")
      "cookies" -> locale_path(~p"/cookies/#{date}")
      "acceptable-use" -> locale_path(~p"/acceptable-use/#{date}")
      "imprint" -> locale_path(~p"/imprint/#{date}")
    end
  end
end
