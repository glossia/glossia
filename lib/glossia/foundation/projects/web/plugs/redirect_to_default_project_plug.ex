defmodule Glossia.Foundation.Projects.Web.Plugs.RedirectToDefaultProjectPlug do
  @moduledoc """
  If there is an authenticated user
  """
  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(
        conn,
        _opts
      ) do
    conn
  end
end
