defmodule Babel.Organizations.TemporaryAccess do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @durations [15, 30, 60, 240]

  embedded_schema do
    field :email, :string
    field :duration_minutes, :integer, default: 30
    field :reason, :string
  end

  def changeset(access, attributes) do
    access
    |> cast(attributes, [:email, :duration_minutes, :reason])
    |> update_change(:email, &normalize_email/1)
    |> update_change(:reason, &String.trim/1)
    |> validate_required([:email, :duration_minutes, :reason])
    |> validate_glossia_email()
    |> validate_inclusion(:duration_minutes, @durations)
    |> validate_length(:reason, min: 10, max: 2_000)
  end

  def durations, do: @durations

  defp normalize_email(email) when is_binary(email),
    do: email |> String.trim() |> String.downcase()

  defp normalize_email(email), do: email

  defp validate_glossia_email(changeset) do
    validate_change(changeset, :email, fn :email, email ->
      case String.split(email, "@", parts: 2) do
        [local_part, "glossia.ai"] when local_part != "" -> []
        _ -> [email: "must be a @glossia.ai email address"]
      end
    end)
  end
end
