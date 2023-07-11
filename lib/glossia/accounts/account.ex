defmodule Glossia.Accounts.Account do
  use Ecto.Schema

  import Ecto.Changeset

  schema "accounts" do
    field :handle, :string
    timestamps()
  end

  def creation_changeset(account, attrs, _opts \\ []) do
    account |> cast(attrs, [:handle])
  end
end
