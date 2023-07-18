defmodule Glossia.Accounts.Account do
  @type t :: %__MODULE__{
          handle: String.t()
        }

  @moduledoc """
  A module that represents the accounts table
  """
  use Ecto.Schema

  schema "accounts" do
    field :handle, :string
    timestamps()
  end
end
