defmodule Glossia.Kits do
  @moduledoc """
  Context for managing kits: shareable translation terminology bundles.
  """

  require OpenTelemetry.Tracer, as: Tracer

  import Ecto.Query

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Kits.{Kit, KitEntry, KitEntryTranslation, KitStar}

  @entry_preloads [:translations]
  @kit_preloads [:created_by, :account, entries: @entry_preloads]

  # --- Kits ---

  def list_kits(%Account{} = account, params \\ %{}) do
    query =
      from k in Kit,
        where: k.account_id == ^account.id,
        preload: [:created_by]

    Flop.validate_and_run(query, params, for: Kit)
  end

  def list_public_kits(%Account{} = account, params \\ %{}) do
    query =
      from k in Kit,
        where: k.account_id == ^account.id and k.visibility == "public",
        preload: [:created_by]

    Flop.validate_and_run(query, params, for: Kit)
  end

  def get_kit!(id) do
    Repo.one!(
      from k in Kit,
        where: k.id == ^id,
        preload: ^@kit_preloads
    )
  end

  def get_kit_by_handle(%Account{} = account, handle) do
    Repo.one(
      from k in Kit,
        where: k.account_id == ^account.id and k.handle == ^handle,
        preload: ^@kit_preloads
    )
  end

  def create_kit(%Account{} = account, %User{} = user, attrs) do
    Tracer.with_span "glossia.kits.create_kit" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.user.id", to_string(user.id)}
      ])

      %Kit{}
      |> Kit.changeset(attrs)
      |> Ecto.Changeset.put_change(:account_id, account.id)
      |> Ecto.Changeset.put_change(:created_by_id, user.id)
      |> Repo.insert()
    end
  end

  def update_kit(%Kit{} = kit, attrs) do
    Tracer.with_span "glossia.kits.update_kit" do
      Tracer.set_attributes([{"glossia.kit.id", to_string(kit.id)}])

      kit
      |> Kit.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_kit(%Kit{} = kit) do
    Tracer.with_span "glossia.kits.delete_kit" do
      Tracer.set_attributes([{"glossia.kit.id", to_string(kit.id)}])
      Repo.delete(kit)
    end
  end

  def change_kit(attrs \\ %{}) do
    Kit.changeset(%Kit{}, attrs)
  end

  # --- Entries ---

  def add_entry(%Kit{} = kit, attrs) do
    Tracer.with_span "glossia.kits.add_entry" do
      Tracer.set_attributes([{"glossia.kit.id", to_string(kit.id)}])

      translations = Map.get(attrs, "translations") || Map.get(attrs, :translations) || []

      Repo.transaction(fn ->
        entry_result =
          %KitEntry{}
          |> KitEntry.changeset(attrs)
          |> Ecto.Changeset.put_change(:kit_id, kit.id)
          |> Repo.insert()

        case entry_result do
          {:ok, entry} ->
            translations =
              Enum.map(translations, fn t_attrs ->
                {:ok, translation} =
                  %KitEntryTranslation{}
                  |> KitEntryTranslation.changeset(t_attrs)
                  |> Ecto.Changeset.put_change(:kit_entry_id, entry.id)
                  |> Repo.insert()

                translation
              end)

            %{entry | translations: translations}

          {:error, changeset} ->
            Repo.rollback({:validation, changeset})
        end
      end)
      |> case do
        {:ok, entry} -> {:ok, entry}
        {:error, {:validation, changeset}} -> {:error, changeset}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def update_entry(%KitEntry{} = entry, attrs) do
    Tracer.with_span "glossia.kits.update_entry" do
      Tracer.set_attributes([{"glossia.kit_entry.id", to_string(entry.id)}])

      translations = Map.get(attrs, "translations") || Map.get(attrs, :translations)

      Repo.transaction(fn ->
        entry_result =
          entry
          |> KitEntry.changeset(attrs)
          |> Repo.update()

        case entry_result do
          {:ok, updated_entry} ->
            if translations do
              # Delete existing translations and re-insert
              from(t in KitEntryTranslation, where: t.kit_entry_id == ^updated_entry.id)
              |> Repo.delete_all()

              new_translations =
                Enum.map(translations, fn t_attrs ->
                  {:ok, translation} =
                    %KitEntryTranslation{}
                    |> KitEntryTranslation.changeset(t_attrs)
                    |> Ecto.Changeset.put_change(:kit_entry_id, updated_entry.id)
                    |> Repo.insert()

                  translation
                end)

              %{updated_entry | translations: new_translations}
            else
              Repo.preload(updated_entry, :translations)
            end

          {:error, changeset} ->
            Repo.rollback({:validation, changeset})
        end
      end)
      |> case do
        {:ok, entry} -> {:ok, entry}
        {:error, {:validation, changeset}} -> {:error, changeset}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def delete_entry(%KitEntry{} = entry) do
    Tracer.with_span "glossia.kits.delete_entry" do
      Tracer.set_attributes([{"glossia.kit_entry.id", to_string(entry.id)}])
      Repo.delete(entry)
    end
  end

  def get_entry!(id) do
    Repo.one!(
      from e in KitEntry,
        where: e.id == ^id,
        preload: ^@entry_preloads
    )
  end

  # --- Stars ---

  def star_kit(%Kit{} = kit, %User{} = user) do
    Tracer.with_span "glossia.kits.star_kit" do
      Repo.transaction(fn ->
        star_result =
          %KitStar{}
          |> KitStar.changeset(%{})
          |> Ecto.Changeset.put_change(:kit_id, kit.id)
          |> Ecto.Changeset.put_change(:user_id, user.id)
          |> Repo.insert()

        case star_result do
          {:ok, star} ->
            from(k in Kit, where: k.id == ^kit.id)
            |> Repo.update_all(inc: [stars_count: 1])

            star

          {:error, changeset} ->
            Repo.rollback({:validation, changeset})
        end
      end)
      |> case do
        {:ok, star} -> {:ok, star}
        {:error, {:validation, changeset}} -> {:error, changeset}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def unstar_kit(%Kit{} = kit, %User{} = user) do
    Tracer.with_span "glossia.kits.unstar_kit" do
      star =
        Repo.one(
          from s in KitStar,
            where: s.kit_id == ^kit.id and s.user_id == ^user.id
        )

      case star do
        nil ->
          {:error, :not_found}

        %KitStar{} = star ->
          Repo.transaction(fn ->
            Repo.delete!(star)

            from(k in Kit, where: k.id == ^kit.id)
            |> Repo.update_all(inc: [stars_count: -1])

            :ok
          end)
      end
    end
  end

  def starred_by?(%Kit{} = kit, %User{} = user) do
    Repo.exists?(
      from s in KitStar,
        where: s.kit_id == ^kit.id and s.user_id == ^user.id
    )
  end
end
