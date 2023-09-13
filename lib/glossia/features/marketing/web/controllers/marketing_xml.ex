defmodule Glossia.Features.Marketing.Web.Controllers.MarketingXML do
  use Glossia.Foundation.Application.Web, :xml

  embed_templates "marketing_xml/*"

  use Timex

  def to_rfc3339(date) do
    date
    |> Timezone.convert("GMT")
    |> Timex.format!("{RFC3339}")
  end
end
