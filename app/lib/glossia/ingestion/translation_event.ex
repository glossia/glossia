defmodule Glossia.Ingestion.TranslationEvent do
  use Ecto.Schema
  use Glossia.Ingestion.Bufferable

  @primary_key false

  schema "translation_session_events" do
    field :id, Ch, type: "UUID"
    field :session_id, Ch, type: "String"
    field :sequence, Ch, type: "UInt32"
    field :event_type, Ch, type: "LowCardinality(String)"
    field :content, Ch, type: "String"
    field :metadata, Ch, type: "String"
  end
end
