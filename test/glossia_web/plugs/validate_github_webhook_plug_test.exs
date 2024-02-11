defmodule GlossiaWeb.Plugs.ValidateGitHubWebhookPlugTest do
  @moduledoc false

  alias GlossiaWeb.Plugs.ValidateGitHubWebhookPlug
  import Plug.Conn
  use Glossia.Web.ConnCase

  # Cases

  test "halts the connection if the payload is invalid", %{conn: conn} do
    # Given
    opts = ValidateGitHubWebhookPlug.init([])

    conn = %{conn | method: "POST", request_path: "/webhooks/github"} |> assign(:raw_body, "")

    # When
    conn = conn |> ValidateGitHubWebhookPlug.call(opts)

    # Then
    assert conn.halted == true

    assert %{
             "error" => "PAYLOAD SIGNATURE FAILED"
           } =
             json_response(conn, 403)
  end

  test "doesn't halt the connection if the payload is valid", %{conn: conn} do
    # Given
    opts = ValidateGitHubWebhookPlug.init([])
    payload = "payload"
    secret = Glossia.ContentSources.Platforms.GitHub.webhook_secret()
    signature = :crypto.mac(:hmac, :sha, secret, payload) |> Base.encode16(case: :lower)

    conn =
      %{conn | method: "POST", request_path: "/webhooks/github"} |> assign(:raw_body, payload)

    conn = conn |> put_req_header("x-hub-signature", "sha1=#{signature}")

    # When
    conn = conn |> ValidateGitHubWebhookPlug.call(opts)

    # Then
    assert conn.halted == false
  end
end
