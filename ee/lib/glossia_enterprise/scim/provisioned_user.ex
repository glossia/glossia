defmodule GlossiaEnterprise.SCIM.ProvisionedUser do
  @moduledoc false
  use Glossia.Schema
  import Ecto.Changeset

  schema "scim_users" do
    belongs_to :organization, Glossia.Accounts.Organization
    belongs_to :user, Glossia.Accounts.User
    field :external_id, :string
    field :display_name, :string
    field :active, :boolean, default: true
    field :identity_linkable, :boolean, default: false
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:external_id, :display_name, :active])
    |> validate_length(:external_id, max: 255)
    |> validate_length(:display_name, max: 255)
    |> unique_constraint([:organization_id, :user_id])
    |> unique_constraint([:organization_id, :external_id])
  end
end
