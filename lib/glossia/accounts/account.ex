defmodule Glossia.Accounts.Account do
  @moduledoc """
  A module that represents the accounts table
  """
  @type t :: %__MODULE__{
          handle: String.t(),
          projects: [Project.t()] | nil
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias Glossia.Projects.Project

  schema "accounts" do
    field :handle, :string

    has_many(:projects, Project)
    timestamps()
  end

  @type create_account_changeset_attrs :: %{
          handle: String.t()
        }
  @spec create_acccount_changeset(attrs :: create_account_changeset_attrs()) :: Ecto.Changeset.t()
  def create_acccount_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:handle])
    |> validate_required([:handle])
    |> unique_constraint(:handle)
  end
end
