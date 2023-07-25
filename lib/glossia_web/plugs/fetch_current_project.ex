defmodule GlossiaWeb.Plugs.FetchCurrentProject do
  @moduledoc """
  This plug will read the body for `POST` and PUT` request and store it into a
  new assigns key `:raw_body`.

  This plug is used on certain routes in preference to the default Phoenix
  behaviors that would automatically decode the params and request body into
  native elixir values for a controller. It is a required choice since the body
  of a `Plug.Conn` can only be read from once.
  """

  alias Plug.Conn

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{} = conn, _opts) do
    conn
  end
end
