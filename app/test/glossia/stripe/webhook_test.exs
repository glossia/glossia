defmodule Glossia.Stripe.WebhookTest do
  use ExUnit.Case, async: true

  alias Glossia.Stripe.Webhook

  test "verifies a valid Stripe-Signature header" do
    secret = "whsec_test_secret"
    payload = ~s({"id":"evt_123","type":"ping"})
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    signature = expected_signature(secret, timestamp, payload)
    header = "t=#{timestamp},v1=#{signature}"

    assert :ok = Webhook.verify([{"stripe-signature", header}], payload, secret)
  end

  test "rejects an invalid signature" do
    secret = "whsec_test_secret"
    payload = ~s({"id":"evt_123","type":"ping"})
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    header = "t=#{timestamp},v1=deadbeef"

    assert {:error, :invalid_signature} =
             Webhook.verify([{"stripe-signature", header}], payload, secret)
  end

  test "rejects a timestamp outside tolerance" do
    secret = "whsec_test_secret"
    payload = ~s({"id":"evt_123","type":"ping"})
    timestamp = (DateTime.utc_now() |> DateTime.to_unix()) - 10_000

    signature = expected_signature(secret, timestamp, payload)
    header = "t=#{timestamp},v1=#{signature}"

    assert {:error, :timestamp_out_of_tolerance} =
             Webhook.verify([{"stripe-signature", header}], payload, secret, tolerance_sec: 5)
  end

  defp expected_signature(secret, timestamp, payload) do
    message = "#{timestamp}.#{payload}"

    :crypto.mac(:hmac, :sha256, secret, message)
    |> Base.encode16(case: :lower)
  end
end
