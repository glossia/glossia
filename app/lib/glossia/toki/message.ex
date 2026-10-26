defmodule Glossia.Toki.Message do
  @moduledoc "A durable message and inference claim. Client UUIDs identify user messages."
  use Glossia.Schema
  import Ecto.Changeset

  schema "toki_messages" do
    belongs_to :conversation, Glossia.Toki.Conversation
    belongs_to :reply_to, __MODULE__
    belongs_to :user, Glossia.Accounts.User
    field :role, :string
    field :content, :string
    field :status, :string
    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:id, :content])
    |> validate_required([:id, :content, :conversation_id, :role, :status])
    |> validate_length(:content, max: 8_000)
    |> validate_change(:content, fn :content, content ->
      if byte_size(content) > 32_000, do: [content: "is too large"], else: []
    end)
    |> unique_constraint(:id, name: :toki_messages_pkey)
  end
end
