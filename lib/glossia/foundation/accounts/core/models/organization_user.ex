defmodule Glossia.Foundation.Accounts.Core.Models.OrganizationUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossia.Foundation.Accounts.Core.Models.{Organization, User}

  # Type
  @type t :: %__MODULE__{
          role: atom(),
          organization: Organization.t(),
          user: User.t()
        }
  @type(role :: :admin, :user)

  # Schema

  schema "organization_users" do
    field :role, Ecto.Enum, values: [{:admin, 1}, {:user, 2}]
    belongs_to :organization, Organization, primary_key: true
    belongs_to :user, User, primary_key: true

    timestamps()
  end

  # Changesets

  @required_fields ~w(user_id organization_id role)a
  def changeset(organization_user, attrs \\ %{}) do
    organization_user
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user, :project],
      name: :organization_id_user_id_unique_index
    )
  end
end
