defmodule GlossiaWeb.Plugs.MarketingMarkdown do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    case Glossia.Extensions.marketing_markdown() do
      nil -> conn
      plug -> plug.call(conn, plug.init([]))
    end
  end
end
