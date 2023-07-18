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
    belongs_to :organization, Organization
    belongs_to :user, User
  end
end
