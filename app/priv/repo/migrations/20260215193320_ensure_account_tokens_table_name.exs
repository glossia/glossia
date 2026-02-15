defmodule Glossia.Repo.Migrations.EnsureAccountTokensTableName do
  use Ecto.Migration

  def up do
    # If a token table already exists under a legacy name, rename it to the
    # canonical `account_tokens` name. We avoid hard-coding the legacy table
    # name so this migration is safe in mixed dev/test environments.
    execute("""
    DO $$
    DECLARE
      candidate_count integer;
      candidate_table text;
    BEGIN
      IF to_regclass('public.account_tokens') IS NOT NULL THEN
        RETURN;
      END IF;

      WITH candidates AS (
        SELECT c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
        GROUP BY c.table_name
        HAVING
          SUM(CASE WHEN c.column_name = 'token_hash' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'token_prefix' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'revoked_at' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'scope' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'expires_at' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'last_used_at' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'account_id' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'user_id' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'name' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'inserted_at' THEN 1 ELSE 0 END) = 1 AND
          SUM(CASE WHEN c.column_name = 'updated_at' THEN 1 ELSE 0 END) = 1
      )
      SELECT count(*), min(table_name) INTO candidate_count, candidate_table FROM candidates;

      IF candidate_count = 1 THEN
        EXECUTE format('ALTER TABLE %I RENAME TO account_tokens', candidate_table);
      END IF;
    END $$;
    """)
  end

  def down do
    :ok
  end
end
