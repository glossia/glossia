defmodule Glossia.IngestRepo do
  @moduledoc """
  Write-centric ClickHouse repository for ingesting analytical data.
  """

  use Ecto.Repo,
    otp_app: :glossia,
    adapter: Ecto.Adapters.ClickHouse
end
