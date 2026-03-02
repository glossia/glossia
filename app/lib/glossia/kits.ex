defmodule Glossia.Kits do
  @moduledoc """
  Context for managing kits: shareable translation terminology bundles.
  """

  require OpenTelemetry.Tracer, as: Tracer

  import Ecto.Query

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Kits.{Kit, KitTerm, KitTermTranslation, KitStar}

  @term_preloads [:translations]
  @kit_preloads [:created_by, :account, terms: @term_preloads]

  defp with_stars_count(query) do
    stars_subquery =
      from s in KitStar,
        where: s.kit_id == parent_as(:kit).id,
        select: count(s.id)

    from k in query,
      as: :kit,
      select_merge: %{stars_count: subquery(stars_subquery)}
  end

  # --- Kits ---

  def list_kits(%Account{} = account, params \\ %{}) do
    query =
      from(k in Kit,
        where: k.account_id == ^account.id,
        preload: [:created_by]
      )
      |> with_stars_count()

    Flop.validate_and_run(query, params, for: Kit)
  end

  def list_public_kits(%Account{} = account, params \\ %{}) do
    query =
      from(k in Kit,
        where: k.account_id == ^account.id and k.visibility == "public",
        preload: [:created_by]
      )
      |> with_stars_count()

    Flop.validate_and_run(query, params, for: Kit)
  end

  def get_kit!(id) do
    from(k in Kit,
      where: k.id == ^id,
      preload: ^@kit_preloads
    )
    |> with_stars_count()
    |> Repo.one!()
  end

  def get_kit_by_handle(%Account{} = account, handle) do
    from(k in Kit,
      where: k.account_id == ^account.id and k.handle == ^handle,
      preload: ^@kit_preloads
    )
    |> with_stars_count()
    |> Repo.one()
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

  # --- Terms ---

  def add_term(%Kit{} = kit, attrs) do
    Tracer.with_span "glossia.kits.add_term" do
      Tracer.set_attributes([{"glossia.kit.id", to_string(kit.id)}])

      translations = Map.get(attrs, "translations") || Map.get(attrs, :translations) || []

      Repo.transaction(fn ->
        term_result =
          %KitTerm{}
          |> KitTerm.changeset(attrs)
          |> Ecto.Changeset.put_change(:kit_id, kit.id)
          |> Repo.insert()

        case term_result do
          {:ok, term} ->
            translations =
              Enum.map(translations, fn t_attrs ->
                {:ok, translation} =
                  %KitTermTranslation{}
                  |> KitTermTranslation.changeset(t_attrs)
                  |> Ecto.Changeset.put_change(:kit_term_id, term.id)
                  |> Repo.insert()

                translation
              end)

            %{term | translations: translations}

          {:error, changeset} ->
            Repo.rollback({:validation, changeset})
        end
      end)
      |> case do
        {:ok, term} -> {:ok, term}
        {:error, {:validation, changeset}} -> {:error, changeset}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def update_term(%KitTerm{} = term, attrs) do
    Tracer.with_span "glossia.kits.update_term" do
      Tracer.set_attributes([{"glossia.kit_term.id", to_string(term.id)}])

      translations = Map.get(attrs, "translations") || Map.get(attrs, :translations)

      Repo.transaction(fn ->
        term_result =
          term
          |> KitTerm.changeset(attrs)
          |> Repo.update()

        case term_result do
          {:ok, updated_term} ->
            if translations do
              from(t in KitTermTranslation, where: t.kit_term_id == ^updated_term.id)
              |> Repo.delete_all()

              new_translations =
                Enum.map(translations, fn t_attrs ->
                  {:ok, translation} =
                    %KitTermTranslation{}
                    |> KitTermTranslation.changeset(t_attrs)
                    |> Ecto.Changeset.put_change(:kit_term_id, updated_term.id)
                    |> Repo.insert()

                  translation
                end)

              %{updated_term | translations: new_translations}
            else
              Repo.preload(updated_term, :translations)
            end

          {:error, changeset} ->
            Repo.rollback({:validation, changeset})
        end
      end)
      |> case do
        {:ok, term} -> {:ok, term}
        {:error, {:validation, changeset}} -> {:error, changeset}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def delete_term(%KitTerm{} = term) do
    Tracer.with_span "glossia.kits.delete_term" do
      Tracer.set_attributes([{"glossia.kit_term.id", to_string(term.id)}])
      Repo.delete(term)
    end
  end

  def get_term!(id) do
    Repo.one!(
      from t in KitTerm,
        where: t.id == ^id,
        preload: ^@term_preloads
    )
  end

  # --- Stars ---

  def star_kit(%Kit{} = kit, %User{} = user) do
    Tracer.with_span "glossia.kits.star_kit" do
      %KitStar{}
      |> KitStar.changeset(%{})
      |> Ecto.Changeset.put_change(:kit_id, kit.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Repo.insert()
    end
  end

  def unstar_kit(%Kit{} = kit, %User{} = user) do
    Tracer.with_span "glossia.kits.unstar_kit" do
      case Repo.one(from s in KitStar, where: s.kit_id == ^kit.id and s.user_id == ^user.id) do
        nil -> {:error, :not_found}
        %KitStar{} = star -> Repo.delete(star)
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
