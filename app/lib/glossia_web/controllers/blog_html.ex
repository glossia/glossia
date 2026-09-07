defmodule GlossiaWeb.BlogHTML do
  use GlossiaWeb, :html

  embed_templates "blog_html/*"

  def format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end
end
