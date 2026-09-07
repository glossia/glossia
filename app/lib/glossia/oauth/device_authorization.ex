defmodule Glossia.OAuth.DeviceAuthorization do
  use Glossia.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved denied consumed)

  schema "oauth_device_authorizations" do
    field :device_code_hash, :string
    field :user_code, :string
    field :scope, :string, default: ""
    field :status, :string, default: "pending"
    field :interval, :integer, default: 5
    field :expires_at, :utc_datetime_usec
    field :authorized_at, :utc_datetime_usec
    field :denied_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec
    field :last_polled_at, :utc_datetime_usec

    belongs_to :client, Boruta.Ecto.Client
    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def create_changeset(device_authorization, attrs) do
    device_authorization
    |> cast(attrs, [
      :device_code_hash,
      :user_code,
      :scope,
      :status,
      :interval,
      :expires_at,
      :client_id
    ])
    |> validate_required([
      :device_code_hash,
      :user_code,
      :status,
      :interval,
      :expires_at,
      :client_id
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:interval, greater_than_or_equal_to: 1)
    |> unique_constraint(:device_code_hash)
    |> unique_constraint(:user_code)
  end

  def approve_changeset(device_authorization, user_id) do
    change(device_authorization,
      status: "approved",
      user_id: user_id,
      authorized_at: DateTime.utc_now(),
      denied_at: nil
    )
  end

  def deny_changeset(device_authorization, user_id) do
    change(device_authorization,
      status: "denied",
      user_id: user_id,
      denied_at: DateTime.utc_now()
    )
  end

  def consume_changeset(device_authorization) do
    change(device_authorization, status: "consumed", consumed_at: DateTime.utc_now())
  end
end
