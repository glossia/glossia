defmodule GlossiaWeb.ChangelogHTML do
  use GlossiaWeb, :html

  embed_templates "changelog_html/*"

  def format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end
end
