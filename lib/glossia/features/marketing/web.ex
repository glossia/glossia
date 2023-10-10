defmodule Glossia.Features.Marketing.Web do
  use Boundary,
    deps: [Glossia.Features.Marketing.Core, Glossia.Foundation.Application.Core],
    exports: [Controllers.MarketingController]
end
