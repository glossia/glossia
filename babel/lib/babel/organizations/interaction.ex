defmodule Babel.Organizations.Interaction do
  @moduledoc """
  A time-stamped account event, such as research, outreach, a meeting, or a renewal touchpoint.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Babel.Organizations.Organization

  @kinds ["research", "note", "introduction_draft", "message_sent", "demo", "state_change"]

  schema "organization_interactions" do
    field :kind, :string
    field :summary, :string
    field :body, :string
    field :source_url, :string
    field :occurred_at, :utc_datetime

    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  def changeset(interaction, attributes) do
    interaction
    |> cast(attributes, [:organization_id, :kind, :summary, :body, :source_url, :occurred_at])
    |> validate_required([:organization_id, :kind, :summary, :occurred_at])
    |> validate_inclusion(:kind, @kinds)
    |> validate_optional_https_url(:source_url)
    |> foreign_key_constraint(:organization_id)
  end

  def kinds, do: @kinds

  defp validate_optional_https_url(changeset, field) do
    case get_field(changeset, field) do
      value when is_binary(value) and value != "" -> validate_https_url(changeset, field)
      _value -> changeset
    end
  end

  defp validate_https_url(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      case URI.parse(value) do
        %URI{scheme: "https", host: host} when is_binary(host) and host != "" -> []
        _uri -> [{field, "must be a secure web address"}]
      end
    end)
  end
end
