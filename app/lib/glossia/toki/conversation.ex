defmodule Glossia.Toki.Conversation do
  @moduledoc "A private companion conversation owned by one user in one project."
  use Glossia.Schema
  import Ecto.Changeset

  @derive {Flop.Schema,
           filterable: [],
           sortable: [:updated_at, :id],
           default_order: %{order_by: [:updated_at, :id], order_directions: [:desc, :desc]},
           pagination_types: [:page],
           default_pagination_type: :page,
           default_limit: 20,
           max_limit: 50}

  schema "toki_conversations" do
    belongs_to :user, Glossia.Accounts.User
    belongs_to :project, Glossia.Accounts.Project
    # Retain the immutable reference even if its source is deleted. Every use
    # resolves and authorizes the source again; this is not an access grant.
    field :translation_session_id, Ecto.UUID
    field :title, :string, default: "New conversation"
    field :status, :string, default: "completed"
    field :error, :string
    has_many :messages, Glossia.Toki.Message
    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:id, :translation_session_id])
    |> validate_required([:id, :user_id, :project_id])
    |> validate_immutable_origin()
    |> unique_constraint(:id, name: :toki_conversations_pkey)
  end

  defp validate_immutable_origin(%{data: %{__meta__: %{state: :loaded}}} = changeset) do
    if changed?(changeset, :translation_session_id),
      do: add_error(changeset, :translation_session_id, "cannot be changed"),
      else: changeset
  end

  defp validate_immutable_origin(changeset), do: changeset
end
