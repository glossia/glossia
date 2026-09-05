defmodule Glossia.Analytics.VerificationTest do
  use ExUnit.Case, async: true

  import Mimic

  alias Glossia.Analytics.Verification

  setup :verify_on_exit!

  describe "check_dns/2" do
    test "returns :ok when the TXT record carries the expected token" do
      token = unique_token()

      expect(MuonTrap, :cmd, fn "dig", ["+short", "TXT", "_glossia-verify.example.com"], _opts ->
        {~s("glossia-site-verification=#{token}" <> "\n"), 0}
      end)

      assert Verification.check_dns("example.com", token) == :ok
    end

    test "ignores unrelated TXT records on the same subdomain" do
      token = unique_token()

      expect(MuonTrap, :cmd, fn "dig", ["+short", "TXT", "_glossia-verify.example.com"], _opts ->
        {~s("v=spf1 -all"\n"unrelated=value"\n), 0}
      end)

      assert Verification.check_dns("example.com", token) == :error
    end

    test "returns :error when dig exits non-zero" do
      expect(MuonTrap, :cmd, fn "dig", ["+short", "TXT", "_glossia-verify.example.com"], _opts ->
        {"", 9}
      end)

      assert Verification.check_dns("example.com", unique_token()) == :error
    end
  end

  describe "check_meta_tag/2" do
    test "returns :ok when the meta tag is present" do
      token = unique_token()

      body =
        ~s(<html><head><meta name="glossia-site-verification" content="#{token}"></head></html>)

      stub(Req, :get, fn _url, _opts ->
        {:ok, %{status: 200, body: body}}
      end)

      assert Verification.check_meta_tag("example.com", token) == :ok
    end

    test "matches the meta tag regardless of attribute order" do
      token = unique_token()
      body = ~s(<head><meta content="#{token}" name="glossia-site-verification"></head>)

      stub(Req, :get, fn _url, _opts -> {:ok, %{status: 200, body: body}} end)

      assert Verification.check_meta_tag("example.com", token) == :ok
    end

    test "returns :error when the tag carries a different token" do
      body = ~s(<meta name="glossia-site-verification" content="not-our-token">)

      stub(Req, :get, fn _url, _opts -> {:ok, %{status: 200, body: body}} end)

      assert Verification.check_meta_tag("example.com", unique_token()) == :error
    end

    test "returns :error when the request fails" do
      stub(Req, :get, fn _url, _opts -> {:error, %Req.TransportError{reason: :closed}} end)

      assert Verification.check_meta_tag("example.com", unique_token()) == :error
    end
  end

  describe "verify/2" do
    test "passes when only the DNS check confirms ownership" do
      token = unique_token()

      expect(MuonTrap, :cmd, fn "dig", ["+short", "TXT", "_glossia-verify.example.com"], _opts ->
        {~s("glossia-site-verification=#{token}" <> "\n"), 0}
      end)

      stub(Req, :get, fn _url, _opts -> {:error, %Req.TransportError{reason: :closed}} end)

      assert Verification.verify("example.com", token) == :ok
    end

    test "passes when only the meta tag confirms ownership" do
      token = unique_token()
      body = ~s(<meta name="glossia-site-verification" content="#{token}">)

      expect(MuonTrap, :cmd, fn "dig", ["+short", "TXT", "_glossia-verify.example.com"], _opts ->
        {"", 9}
      end)

      stub(Req, :get, fn _url, _opts -> {:ok, %{status: 200, body: body}} end)

      assert Verification.verify("example.com", token) == :ok
    end

    test "fails when neither check confirms ownership" do
      expect(MuonTrap, :cmd, fn _cmd, _args, _opts -> {"", 9} end)
      stub(Req, :get, fn _url, _opts -> {:ok, %{status: 200, body: "<html></html>"}} end)

      assert Verification.verify("example.com", unique_token()) == :error
    end
  end

  defp unique_token, do: "tok-" <> Integer.to_string(System.unique_integer([:positive]))
end
