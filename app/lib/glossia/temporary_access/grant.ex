defmodule Glossia.TemporaryAccess.Grant do
  @moduledoc false

  use Glossia.Schema

  import Ecto.Changeset

  schema "temporary_access_grants" do
    field :recipient_email, :string
    field :requested_by_email, :string
    field :requested_by_pomerium_id, :string
    field :pomerium_subject, :string
    field :reason, :string
    field :expires_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :recipient_user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(grant, attributes) do
    grant
    |> cast(attributes, [
      :recipient_email,
      :requested_by_email,
      :requested_by_pomerium_id,
      :reason,
      :expires_at
    ])
    |> update_change(:recipient_email, &normalize_email/1)
    |> update_change(:requested_by_email, &normalize_email/1)
    |> update_change(:requested_by_pomerium_id, &String.trim/1)
    |> update_change(:reason, &String.trim/1)
    |> validate_required([
      :recipient_email,
      :requested_by_email,
      :requested_by_pomerium_id,
      :reason,
      :expires_at
    ])
    |> validate_glossia_email(:recipient_email)
    |> validate_glossia_email(:requested_by_email)
    |> validate_length(:reason, min: 10, max: 2_000)
    |> validate_length(:requested_by_pomerium_id, max: 500)
  end

  defp normalize_email(email) when is_binary(email),
    do: email |> String.trim() |> String.downcase()

  defp normalize_email(email), do: email

  defp validate_glossia_email(changeset, field) do
    validate_change(changeset, field, fn ^field, email ->
      case String.split(email, "@", parts: 2) do
        [local_part, "glossia.ai"] when local_part != "" -> []
        _ -> [{field, "must be a @glossia.ai email address"}]
      end
    end)
  end
end
