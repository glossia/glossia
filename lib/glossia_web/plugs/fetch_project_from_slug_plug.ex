defmodule GlossiaWeb.Plugs.FetchProjectFromSlugPlug do
  @moduledoc """
  This plug will extract the project owner and handle from the URL and load the project from the database.
  """

  import Plug.Conn
  alias Plug.Conn

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{path_params: %{"owner" => owner, "project" => project}} = conn, opts) do
    # case Conn.read_body(conn, opts) do
    #   {:ok, body, _conn_details} ->
    #     Conn.assign(conn, :raw_body, body)

    #   {:more, _partial_body, _conn_details} ->
    #     conn
    #     |> send_resp(413, "PAYLOAD TOO LARGE")
    #     |> halt
    # end
  end

  def call(conn, _opts), do: conn
end
