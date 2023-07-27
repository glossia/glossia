defmodule GlossiaWeb.Plugs.AuthorizeBuildsAPIKey do
  @moduledoc """

  """

  import Plug.Conn
  alias Plug.Conn

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{} = conn, _opts) do
    case get_req_header(conn, "authorization") do
      [] ->
        send_json_response(conn, 401, %{"error" => "Missing authorization header"})

      ["Bearer " <> token] ->
        if Plug.Crypto.secure_compare(
             token,
             Application.get_env(:glossia, :builder_api_key)
           ) do
          conn
        else
          send_json_response(conn, 401, %{"error" => "Invalid token"})
        end

      _ ->
        send_json_response(conn, 401, %{"error" => "Invalid authorization header"})
    end
  end

  defp send_json_response(conn, status, body) do
    conn
    |> put_status(status)
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
    |> halt()
  end
end
