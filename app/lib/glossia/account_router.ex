defmodule Glossia.AccountRouter do
  @callback resolve(Plug.Conn.t(), String.t(), [String.t()]) :: Plug.Conn.t() | :not_found
end

defmodule Glossia.AccountRouter.Default do
  @moduledoc false

  @behaviour Glossia.AccountRouter

  @impl true
  def resolve(_conn, _handle, _path), do: :not_found
end
