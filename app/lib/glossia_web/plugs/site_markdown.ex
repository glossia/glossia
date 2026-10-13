defmodule GlossiaWeb.Plugs.SiteMarkdown do
  @moduledoc """
  Serve only published content before sessions, authentication and rendering.

  No User-Agent bypass: Markdown is available to every reader, but never turns
  account, API or dashboard URLs into an alternative unprotected surface.
  """

  import Plug.Conn

  alias Glossia.{I18n, PublicContent}
  alias GlossiaWeb.MarkdownResponse

  def init(opts), do: opts

  def call(conn, opts) do
    conn = published_content(conn)

    if conn.halted do
      conn
    else
      case Glossia.Extensions.site_markdown() do
        nil -> conn
        plug -> plug.call(conn, plug.init(opts))
      end
    end
  end

  defp published_content(%{method: method} = conn) when method in ["GET", "HEAD"] do
    {locale, path} = I18n.split_path(conn.request_path)
    explicit? = Path.extname(path) == ".md"
    canonical_path = if explicit?, do: Path.rootname(path, ".md"), else: path
    canonical_path = if explicit? and canonical_path == "/index", do: "/", else: canonical_path

    # Only literal locale routes qualify. /en/docs and /ES/docs are not
    # marketing routes and must not accidentally exempt an account dashboard.
    markdown =
      if I18n.localize_path(locale, path) == conn.request_path do
        Map.get(PublicContent.documents(locale), canonical_path)
      end

    case markdown do
      nil ->
        conn

      markdown ->
        canonical_path = I18n.localize_path(locale, canonical_path)
        canonical_url = GlossiaWeb.Endpoint.url() |> URI.merge(canonical_path) |> URI.to_string()
        markdown_url = PublicContent.markdown_path(canonical_path)

        conn =
          register_before_send(conn, fn conn ->
            conn = MarkdownResponse.vary_accept(conn)

            if conn.status == 200 do
              conn
              |> put_resp_header(
                "link",
                ~s(<#{canonical_url}>; rel="canonical", <#{markdown_url}>; rel="alternate"; type="text/markdown")
              )
              |> put_resp_header("x-robots-tag", "index, follow")
            else
              conn
            end
          end)

        if explicit? or markdown_requested?(conn) do
          MarkdownResponse.send(conn, markdown)
        else
          conn
        end
    end
  end

  defp published_content(conn), do: conn

  defp markdown_requested?(conn) do
    # Only an explicit supported media type opts in. Honor q=0 and prefer HTML
    # when it has a higher quality; */* remains the ordinary browser response.
    types = conn |> get_req_header("accept") |> Enum.flat_map(&Plug.Conn.Utils.list/1)

    quality = fn type ->
      types
      |> Enum.flat_map(fn value ->
        case Plug.Conn.Utils.media_type(value) do
          {:ok, media, subtype, params} when media <> "/" <> subtype == type ->
            case Float.parse(Map.get(params, "q", "1")) do
              {q, ""} when q >= 0 and q <= 1 -> [q]
              _ -> [0.0]
            end

          _ ->
            []
        end
      end)
      |> Enum.max(fn -> 0.0 end)
    end

    markdown = quality.("text/markdown")
    markdown > 0 and markdown >= quality.("text/html")
  end
end
