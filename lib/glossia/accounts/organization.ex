defmodule Glossia.Accounts.Organization do
  @moduledoc """
  A struct that represents the organizations table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Glossia.Accounts.Account

  # Type
  @type t :: %__MODULE__{
          account: Account.t()
        }

  # Schema

  schema "organizations" do
    belongs_to :account, Account
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
    |> cast(attrs, [])
    |> validate_required([:account_id])
  end
end
