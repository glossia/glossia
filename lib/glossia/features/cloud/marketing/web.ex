defmodule Glossia.Features.Cloud.Marketing.Web do
  use Boundary,
    deps: [Glossia.Features.Cloud.Marketing.Core, Glossia.Foundation.Application.Core],
    exports: [Controllers.MarketingController]
end
