defmodule Glossia.Repo.Migrations.AddTranslationSessionOutcomes do
  use Ecto.Migration

  def change do
    alter table(:translation_sessions) do
      add :outcome, :string
      add :translated_content_count, :integer, null: false, default: 0
      add :content_hit_count, :integer, null: false, default: 0
    end

    create index(:translation_sessions, [:project_id, :outcome])

    execute(
      "UPDATE translation_sessions SET outcome = 'content_hit' WHERE status = 'completed' AND summary = 'No translations needed.'",
      "UPDATE translation_sessions SET outcome = NULL WHERE outcome = 'content_hit'"
    )

    execute(
      "UPDATE translation_sessions SET outcome = 'translated' WHERE status = 'completed' AND outcome IS NULL",
      "UPDATE translation_sessions SET outcome = NULL WHERE outcome = 'translated'"
    )

    execute(
      "UPDATE translation_sessions SET outcome = 'failed' WHERE status = 'failed'",
      "UPDATE translation_sessions SET outcome = NULL WHERE outcome = 'failed'"
    )

    execute(
      "UPDATE translation_sessions SET outcome = 'cancelled' WHERE status = 'cancelled'",
      "UPDATE translation_sessions SET outcome = NULL WHERE outcome = 'cancelled'"
    )

    execute(
      """
      WITH latest_runs AS (
        SELECT
          session_id,
          COALESCE(MAX(seq) FILTER (WHERE payload->>'type' = 'run_started'), 0) AS started_at_seq
        FROM translation_session_progress_events
        GROUP BY session_id
      ), progress_counts AS (
        SELECT
          events.session_id,
          COUNT(DISTINCT events.payload->>'index')
            FILTER (WHERE events.payload->>'type' = 'item_completed')::integer AS translated,
          COALESCE(
            MAX((events.payload->>'up_to_date')::integer)
              FILTER (WHERE events.payload->>'type' = 'plan_assessed'),
            COUNT(*) FILTER (WHERE events.payload->>'type' = 'item_skipped'),
            0
          )::integer AS content_hits
        FROM translation_session_progress_events AS events
        INNER JOIN latest_runs ON latest_runs.session_id = events.session_id
        WHERE events.seq > latest_runs.started_at_seq
        GROUP BY events.session_id
      )
      UPDATE translation_sessions AS sessions
      SET
        translated_content_count = progress_counts.translated,
        content_hit_count = progress_counts.content_hits
      FROM progress_counts
      WHERE sessions.id = progress_counts.session_id
      """,
      "UPDATE translation_sessions SET translated_content_count = 0, content_hit_count = 0"
    )

    execute(
      """
      UPDATE translation_sessions AS previous
      SET outcome = 'superseded'
      WHERE previous.status = 'cancelled'
        AND EXISTS (
          SELECT 1
          FROM translation_sessions AS replacement
          WHERE replacement.continued_from_session_id = previous.id
        )
      """,
      "UPDATE translation_sessions SET outcome = 'cancelled' WHERE outcome = 'superseded'"
    )
  end
end
