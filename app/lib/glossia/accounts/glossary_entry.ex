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
    |> cast(normalize_public_id(attrs), [:term, :logical_key, :definition, :case_sensitive])
    |> validate_required([:term])
    |> put_logical_key()
    |> unique_constraint([:glossary_id, :term])
    |> unique_constraint([:glossary_id, :logical_key])
  end

  # The public API surface (REST, MCP, repo glossary YAML) uses `id` for the
  # entry's stable identifier because that reads better in an API payload
  # than `logical_key`. Internally the column stays `logical_key` to leave
  # room for a future opaque row id without ambiguity, so map at the
  # boundary. An explicit **binary** `logical_key` still wins; a null or
  # non-string `logical_key` is dropped so `id` (or the term-derived
  # default) can take over. Non-string `id` is dropped for the same reason,
  # letting `validate_required(:term)` and the term-derived fallback pick
  # up.
  defp normalize_public_id(%{} = attrs) do
    attrs
    |> drop_non_string("logical_key")
    |> drop_non_string(:logical_key)
    |> promote_id_to_logical_key()
  end

  defp normalize_public_id(attrs), do: attrs

  defp drop_non_string(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_binary(value) -> attrs
      {:ok, _} -> Map.delete(attrs, key)
      :error -> attrs
    end
  end

  defp promote_id_to_logical_key(attrs) do
    cond do
      Map.has_key?(attrs, "logical_key") or Map.has_key?(attrs, :logical_key) ->
        attrs

      is_binary(attrs["id"]) ->
        Map.put(attrs, "logical_key", attrs["id"])

      is_binary(attrs[:id]) ->
        Map.put(attrs, :logical_key, attrs[:id])

      true ->
        attrs
    end
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

  @doc """
  Derives a stable logical key from a term.

  Preserves distinguishing punctuation by transliterating it into short
  tokens (`+` -> `plus`, `#` -> `sharp`, `.` -> `dot`, `&` -> `and`,
  `/` -> `slash`, `@` -> `at`) before slugification. This keeps
  `C++`, `C#`, `.net`, `Foo & Bar` from all collapsing to `c` / `foo-bar`
  and colliding under the new unique constraint. As a last resort the
  original term is returned verbatim when nothing else survives.
  """
  def slugify(term) when is_binary(term) do
    slug =
      term
      |> String.downcase()
      |> String.replace("++", "plusplus")
      |> String.replace("+", "plus")
      |> String.replace("#", "sharp")
      |> String.replace("&", "and")
      |> String.replace("@", "at")
      |> String.replace("%", "percent")
      |> String.replace(".", "dot")
      |> String.replace("/", "slash")
      |> String.replace(~r/[^\p{L}\p{N}]+/u, "-")
      |> String.trim("-")

    case slug do
      "" -> term
      slug -> slug
    end
  end
end
