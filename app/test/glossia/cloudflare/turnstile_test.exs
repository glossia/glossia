defmodule Glossia.Cloudflare.TurnstileTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Cloudflare.Turnstile

  describe "verify/2" do
    test "short-circuits with :ok when Turnstile is not required" do
      # `required?: false` should skip both the secret lookup and the HTTP
      # call — the test injects a request stub that flunks if it is ever
      # invoked.
      request = fn _url, _opts -> flunk("HTTP request should not run") end

      assert :ok = Turnstile.verify("any-token", required?: false, request: request)
    end

    test "returns :missing_token when no token is provided" do
      request = fn _url, _opts -> flunk("HTTP request should not run") end

      assert {:error, :missing_token} =
               Turnstile.verify(nil,
                 required?: true,
                 secret_key: "secret",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "returns :misconfigured when the secret key is missing" do
      request = fn _url, _opts -> flunk("HTTP request should not run") end

      assert {:error, :misconfigured} =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "returns :ok when Cloudflare accepts the token" do
      request = fn _url,
                   [
                     form: %{secret: "secret", response: "token"},
                     connect_options: _,
                     receive_timeout: _
                   ] ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"success" => true, "action" => "signup", "hostname" => "glossia.ai"}
         }}
      end

      assert :ok =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "secret",
                 expected_action: "signup",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "returns :rejected on action mismatch" do
      request = fn _url, _opts ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"success" => true, "action" => "other", "hostname" => "glossia.ai"}
         }}
      end

      assert {:error, :rejected} =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "secret",
                 expected_action: "signup",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "returns :rejected on hostname mismatch" do
      request = fn _url, _opts ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"success" => true, "hostname" => "impostor.example"}
         }}
      end

      assert {:error, :rejected} =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "secret",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "returns :rejected on Cloudflare success:false" do
      request = fn _url, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"success" => false}}}
      end

      assert {:error, :rejected} =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "secret",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "fails closed with :unavailable on non-200 status" do
      request = fn _url, _opts -> {:ok, %Req.Response{status: 500, body: ""}} end

      assert {:error, :unavailable} =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "secret",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end

    test "fails closed with :unavailable on network error" do
      request = fn _url, _opts -> {:error, %Req.TransportError{reason: :timeout}} end

      assert {:error, :unavailable} =
               Turnstile.verify("token",
                 required?: true,
                 secret_key: "secret",
                 expected_hostname: "glossia.ai",
                 request: request
               )
    end
  end
end
