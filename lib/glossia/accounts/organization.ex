defmodule Glossia.Accounts.Organization do
  use Ecto.Schema

  alias Glossia.Accounts.Account

  schema "organizations" do
    belongs_to :account, Account

    timestamps()
  end
end
