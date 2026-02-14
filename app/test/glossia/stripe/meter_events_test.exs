defmodule Glossia.Stripe.MeterEventsTest do
  use ExUnit.Case, async: true

  alias Glossia.Stripe.MeterEvents

  test "build_params/4 builds the expected payload" do
    params =
      MeterEvents.build_params("glossia_usage_credits", "cus_123", 25,
        identifier: "evt_1",
        timestamp: 1_700_000_000
      )

    assert params == %{
             event_name: "glossia_usage_credits",
             identifier: "evt_1",
             timestamp: 1_700_000_000,
             payload: %{
               stripe_customer_id: "cus_123",
               value: 25
             }
           }
  end
end

