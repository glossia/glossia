defmodule Babel.GoToMarket.Prospect do
  @moduledoc """
  A researched company that may benefit from a developer-led Glossia introduction.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Babel.Organizations.Organization

  @statuses ["researching", "ready", "contacted", "demo_booked", "not_a_fit"]

  schema "go_to_market_prospects" do
    field :company, :string
    field :website_url, :string
    field :translation_tool, :string
    field :source_title, :string
    field :source_url, :string
    field :evidence, :string
    field :contact_name, :string
    field :contact_role, :string
    field :contact_profile_url, :string
    field :status, :string, default: "researching"
    field :outreach_angle, :string
    field :intro_email_draft, :string
    field :next_step, :string

    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  def changeset(prospect, attributes) do
    prospect
    |> cast(attributes, [
      :company,
      :website_url,
      :translation_tool,
      :source_title,
      :source_url,
      :evidence,
      :contact_name,
      :contact_role,
      :contact_profile_url,
      :status,
      :outreach_angle,
      :intro_email_draft,
      :next_step,
      :organization_id
    ])
    |> validate_required([
      :company,
      :website_url,
      :source_title,
      :source_url,
      :evidence,
      :status,
      :outreach_angle,
      :next_step
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_https_url(:website_url)
    |> validate_https_url(:source_url)
    |> validate_optional_https_url(:contact_profile_url)
    |> unique_constraint([:company, :source_url])
    |> foreign_key_constraint(:organization_id)
  end

  def statuses, do: @statuses

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
