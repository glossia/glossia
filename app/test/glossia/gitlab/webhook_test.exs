defmodule Glossia.Gitlab.WebhookTest do
  use ExUnit.Case, async: true

  alias Glossia.Gitlab.Webhook

  @secret "test_gitlab_webhook_secret"
  @payload ~s({"object_kind":"push"})

  describe "verify/3" do
    test "accepts a valid token" do
      headers = [{"x-gitlab-token", @secret}]

      assert :ok = Webhook.verify(headers, @payload, @secret)
    end

    test "rejects an invalid token" do
      headers = [{"x-gitlab-token", "wrong_token"}]

      assert {:error, :invalid_token} = Webhook.verify(headers, @payload, @secret)
    end

    test "rejects when token header is missing" do
      assert {:error, :missing_token} = Webhook.verify([], @payload, @secret)
    end

    test "rejects when secret is nil" do
      headers = [{"x-gitlab-token", @secret}]

      assert {:error, :missing_secret} = Webhook.verify(headers, @payload, nil)
    end

    test "rejects when secret is empty" do
      headers = [{"x-gitlab-token", @secret}]

      assert {:error, :missing_secret} = Webhook.verify(headers, @payload, "")
    end
  end
end
