defmodule Glossia.Accounts.Account do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:handle, :visibility],
    sortable: [:handle, :visibility, :inserted_at],
    default_order: %{order_by: [:handle], order_directions: [:asc]}
  }

  schema "accounts" do
    field :handle, :string
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :stripe_subscription_status, :string
    field :stripe_current_period_end, :utc_datetime_usec
    field :visibility, :string, default: "private"

    has_one :user, Glossia.Accounts.User
    has_one :organization, Glossia.Accounts.Organization
    has_many :projects, Glossia.Accounts.Project
    has_many :github_installations, Glossia.Accounts.GithubInstallation

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :handle,
      :stripe_customer_id,
      :stripe_subscription_id,
      :stripe_subscription_status,
      :stripe_current_period_end,
      :visibility
    ])
    |> validate_required([:handle])
    |> validate_inclusion(:visibility, ["private", "public"])
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

defimpl FunWithFlags.Actor, for: Glossia.Accounts.Account do
  def id(%{id: id}), do: "account:#{id}"
end
