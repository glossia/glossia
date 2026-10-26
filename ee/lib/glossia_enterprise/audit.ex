defmodule GlossiaEnterprise.Audit do
  @moduledoc """
  Supervision extension for enterprise audit ingestion.

  The buffer and row schema are isolated here so core deployments do not
  compile or start enterprise audit code. Event persistence and an audit-log
  interface are not implemented by this extension yet.
  """

  alias Glossia.Ingestion.Buffer
  alias GlossiaEnterprise.Audit.Event

  def children do
    opts =
      Event.buffer_opts()
      |> Map.take([:insert_sql, :insert_opts, :header])
      |> Map.to_list()

    [
      Supervisor.child_spec(
        {Buffer, [name: GlossiaEnterprise.Audit.EventBuffer] ++ opts},
        id: GlossiaEnterprise.Audit.EventBuffer
      )
    ]
  end
end
