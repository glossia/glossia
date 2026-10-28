defmodule GlossiaEnterprise.SCIM.Token do
  @moduledoc false
  use Glossia.Schema
  import Ecto.Changeset

  schema "scim_tokens" do
    belongs_to :organization, Glossia.Accounts.Organization
    field :name, :string
    field :token_hash, :binary, redact: true
    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> unique_constraint(:token_hash)
  end
end
