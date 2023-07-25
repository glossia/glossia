defmodule GlossiaWeb.Plugs.FetchCurrentProject do
  @moduledoc """

  """

  alias Plug.Conn

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{} = conn, _opts) do
    conn
  end
end
