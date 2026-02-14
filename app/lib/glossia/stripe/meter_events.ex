defmodule Glossia.Stripe.MeterEvents do
  @moduledoc false

  alias Stripe.Request

  @endpoint "/v1/billing/meter_events"

  def create(event_name, customer_id, value, opts \\ [])
      when is_binary(event_name) and event_name != "" and is_binary(customer_id) and customer_id != "" and
             is_integer(value) and value > 0 do
    params = build_params(event_name, customer_id, value, opts)

    # stripity_stripe doesn't currently ship a generated client for meter events,
    # but its Request module supports custom endpoints.
    Request.new_request(opts)
    |> Request.put_endpoint(@endpoint)
    |> Request.put_method(:post)
    |> Request.put_params(params)
    |> Request.make_request()
  end

  def build_params(event_name, customer_id, value, opts \\ [])
      when is_binary(event_name) and is_binary(customer_id) and is_integer(value) do
    identifier = Keyword.get(opts, :identifier)
    timestamp = Keyword.get(opts, :timestamp)

    base = %{
      event_name: event_name,
      payload: %{
        stripe_customer_id: customer_id,
        value: value
      }
    }

    base
    |> maybe_put(:identifier, identifier)
    |> maybe_put(:timestamp, timestamp)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end

