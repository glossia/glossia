defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  def github(conn, _params) do
    secret = Application.get_env(:glossia, Ueberauth.Strategy.Github.OAuth)[:webhooks_secret]

    with {:ok, _} <- conn |> verify_github_signature(secret) do
      # Handle your webhook event here
      send_resp(conn, 200, "ok")
    else
      _ -> send_resp(conn, 403, "Forbidden")
    end
  end

  defp verify_github_signature(conn, secret) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    {signing_algo, expected_signature} =
      conn
      |> Plug.Conn.get_req_header("x-hub-signature")
      |> List.first()
      |> String.split("=")

    case signing_algo do
      "sha1" ->
        computed_signature =
          :crypto.mac(:hmac, :sha, secret, body) |> Base.encode16() |> String.downcase()

        if secure_compare(expected_signature, computed_signature) do
          {:ok, :verified}
        else
          Logger.warning("Invalid GitHub webhook signature")
          {:error, :invalid_signature}
        end

      _ ->
        Logger.warning("Invalid signing algorithm: #{signing_algo}")
        {:error, :invalid_algorithm}
    end
  end

  # Constant time string comparison to prevent timing attacks
  defp secure_compare(a, b) do
    Plug.Crypto.secure_compare(a, b)
  end
end
