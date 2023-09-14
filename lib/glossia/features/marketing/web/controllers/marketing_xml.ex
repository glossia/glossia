defmodule Glossia.Features.Marketing.Web.Controllers.MarketingXML do
  use Glossia.Foundation.Application.Web.Helpers.Shared, :verified_routes
  use Phoenix.Component

  embed_templates "marketing_xml/*"

  use Timex

  def to_rfc3339(date) do
    date
    |> Timezone.convert("GMT")
    |> Timex.format!("{RFC3339}")
  end
end
