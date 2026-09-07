defmodule GlossiaWeb.Plugs.SiteMarkdown do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    case Glossia.Extensions.site_markdown() do
      nil -> conn
      plug -> plug.call(conn, plug.init([]))
    end
  end
end
