defmodule Glossia.Interest do
  @moduledoc "Validates interest requests and emails them for gradual onboarding."

  import Ecto.Changeset

  alias Glossia.Emails
  alias Glossia.Mailer

  def changeset(attrs) do
    {%{}, %{email: :string}}
    |> cast(attrs, [:email])
    |> update_change(:email, &String.trim/1)
    |> validate_required([:email])
    |> validate_length(:email, max: 254)
    |> validate_format(:email, ~r/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/u)
  end

  def deliver(changeset) do
    case apply_action(changeset, :insert) do
      {:ok, %{email: email}} ->
        case email |> Emails.interest_email() |> Mailer.deliver() do
          {:ok, metadata} -> {:ok, metadata}
          {:error, reason} -> {:error, {:delivery_failed, reason}}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
