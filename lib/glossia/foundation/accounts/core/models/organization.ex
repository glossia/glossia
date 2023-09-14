defmodule Glossia.Foundation.Accounts.Core.Models.Organization do
  @moduledoc """
  A struct that represents the organizations table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Glossia.Foundation.Accounts.Core.Models.{Account, User}

  # Type
  @type t :: %__MODULE__{
          account: Account.t()
        }

  # Schema

  schema "organizations" do
    belongs_to :account, Account

    many_to_many(:users, User,
      join_through: "organization_users",
      on_replace: :delete
    )

    timestamps()
  end

  # Changesets
  @type create_organization_changeset_attrs :: %{
          account: map()
        }

  @spec create_organization_changeset(attrs :: create_organization_changeset_attrs) ::
          Ecto.Changeset.t()
  def create_organization_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:account_id])
    |> validate_required([:account_id])
  end
end
