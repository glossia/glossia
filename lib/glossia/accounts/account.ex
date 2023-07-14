defmodule Glossia.Accounts.Account do
  use Ecto.Schema

  schema "accounts" do
    field :handle, :string
    timestamps()
  end
end
