defmodule Glossia.Accounts.OrganizationInvitation do
  use Glossia.Schema
  import Ecto.Changeset

  schema "organization_invitations" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :status, :string, default: "pending"
    field :expires_at, :utc_datetime_usec

    belongs_to :organization, Glossia.Accounts.Organization
    belongs_to :invited_by, Glossia.Accounts.User

    timestamps()
  end

  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:email, :role, :status, :expires_at])
    |> validate_required([:email, :role, :status, :expires_at])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:role, ["admin", "member", "linguist"])
    |> validate_inclusion(:status, ["pending", "accepted", "declined", "revoked"])
  end
end
