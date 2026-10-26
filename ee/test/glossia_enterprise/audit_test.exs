defmodule GlossiaEnterprise.AuditTest do
  use ExUnit.Case, async: true

  alias GlossiaEnterprise.Audit
  alias GlossiaEnterprise.Audit.Event

  test "preserves the ClickHouse audit row format" do
    assert Event.__schema__(:source) == "events"

    assert Event.__schema__(:fields) == [
             :id,
             :name,
             :account_id,
             :user_id,
             :actor_handle,
             :actor_email,
             :resource_type,
             :resource_id,
             :resource_path,
             :summary,
             :duration_ms,
             :metadata
           ]

    opts = Event.buffer_opts()
    assert opts.insert_sql =~ "INSERT INTO events"
    assert opts.insert_opts[:source] == "events"
    assert is_binary(opts.header)
  end

  test "supplies the enterprise audit buffer child spec" do
    assert [%{id: GlossiaEnterprise.Audit.EventBuffer, start: start}] = Audit.children()
    assert {Glossia.Ingestion.Buffer, :start_link, [opts]} = start
    assert opts[:name] == GlossiaEnterprise.Audit.EventBuffer
    assert opts[:insert_sql] == Event.buffer_opts().insert_sql
  end

  test "enterprise builds configure the audit extension" do
    assert Application.fetch_env!(:glossia, :audit_extension) == Audit
    assert Glossia.Extensions.audit_children() == Audit.children()
  end
end
