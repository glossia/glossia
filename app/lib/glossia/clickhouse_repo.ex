defmodule Glossia.ClickHouseRepo do
  @moduledoc """
  Read-only ClickHouse repository for analytical queries.
  """

  use Ecto.Repo,
    otp_app: :glossia,
    adapter: Ecto.Adapters.ClickHouse,
    read_only: true
end
