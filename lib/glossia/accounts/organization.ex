defmodule Glossia.Accounts.Organization do
  @moduledoc """
  A struct that represents the organizations table.
  """
  use Ecto.Schema

  alias Glossia.Accounts.Account

  schema "organizations" do
    belongs_to :account, Account

    timestamps()
  end
end
