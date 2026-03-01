defmodule Glossia.Repo.Migrations.RenameChangeRequestKindsToSuggestions do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE tickets
    SET kind = 'voice_suggestion'
    WHERE kind = 'voice_change_request'
    """)

    execute("""
    UPDATE tickets
    SET kind = 'glossary_suggestion'
    WHERE kind = 'glossary_change_request'
    """)
  end

  def down do
    execute("""
    UPDATE tickets
    SET kind = 'voice_change_request'
    WHERE kind = 'voice_suggestion'
    """)

    execute("""
    UPDATE tickets
    SET kind = 'glossary_change_request'
    WHERE kind = 'glossary_suggestion'
    """)
  end
end
