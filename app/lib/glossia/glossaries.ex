defmodule Glossia.Glossaries do
  alias Glossia.Accounts.{Account, User, Glossary, GlossaryEntry, GlossaryTranslation}
  alias Glossia.Repo

  import Ecto.Query

  def get_latest_glossary(%Account{id: account_id}) do
    Glossary
    |> where(account_id: ^account_id)
    |> order_by(desc: :version)
    |> limit(1)
    |> preload(created_by: :account, entries: :translations)
    |> Repo.one()
  end

  def get_glossary_version(%Account{id: account_id}, version) do
    Glossary
    |> where(account_id: ^account_id, version: ^version)
    |> preload(created_by: :account, entries: :translations)
    |> Repo.one()
  end

  def get_previous_glossary_version(%Account{id: account_id}, version) do
    Glossary
    |> where([g], g.account_id == ^account_id and g.version < ^version)
    |> order_by(desc: :version)
    |> limit(1)
    |> preload(created_by: :account, entries: :translations)
    |> Repo.one()
  end

  def list_glossary_versions(%Account{id: account_id}, params \\ %{}) do
    query =
      Glossary
      |> where(account_id: ^account_id)
      |> preload(created_by: :account)

    Flop.validate_and_run(query, params, for: Glossary)
  end

  def create_glossary(%Account{id: account_id}, attrs, user \\ nil) do
    entries_attrs = attrs["entries"] || attrs[:entries] || []
    created_by_id = if match?(%User{}, user), do: user.id, else: nil

    Ecto.Multi.new()
    |> Ecto.Multi.run(:next_version, fn repo, _changes ->
      max =
        Glossary
        |> where(account_id: ^account_id)
        |> select([g], max(g.version))
        |> repo.one()

      {:ok, (max || 0) + 1}
    end)
    |> Ecto.Multi.insert(:glossary, fn %{next_version: version} ->
      %Glossary{account_id: account_id, created_by_id: created_by_id}
      |> Glossary.changeset(Map.put(attrs, :version, version))
    end)
    |> Ecto.Multi.run(:entries, fn repo, %{glossary: glossary} ->
      insert_entries(repo, glossary.id, entries_attrs)
    end)
    |> Repo.transaction()
  end

  def get_resolved_glossary(%Account{} = account, locale) do
    case get_latest_glossary(account) do
      nil ->
        nil

      glossary ->
        entries =
          glossary.entries
          |> Enum.map(fn entry ->
            translation = Enum.find(entry.translations, &(&1.locale == locale))

            %{
              term: entry.term,
              definition: entry.definition,
              case_sensitive: entry.case_sensitive,
              translation: if(translation, do: translation.translation)
            }
          end)
          |> Enum.filter(& &1.translation)

        %{
          version: glossary.version,
          locale: locale,
          entries: entries
        }
    end
  end

  defp insert_entries(repo, glossary_id, entries_attrs) do
    results =
      Enum.map(entries_attrs, fn entry_attrs ->
        translations_attrs = entry_attrs["translations"] || entry_attrs[:translations] || []

        with {:ok, entry} <-
               %GlossaryEntry{glossary_id: glossary_id}
               |> GlossaryEntry.changeset(entry_attrs)
               |> repo.insert() do
          translation_results =
            Enum.map(translations_attrs, fn t_attrs ->
              %GlossaryTranslation{glossary_entry_id: entry.id}
              |> GlossaryTranslation.changeset(t_attrs)
              |> repo.insert()
            end)

          case Enum.find(translation_results, &match?({:error, _}, &1)) do
            nil ->
              translations = Enum.map(translation_results, fn {:ok, t} -> t end)
              {:ok, %{entry | translations: translations}}

            {:error, changeset} ->
              {:error, changeset}
          end
        end
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(results, fn {:ok, e} -> e end)}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
