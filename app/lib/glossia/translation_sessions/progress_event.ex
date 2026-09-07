defmodule Glossia.TranslationSessions.ProgressEvent do
  @moduledoc """
  A durable structural progress event for a translation session.

  The translation streams thousands of text and reasoning chunks per file, so
  only the events that shape the panel — the plan, and each file starting,
  completing, or failing — are written here. Those are what a LiveView needs to
  render a session it did not watch from the beginning: one mounting on another
  replica, or after the pod that ran the translation is gone.

  `seq` is assigned by the process producing the run, so it is monotonic across
  the whole session and lets a viewer that already folded a prefix ignore
  events it has seen.
  """

  use Glossia.Schema

  import Ecto.Changeset

  alias Glossia.TranslationSessions.TranslationSession

  schema "translation_session_progress_events" do
    field :seq, :integer
    field :payload, :map, default: %{}

    belongs_to :session, TranslationSession

    timestamps(updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:session_id, :seq, :payload])
    |> validate_required([:session_id, :seq, :payload])
    # Declared so a write against a session that is not there comes back as an
    # error rather than raising. A progress row is worth much less than the
    # translation producing it, so the caller logs it and carries on.
    |> foreign_key_constraint(:session_id)
  end
end
