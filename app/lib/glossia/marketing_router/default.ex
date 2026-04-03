defmodule Glossia.MarketingRouter.Default do
  @moduledoc false

  @behaviour Glossia.MarketingRouter

  @impl true
  def resolve(_conn, _path), do: :not_found
end
