defmodule Glossia.Web.MarketingXML do
  use Glossia.Web, :xml

  embed_templates "marketing_xml/*"

  use Timex

  def to_rfc3339(date) do
    date
    |> Timezone.convert("GMT")
    |> Timex.format!("{RFC3339}")
  end
end