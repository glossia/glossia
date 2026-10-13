defmodule GlossiaWeb.Plugs.NoIndex do
  @moduledoc "Prevent indexing of application and authentication responses, including errors."

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    register_before_send(conn, fn conn ->
      if Keyword.get(opts, :only_if_unset, false) and conn.status < 400 and
           get_resp_header(conn, "x-robots-tag") != [] do
        conn
      else
        put_resp_header(conn, "x-robots-tag", "noindex, nofollow")
      end
    end)
  end
end
