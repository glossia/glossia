defmodule Babel.Organizations.Organization do
  @moduledoc """
  A company whose relationship with Glossia is tracked across Babel domains.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Babel.Organizations.Interaction

  @states ["researching", "qualified", "engaging", "demo_scheduled", "customer", "not_a_fit"]

  schema "organizations" do
    field :name, :string
    field :website_url, :string
    field :state, :string, default: "researching"
    field :translation_tool, :string
    field :notes, :string
    field :origin_url, :string
    field :glossia_organization_id, :binary_id

    has_many :interactions, Interaction

    timestamps(type: :utc_datetime)
  end

  def changeset(organization, attributes) do
    organization
    |> cast(attributes, [
      :name,
      :website_url,
      :state,
      :translation_tool,
      :notes,
      :origin_url,
      :glossia_organization_id
    ])
    |> validate_required([:name, :website_url, :state])
    |> validate_inclusion(:state, @states)
    |> validate_https_url(:website_url)
    |> validate_optional_https_url(:origin_url)
    |> unique_constraint(:name)
    |> unique_constraint(:website_url)
  end

  def states, do: @states

  defp validate_https_url(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      case URI.parse(value) do
        %URI{scheme: "https", host: host} when is_binary(host) and host != "" -> []
        _uri -> [{field, "must be a secure web address"}]
      end
    end)
  end

  defp validate_optional_https_url(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      case URI.parse(value) do
        %URI{scheme: "https", host: host} when is_binary(host) and host != "" -> []
        _uri -> [{field, "must be a secure web address"}]
      end
    end)
  end
end
