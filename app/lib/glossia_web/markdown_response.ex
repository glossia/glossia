defmodule GlossiaWeb.MarkdownResponse do
  @moduledoc false

  import Plug.Conn

  def send(conn, markdown, opts \\ []) do
    content_type = Keyword.get(opts, :content_type, "text/markdown")
    etag = ~s("#{:crypto.hash(:sha256, markdown) |> Base.encode16(case: :lower)}")

    conn =
      conn
      |> put_resp_content_type(content_type, "utf-8")
      |> put_resp_header("cache-control", "public, max-age=300, stale-while-revalidate=60")
      |> put_resp_header("etag", etag)
      |> put_resp_header(
        "x-markdown-tokens",
        Integer.to_string(max(1, ceil(String.length(markdown) / 4)))
      )
      |> put_resp_header("x-robots-tag", Keyword.get(opts, :robots, "index, follow"))
      |> delete_resp_header("content-length")

    matches? =
      conn
      |> get_req_header("if-none-match")
      |> Enum.any?(fn value ->
        value
        |> String.split(",")
        |> Enum.any?(fn tag ->
          tag = String.trim(tag)
          tag == "*" or String.trim_leading(tag, "W/") == etag
        end)
      end)

    conn
    |> send_resp(if(matches?, do: 304, else: 200), if(matches?, do: "", else: markdown))
    |> halt()
  end

  def vary_accept(conn) do
    values =
      conn
      |> get_resp_header("vary")
      |> Enum.flat_map(&String.split(&1, ","))
      |> Enum.map(&String.trim/1)

    if Enum.any?(values, &(String.downcase(&1) in ["accept", "*"])) do
      conn
    else
      put_resp_header(conn, "vary", Enum.join(values ++ ["Accept"], ", "))
    end
  end
end
