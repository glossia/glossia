defmodule Glossia.Glossaries do
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Accounts.{Account, User, Glossary, GlossaryEntry, GlossaryTranslation}
  alias Glossia.Events
  alias Glossia.Repo

  import Ecto.Query

  def latest_glossary_version(%Account{id: account_id}) do
    Tracer.with_span "glossia.glossaries.latest_glossary_version" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      Glossary
      |> where(account_id: ^account_id)
      |> select([glossary], max(glossary.version))
      |> Repo.one()
    end
  end

  def get_latest_glossary(%Account{id: account_id}) do
    Tracer.with_span "glossia.glossaries.get_latest_glossary" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      Glossary
      |> where(account_id: ^account_id)
      |> order_by(desc: :version)
      |> limit(1)
      |> preload(created_by: :account, entries: :translations)
      |> Repo.one()
    end
  end

  def get_glossary_version(%Account{id: account_id}, version) do
    Tracer.with_span "glossia.glossaries.get_glossary_version" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.glossary.version", version}
      ])

      Glossary
      |> where(account_id: ^account_id, version: ^version)
      |> preload(created_by: :account, entries: :translations)
      |> Repo.one()
    end
  end

  def get_previous_glossary_version(%Account{id: account_id}, version) do
    Tracer.with_span "glossia.glossaries.get_previous_glossary_version" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.glossary.version", version}
      ])

      Glossary
      |> where([g], g.account_id == ^account_id and g.version < ^version)
      |> order_by(desc: :version)
      |> limit(1)
      |> preload(created_by: :account, entries: :translations)
      |> Repo.one()
    end
  end

  def list_glossary_versions(%Account{id: account_id}, params \\ %{}) do
    Tracer.with_span "glossia.glossaries.list_glossary_versions" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      query =
        Glossary
        |> where(account_id: ^account_id)
        |> preload(created_by: :account)

      Flop.validate_and_run(query, params, for: Glossary)
    end
  end

  def create_glossary(%Account{id: account_id} = account, attrs, user \\ nil, opts \\ []) do
    Tracer.with_span "glossia.glossaries.create_glossary" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.user.id", if(match?(%User{}, user), do: to_string(user.id), else: "")}
      ])

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
      |> case do
        {:ok, %{glossary: glossary}} = ok ->
          Tracer.set_attributes([{"glossia.glossary.version", glossary.version}])

          if match?(%User{}, user) do
            Events.emit("glossary.created", account, user,
              resource_type: "glossary",
              resource_id: to_string(glossary.version),
              resource_path: "/#{account.handle}/-/terminology/#{glossary.version}",
              summary: glossary.change_note || "Updated terminology.",
              via: Keyword.get(opts, :via)
            )
          end

          ok

        other ->
          other
      end
    end
  end

  def get_resolved_glossary(%Account{} = account, locale) do
    Tracer.with_span "glossia.glossaries.get_resolved_glossary" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.locale", to_string(locale)}
      ])

      case latest_glossary_version(account) do
        nil -> nil
        version -> get_resolved_glossary_version(account, version, locale)
      end
    end
  end

  def get_resolved_glossary_version(%Account{id: account_id}, version, locale)
      when is_integer(version) and is_binary(locale) do
    Tracer.with_span "glossia.glossaries.get_resolved_glossary_version" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.glossary.version", version},
        {"glossia.locale", locale}
      ])

      locale_candidates = locale_candidates(locale)
      locale_ranks = locale_candidates |> Enum.with_index() |> Map.new()

      entries =
        from(glossary in Glossary,
          join: entry in GlossaryEntry,
          on: entry.glossary_id == glossary.id,
          join: translation in GlossaryTranslation,
          on:
            translation.glossary_entry_id == entry.id and
              translation.locale in ^locale_candidates,
          where: glossary.account_id == ^account_id and glossary.version == ^version,
          order_by: [asc: entry.term],
          select: %{
            id: entry.id,
            term: entry.term,
            definition: entry.definition,
            case_sensitive: entry.case_sensitive,
            translation: translation.translation,
            translation_locale: translation.locale
          }
        )
        |> Repo.all()
        |> Enum.sort_by(fn entry ->
          {entry.term, Map.fetch!(locale_ranks, entry.translation_locale)}
        end)
        |> Enum.uniq_by(& &1.id)
        |> Enum.map(&Map.delete(&1, :translation_locale))

      %{
        version: version,
        locale: locale,
        entries: entries
      }
    end
  end

  defp locale_candidates(locale) do
    parts =
      locale
      |> String.replace("_", "-")
      |> String.split("-", trim: true)

    case parts do
      [] ->
        [locale]

      parts ->
        Enum.map(length(parts)..1//-1, fn count ->
          parts |> Enum.take(count) |> Enum.join("-")
        end)
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
