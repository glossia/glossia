defmodule Glossia.Foundation.Accounts.Core.Models.Organization do
  @moduledoc """
  A struct that represents the organizations table.
  """
  use Glossia.Foundation.Database.Core.Schema
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
  @spec create_organization_changeset(attrs :: map()) :: Ecto.Changeset.t()
  def create_organization_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:account_id])
    |> validate_required([:account_id])
  end
end
