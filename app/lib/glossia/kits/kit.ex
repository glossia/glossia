defmodule Glossia.Kits.Kit do
  use Glossia.Schema
  import Ecto.Changeset
  import Glossia.Validations

  @derive {
    Flop.Schema,
    filterable: [:name, :visibility, :source_language, :inserted_at],
    sortable: [:name, :source_language, :inserted_at],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  @visibilities ~w(public private)

  schema "kits" do
    field :handle, :string
    field :name, :string
    field :description, :string
    field :source_language, :string
    field :target_languages, {:array, :string}, default: []
    field :domain_tags, {:array, :string}, default: []
    field :visibility, :string, default: "public"
    field :stars_count, :integer, virtual: true, default: 0

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :created_by, Glossia.Accounts.User

    has_many :entries, Glossia.Kits.KitEntry
    has_many :stars, Glossia.Kits.KitStar

    timestamps()
  end

  def changeset(kit, attrs) do
    kit
    |> cast(attrs, [
      :handle,
      :name,
      :description,
      :source_language,
      :target_languages,
      :domain_tags,
      :visibility
    ])
    |> validate_required([:handle, :name, :source_language])
    |> validate_handle(:handle, min: 1, max: 64)
    |> validate_locale(:source_language)
    |> validate_locales(:target_languages)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_inclusion(:visibility, @visibilities)
    |> unique_constraint([:account_id, :handle])
  end
end
