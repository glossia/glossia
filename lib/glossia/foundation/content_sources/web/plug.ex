defmodule Glossia.Foundation.ContentSources.Web.Plug do
  # Modules
  alias Glossia.Foundation.ContentSources.Web.Plug.GitHub

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(conn, opts) do
    conn |> GitHub.call(GitHub.init(opts))
  end
end