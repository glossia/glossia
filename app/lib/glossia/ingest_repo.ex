defmodule Glossia.IngestRepo do
  @moduledoc """
  Write-centric ClickHouse repository for ingesting analytical data.
  """

  use Ecto.Repo,
    otp_app: :glossia,
    adapter: Ecto.Adapters.ClickHouse

  alias Glossia.ClickHouseRetry

  defoverridable insert_all: 2, insert_all: 3, insert: 1, insert: 2

  def insert_all(schema_or_source, entries, opts \\ []) do
    with_retry(fn -> super(schema_or_source, entries, opts) end)
  end

  def insert(struct, opts \\ []) do
    with_retry(fn -> super(struct, opts) end)
  end

  defdelegate with_retry(fun), to: ClickHouseRetry
  defdelegate with_retry(fun, retries_left), to: ClickHouseRetry
end
