defmodule Glossia.Accounts.OAuthApplication do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name],
    sortable: [:name, :inserted_at],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  schema "oauth_applications" do
    field :name, :string
    field :description, :string
    field :homepage_url, :string
    field :boruta_client_id, Ecto.UUID

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(app, attrs) do
    app
    |> cast(attrs, [:name, :description, :homepage_url])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_url(:homepage_url)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _field, value ->
      case URI.parse(value) do
        %URI{scheme: scheme} when scheme in ["http", "https"] -> []
        _ -> [{field, "must be a valid URL starting with http:// or https://"}]
      end
    end)
  end
end
