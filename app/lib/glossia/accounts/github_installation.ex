defmodule Glossia.Accounts.GithubInstallation do
  use Glossia.Schema
  import Ecto.Changeset

  schema "github_installations" do
    field :github_installation_id, :integer
    field :github_account_login, :string
    field :github_account_type, :string
    field :github_account_id, :integer
    field :suspended_at, :utc_datetime

    belongs_to :account, Glossia.Accounts.Account
    has_many :projects, Glossia.Accounts.Project

    timestamps()
  end

  def changeset(installation, attrs) do
    installation
    |> cast(attrs, [
      :github_installation_id,
      :github_account_login,
      :github_account_type,
      :github_account_id,
      :suspended_at
    ])
    |> validate_required([
      :github_installation_id,
      :github_account_login,
      :github_account_type,
      :github_account_id
    ])
    |> validate_inclusion(:github_account_type, ["Organization", "User"])
    |> unique_constraint(:github_installation_id)
  end
end
