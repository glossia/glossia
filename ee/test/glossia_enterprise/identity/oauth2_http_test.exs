defmodule GlossiaEnterprise.Identity.OAuth2HTTPTest do
  use ExUnit.Case, async: true
  use Mimic
  alias GlossiaEnterprise.Identity.OAuth2HTTP

  test "rejects unsafe schemes, credentials, ports and non-public IPv4 and IPv6 answers" do
    for url <- [
          "http://id.example.com/token",
          "https://user:pass@id.example.com",
          "https://id.example.com:8443/token",
          "https://id.example.com/token?foo=1",
          "https://id.example.com/token#foo",
          "https://id.example.com:not-a-port/token",
          "https://id.example.com/bad path"
        ] do
      refute OAuth2HTTP.valid_url?(url)

      assert {:error, :invalid_url} =
               OAuth2HTTP.pin(url, fn _, _ -> flunk("must not resolve") end)
    end

    for address <- [
          {127, 0, 0, 1},
          {10, 0, 0, 1},
          {100, 64, 0, 1},
          {169, 254, 169, 254},
          {172, 16, 0, 1},
          {192, 168, 0, 1},
          {198, 18, 0, 1},
          {203, 0, 113, 1},
          {0, 0, 0, 0, 0, 0, 0, 1},
          {0, 0, 0, 0, 0, 0xFFFF, 0x7F00, 1},
          {0xFC00, 0, 0, 0, 0, 0, 0, 1},
          {0x2001, 0xDB8, 0, 0, 0, 0, 0, 1},
          {0x2002, 0x7F00, 1, 0, 0, 0, 0, 1}
        ] do
      assert {:error, :non_public_endpoint} =
               OAuth2HTTP.pin("https://id.example.com/token", fn _, _ -> {:ok, [address]} end)
    end

    assert {:error, :non_public_endpoint} =
             OAuth2HTTP.pin("https://id.example.com/token", fn
               _, :inet -> {:ok, [{8, 8, 8, 8}]}
               _, :inet6 -> {:ok, [{0, 0, 0, 0, 0, 0, 0, 1}]}
             end)
  end

  test "pins both IP families while preserving the original hostname for TLS" do
    for {family, ip, pinned} <- [
          {:inet, {8, 8, 8, 8}, "https://8.8.8.8/token"},
          {:inet6, {0x2606, 0x4700, 0x4700, 0, 0, 0, 0, 0x1111},
           "https://[2606:4700:4700::1111]/token"}
        ] do
      resolver = fn
        _, ^family -> {:ok, [ip]}
        _, _ -> {:error, :nxdomain}
      end

      assert {:ok, ^pinned, "id.example.com"} =
               OAuth2HTTP.pin("https://id.example.com/token", resolver)

      expect(Req, :request, fn opts ->
        assert opts[:url] == pinned
        assert {"host", "id.example.com"} in opts[:headers]
        assert opts[:redirect] == false
        assert opts[:retry] == false
        assert opts[:connect_options][:hostname] == "id.example.com"
        assert opts[:connect_options][:transport_opts][:verify] == :verify_peer

        assert opts[:connect_options][:transport_opts][:server_name_indication] ==
                 ~c"id.example.com"

        {:ok,
         %Req.Response{
           status: 302,
           headers: %{"location" => ["http://127.0.0.1"]},
           body: "redirect"
         }}
      end)

      assert {:ok, %Assent.HTTPAdapter.HTTPResponse{status: 302, body: "redirect"}} =
               OAuth2HTTP.request(:post, "https://id.example.com/token", "code=one", [],
                 resolver: resolver
               )
    end
  end
end
