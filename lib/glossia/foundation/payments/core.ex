defmodule Glossia.Foundation.Payments.Core do
  use Boundary,
    exports: [Billing, Customers, Subscriptions],
    deps: [Glossia.Foundation.Utilities.Core]
end
