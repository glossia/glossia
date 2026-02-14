defmodule Glossia.Waitlist.Submission do
  use Glossia.Schema
  import Ecto.Changeset

  schema "waitlist_submissions" do
    field :email, :string
    field :company, :string
    field :url, :string
    field :description, :string
    field :motivation, :string
    field :target_languages, :string

    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [
      :email,
      :company,
      :url,
      :description,
      :motivation,
      :target_languages,
      :user_id
    ])
    |> validate_required([:email, :user_id])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> foreign_key_constraint(:user_id)
  end
end
