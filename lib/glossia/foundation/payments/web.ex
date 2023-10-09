defmodule Glossia.Foundation.Payments.Web do
  use Boundary, exports: [Controllers.StripeWebhooksController]
end
