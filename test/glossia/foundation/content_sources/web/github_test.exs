defmodule Glossia.Foundation.ContentSources.Web.Plug.GitHubTest do
  # Modules
  use Glossia.Foundation.Application.Web.ConnCase
  alias Glossia.Foundation.ContentSources.Web.Plug.GitHub
  import Plug.Conn

  # Cases

  test "halts the connection if the payload is invalid", %{conn: conn} do
    # Given
    opts = GitHub.init([])

    conn = %{conn | method: "POST", request_path: "/webhooks/github"} |> assign(:raw_body, "")

    # When
    conn = conn |> GitHub.call(opts)

    # Then
    assert conn.halted == true

    assert %{
             "error" => "PAYLOAD SIGNATURE FAILED"
           } =
             json_response(conn, 403)
  end

  test "doesn't halt the connection if the payload is valid", %{conn: conn} do
    # Given
    opts = GitHub.init([])
    payload = "payload"
    secret = Glossia.Foundation.ContentSources.Core.GitHub.webhook_secret()
    signature = :crypto.mac(:hmac, :sha, secret, payload) |> Base.encode16(case: :lower)

    conn =
      %{conn | method: "POST", request_path: "/webhooks/github"} |> assign(:raw_body, payload)

    conn = conn |> put_req_header("x-hub-signature", "sha1=#{signature}")

    # When
    conn = conn |> GitHub.call(opts)

    # Then
    assert conn.halted == false
  end
end
