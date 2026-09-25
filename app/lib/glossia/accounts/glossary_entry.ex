defmodule Glossia.Accounts.GlossaryEntry do
  use Glossia.Schema
  import Ecto.Changeset

  schema "glossary_entries" do
    field :term, :string
    field :logical_key, :string
    field :definition, :string
    field :case_sensitive, :boolean, default: false

    belongs_to :glossary, Glossia.Accounts.Glossary
    has_many :translations, Glossia.Accounts.GlossaryTranslation

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:term, :logical_key, :definition, :case_sensitive])
    |> validate_required([:term])
    |> put_logical_key()
    |> unique_constraint([:glossary_id, :term])
    |> unique_constraint([:glossary_id, :logical_key])
  end

  # Logical keys stay stable across versions of the same glossary so the
  # lockfile can reference an entry by concept rather than by row id (row ids
  # are re-minted each version). If the caller does not provide one, derive it
  # from the term on first save.
  defp put_logical_key(changeset) do
    case get_field(changeset, :logical_key) do
      nil ->
        case get_change(changeset, :term) || get_field(changeset, :term) do
          nil -> changeset
          term -> put_change(changeset, :logical_key, slugify(term))
        end

      _ ->
        changeset
    end
  end

  @doc "Derives a stable logical key from a term."
  def slugify(term) when is_binary(term) do
    term
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{N}]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> term
      slug -> slug
    end
  end
end
