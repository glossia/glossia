defmodule GlossiaWeb.HomeXML do
  use GlossiaWeb, :xml

  embed_templates "home_xml/*"

  use Timex

  def to_rfc3339(date) do
    date
    |> Timezone.convert("GMT")
    |> Timex.format!("{RFC3339}")
  end
end
