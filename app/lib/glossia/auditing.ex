defmodule Glossia.Auditing do
  @moduledoc """
  Facade for audit recording.

  The default OSS sink writes events to ClickHouse. Enterprise deployments can
  replace the sink in config while keeping the same `Glossia.Auditing.record/4`
  calls throughout the app.
  """

  def record(name, account, user, opts \\ []) do
    sink().record(%{name: name, account: account, user: user, opts: opts})
  end

  def list_events(account_id, opts \\ []) do
    sink().list_events(account_id, opts)
  end

  defp sink, do: Glossia.Extensions.audit_sink()
end
