defmodule Glossia.Accounts.Account do
  use Glossia.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :handle, :string
    field :type, :string, default: "user"
    field :has_access, :boolean, default: false
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :stripe_subscription_status, :string
    field :stripe_current_period_end, :utc_datetime_usec

    has_one :user, Glossia.Accounts.User
    has_one :organization, Glossia.Accounts.Organization
    has_many :projects, Glossia.Accounts.Project

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :handle,
      :type,
      :has_access,
      :stripe_customer_id,
      :stripe_subscription_id,
      :stripe_subscription_status,
      :stripe_current_period_end
    ])
    |> validate_required([:handle])
    |> validate_inclusion(:type, ["user", "organization"])
    |> validate_format(:handle, ~r/^[a-z]([a-z0-9-]*[a-z0-9])?$/,
      message: "must start with a letter and contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 39)
    |> validate_not_reserved()
    |> unique_constraint(:handle)
  end

  defp validate_not_reserved(changeset) do
    validate_change(changeset, :handle, fn :handle, handle ->
      if Glossia.Accounts.ReservedHandles.reserved?(handle) do
        [handle: "is reserved and cannot be used"]
      else
        []
      end
    end)
  end
end
