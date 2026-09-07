defmodule Glossia.SiteRouter do
  @moduledoc false

  @callback resolve(Plug.Conn.t(), [String.t()]) :: Plug.Conn.t() | :not_found
end
