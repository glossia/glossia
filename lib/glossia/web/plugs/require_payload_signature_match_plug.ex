defmodule Glossia.Web.Plugs.RequirePayloadSignatureMatchPlug do
  @moduledoc """
  This plug will verify that the payload from a webhook request matches the accompanying header signature, based on a previously shared `webhook_secret`.

  When the payload is verified the connection continues as normal.

  When the payload is unverifiable the connection is halted with a 403 response.
  """

  import Plug.Conn
  alias Plug.Conn

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{method: method} = conn, _opts) when method == "POST" or method == "PUT" do
    # TODO: - Not assume GitHub
    case Glossia.Foundation.ContentSources.GitHub.is_webhook_payload_valid?(
           conn.req_headers,
           conn.assigns.raw_body
         ) do
      true ->
        conn

      false ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, "{\"error\":\"PAYLOAD SIGNATURE FAILED\"}")
        |> halt
    end
  end

  def call(conn, _opts), do: Conn.assign(conn, :cached_body, %{})
end
