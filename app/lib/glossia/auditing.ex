defmodule Glossia.Auditing do
  @moduledoc """
  Read-side facade for audit log queries while OSS mutations move to
  `Glossia.Events.emit/4`.
  """

  def record(name, account, user, opts \\ []) do
    Glossia.Events.emit(name, account, user, opts)
  end

  def list_events(account_id, opts \\ []) do
    sink().list_events(account_id, opts)
  end

  defp sink, do: Glossia.Extensions.audit_sink()
end
