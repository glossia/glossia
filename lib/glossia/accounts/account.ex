defmodule Glossia.Accounts.Account do
  use Boundary

  @moduledoc """
  A module that represents the accounts table
  """
  use Ecto.Schema

  schema "accounts" do
    field :handle, :string
    timestamps()
  end
end
