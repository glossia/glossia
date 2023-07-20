defmodule Glossia.Accounts.OrganizationUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossia.Accounts.{Organization, User}

  # Type
  @type t :: %__MODULE__{
          role: atom(),
          organization: Organization.t(),
          user: User.t()
        }

  # Schema

  schema "organization_users" do
    field :role, Ecto.Enum, values: [admin: 1]
    belongs_to :organization, Organization, primary_key: true
    belongs_to :user, User, primary_key: true
  end

  # Changesets

  @required_fields ~w(user_id organization_id role)a
  def changeset(user_project, params \\ %{}) do
    user_project
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user, :project],
      name: :organization_id_user_id_unique_index
    )
  end
end
