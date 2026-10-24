defmodule GlossiaWeb.ClientIPTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias GlossiaWeb.ClientIP

  defp request(peer \\ {192, 168, 1, 20}) do
    %{conn(:get, "/") | remote_ip: peer}
  end

  test "uses nginx's canonical address instead of a caller-supplied forwarding chain" do
    conn =
      request()
      |> put_req_header("x-real-ip", "8.8.8.8")
      |> put_req_header("x-forwarded-for", "1.1.1.1, 8.8.8.8")
      |> put_req_header("cf-connecting-ip", "9.9.9.9")

    assert ClientIP.value(conn, []) == "8.8.8.8"
  end

  test "does not fall back to an unauthenticated forwarding chain" do
    conn =
      request()
      |> put_req_header("x-forwarded-for", "1.1.1.1")
      |> put_req_header("cf-connecting-ip", "9.9.9.9")

    assert ClientIP.value(conn, []) == "192.168.1.20"
  end

  test "ignores all forwarding headers for a direct public socket peer" do
    conn =
      request({8, 8, 8, 8})
      |> put_req_header("x-real-ip", "1.1.1.1")
      |> put_req_header("cf-connecting-ip", "9.9.9.9")
      |> put_req_header("x-forwarded-for", "4.4.4.4")

    assert ClientIP.value(conn, []) == "8.8.8.8"
    assert ClientIP.value(conn, trust_cloudflare_header: true) == "8.8.8.8"
  end

  test "supports private ingress peer address families" do
    peers = [
      {10, 1, 2, 3},
      {172, 16, 1, 2},
      {172, 31, 1, 2},
      {192, 168, 1, 2},
      {127, 0, 0, 1},
      {0, 0, 0, 0, 0, 0, 0, 1},
      {0xFD3A, 1, 2, 3, 4, 5, 6, 7},
      {0, 0, 0, 0, 0, 0xFFFF, 0xC0A8, 0x0114}
    ]

    for peer <- peers do
      conn = request(peer) |> put_req_header("x-real-ip", "8.8.8.8")
      assert ClientIP.value(conn, []) == "8.8.8.8"
    end
  end

  test "does not classify nearby public ranges as trusted ingress peers" do
    peers = [
      {172, 15, 1, 2},
      {172, 32, 1, 2},
      {192, 169, 1, 2},
      {0, 0, 0, 0, 0, 0xFFFF, 0x0808, 0x0808},
      {0x2606, 0x4700, 0, 0, 0, 0, 0, 0x1111}
    ]

    for peer <- peers do
      conn = request(peer) |> put_req_header("x-real-ip", "1.1.1.1")
      expected = peer |> :inet.ntoa() |> to_string()
      assert ClientIP.value(conn, []) == expected
    end
  end

  test "normalizes valid canonical addresses and rejects malformed ones" do
    for {header, expected} <- [
          {" 8.8.8.8 ", "8.8.8.8"},
          {"2606:4700:0:0:0:0:0:1111", "2606:4700::1111"},
          {"", "192.168.1.20"},
          {"not-an-address", "192.168.1.20"},
          {"8.8.8.8, 1.1.1.1", "192.168.1.20"}
        ] do
      conn = request() |> put_req_header("x-real-ip", header)
      assert ClientIP.value(conn, []) == expected
    end
  end

  test "accepts Cloudflare's client IP only with explicit edge trust" do
    conn =
      request()
      |> put_req_header("x-real-ip", "104.16.0.1")
      |> put_req_header("cf-connecting-ip", "8.8.8.8")

    assert ClientIP.value(conn, []) == "104.16.0.1"
    assert ClientIP.value(conn, trust_cloudflare_header: true) == "8.8.8.8"
  end

  test "missing or invalid trusted Cloudflare headers use the canonical ingress address" do
    for header <- [nil, "", "invalid", "8.8.8.8, 1.1.1.1"] do
      conn = request() |> put_req_header("x-real-ip", "9.9.9.9")
      conn = if header, do: put_req_header(conn, "cf-connecting-ip", header), else: conn
      assert ClientIP.value(conn, trust_cloudflare_header: true) == "9.9.9.9"
    end
  end

  test "rejects duplicate IP headers rather than choosing one" do
    conn = %{
      request()
      | req_headers: [
          {"x-real-ip", "8.8.8.8"},
          {"x-real-ip", "1.1.1.1"},
          {"cf-connecting-ip", "9.9.9.9"},
          {"cf-connecting-ip", "4.4.4.4"}
        ]
    }

    assert ClientIP.value(conn, trust_cloudflare_header: true) == "192.168.1.20"
  end
end
