defmodule Glossia.SiteRouter.Default do
  @moduledoc false

  @behaviour Glossia.SiteRouter

  @impl true
  def resolve(_conn, _path), do: :not_found
end
