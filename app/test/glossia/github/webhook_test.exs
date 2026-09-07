defmodule Glossia.Github.WebhookTest do
  use ExUnit.Case, async: true

  alias Glossia.Github.Webhook

  @secret "test_github_webhook_secret"
  @payload ~s({"action":"opened","number":1})

  defp sign(secret, payload) do
    digest =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    "sha256=#{digest}"
  end

  describe "verify/3" do
    test "accepts a valid HMAC-SHA256 signature" do
      signature = sign(@secret, @payload)
      headers = [{"x-hub-signature-256", signature}]

      assert :ok = Webhook.verify(headers, @payload, @secret)
    end

    test "rejects an invalid signature" do
      headers = [{"x-hub-signature-256", "sha256=bad"}]

      assert {:error, :invalid_signature} = Webhook.verify(headers, @payload, @secret)
    end

    test "rejects when signature header is missing" do
      assert {:error, :missing_signature} = Webhook.verify([], @payload, @secret)
    end

    test "rejects when secret is nil" do
      headers = [{"x-hub-signature-256", sign(@secret, @payload)}]

      assert {:error, :missing_secret} = Webhook.verify(headers, @payload, nil)
    end

    test "rejects when secret is empty" do
      headers = [{"x-hub-signature-256", sign(@secret, @payload)}]

      assert {:error, :missing_secret} = Webhook.verify(headers, @payload, "")
    end
  end
end
