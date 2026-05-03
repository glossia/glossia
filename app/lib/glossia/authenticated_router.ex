defmodule Glossia.AuthenticatedRouter do
  @callback resolve(Plug.Conn.t(), [String.t()]) :: Plug.Conn.t() | :not_found
end

defmodule Glossia.AuthenticatedRouter.Default do
  @moduledoc false

  @behaviour Glossia.AuthenticatedRouter

  @impl true
  def resolve(_conn, _path), do: :not_found
end
