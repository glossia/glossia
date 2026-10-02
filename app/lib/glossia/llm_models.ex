defmodule Glossia.LLMModels do
  @moduledoc """
  Context for managing LLM model configurations per account.
  """

  use GlossiaWeb, :verified_routes

  import Ecto.Query

  alias Glossia.Accounts.{Account, LLMModel, User}
  alias Glossia.Events
  alias Glossia.Repo

  def list_models(%Account{} = account, params \\ %{}) do
    LLMModel
    |> where(account_id: ^account.id)
    |> Flop.validate_and_run(params, for: LLMModel)
  end

  def get_model!(id, account_id) do
    Repo.one!(
      from m in LLMModel,
        where: m.id == ^id and m.account_id == ^account_id
    )
  end

  def get_model(id, account_id) do
    Repo.one(
      from m in LLMModel,
        where: m.id == ^id and m.account_id == ^account_id
    )
  end

  def get_model_by_handle(handle, account_id) do
    Repo.one(
      from m in LLMModel,
        where: m.handle == ^handle and m.account_id == ^account_id
    )
  end

  @doc """
  Returns the account's default model for a category (generative by default).

  Prefers the model explicitly flagged as `default`; otherwise falls back to the
  first model by handle for legacy data that has not been backfilled. Returns
  `nil` when the account has no models.
  """
  def default_model(account, category \\ "generative")

  def default_model(%Account{} = account, category), do: default_model(account.id, category)

  def default_model(account_id, category) do
    Repo.one(
      from m in LLMModel,
        where: m.account_id == ^account_id and m.category == ^category,
        order_by: [desc: m.default, asc: m.handle],
        limit: 1
    )
  end

  def create_model(%Account{} = account, %User{} = user, attrs) do
    result =
      Repo.transaction(fn ->
        lock_account(account.id)
        initial_changeset = LLMModel.changeset(%LLMModel{}, attrs)
        unless initial_changeset.valid?, do: Repo.rollback(%{initial_changeset | action: :insert})
        category = Ecto.Changeset.get_field(initial_changeset, :category)
        make_default? = requested_default?(attrs) or not account_has_models?(account.id, category)

        if make_default?, do: clear_default(account.id, category)

        changeset =
          %LLMModel{}
          |> LLMModel.changeset(attrs)
          |> Ecto.Changeset.put_change(:account_id, account.id)
          |> Ecto.Changeset.put_change(:created_by_id, user.id)
          |> Ecto.Changeset.put_change(:default, make_default?)

        case Repo.insert(changeset) do
          {:ok, model} -> model
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    with {:ok, model} <- result do
      Events.emit("llm_model.created", account, user,
        resource_type: "llm_model",
        resource_id: to_string(model.id),
        resource_path: ~p"/#{account.handle}/-/settings/models",
        summary: "Created LLM model \"#{model.handle}\""
      )

      {:ok, model}
    end
  end

  def update_model(%Account{} = account, %User{} = user, %LLMModel{} = model, attrs) do
    result =
      Repo.transaction(fn ->
        lock_account(account.id)
        model = current_model!(model, account.id, :update)
        changeset = LLMModel.changeset(model, attrs, require_api_key: false)
        unless changeset.valid?, do: Repo.rollback(%{changeset | action: :update})
        category = Ecto.Changeset.get_field(changeset, :category)
        changeset = prevent_routed_decision_model(changeset, model, category)

        make_default? =
          requested_default?(attrs) or
            (category != model.category and Ecto.Changeset.get_field(changeset, :default))

        changeset =
          if make_default? do
            clear_default(account.id, category)
            Ecto.Changeset.force_change(changeset, :default, true)
          else
            changeset
          end

        case Repo.update(changeset) do
          {:ok, updated} ->
            ensure_default(account.id, model.category)
            ensure_default(account.id, category)
            Repo.get!(LLMModel, updated.id)

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)

    with {:ok, updated} <- result do
      Events.emit("llm_model.updated", account, user,
        resource_type: "llm_model",
        resource_id: to_string(updated.id),
        resource_path: ~p"/#{account.handle}/-/settings/models/#{updated.id}",
        summary: "Updated LLM model \"#{updated.handle}\""
      )

      {:ok, updated}
    end
  end

  def delete_model(%Account{} = account, %User{} = user, %LLMModel{} = model) do
    result =
      Repo.transaction(fn ->
        lock_account(account.id)
        model = current_model!(model, account.id, :delete)

        case Repo.delete(model) do
          {:ok, deleted} ->
            ensure_default(account.id, model.category)
            deleted

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)

    with {:ok, deleted} <- result do
      Events.emit("llm_model.deleted", account, user,
        resource_type: "llm_model",
        resource_id: to_string(deleted.id),
        resource_path: ~p"/#{account.handle}/-/settings/models",
        summary: "Deleted LLM model \"#{deleted.handle}\""
      )

      {:ok, deleted}
    end
  end

  def change_model(%LLMModel{} = model, attrs \\ %{}) do
    LLMModel.changeset(model, attrs)
  end

  def change_model(%LLMModel{} = model, attrs, opts) do
    LLMModel.changeset(model, attrs, opts)
  end

  defp account_has_models?(account_id, category) do
    Repo.exists?(
      from m in LLMModel, where: m.account_id == ^account_id and m.category == ^category
    )
  end

  defp clear_default(account_id, category) do
    Repo.update_all(
      from(m in LLMModel,
        where: m.account_id == ^account_id and m.category == ^category and m.default == true
      ),
      set: [default: false]
    )
  end

  defp ensure_default(account_id, category) do
    if account_has_models?(account_id, category) and
         not explicitly_defaulted?(account_id, category) do
      account_id
      |> first_model(category)
      |> Ecto.Changeset.change(default: true)
      |> Repo.update!()
    end
  end

  defp explicitly_defaulted?(account_id, category) do
    Repo.exists?(
      from m in LLMModel,
        where: m.account_id == ^account_id and m.category == ^category and m.default == true
    )
  end

  defp first_model(account_id, category) do
    Repo.one!(
      from m in LLMModel,
        where: m.account_id == ^account_id and m.category == ^category,
        order_by: [asc: m.handle],
        limit: 1
    )
  end

  defp current_model!(model, account_id, action) do
    case get_model(model.id, account_id) do
      nil ->
        changeset =
          model
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:base, "model no longer exists")

        Repo.rollback(%{changeset | action: action})

      current ->
        current
    end
  end

  defp lock_account(account_id) do
    Repo.one!(from a in Account, where: a.id == ^account_id, lock: "FOR UPDATE")
  end

  defp prevent_routed_decision_model(changeset, model, "decision") do
    if Repo.exists?(
         from r in Glossia.Accounts.TranslationRoutingRule, where: r.llm_model_id == ^model.id
       ) do
      Ecto.Changeset.add_error(
        changeset,
        :category,
        "remove translation routing rules before changing this model to a decision model"
      )
    else
      changeset
    end
  end

  defp prevent_routed_decision_model(changeset, _model, _category), do: changeset

  defp requested_default?(attrs) do
    Map.get(attrs, "default") in [true, "true", 1, "1"] or
      Map.get(attrs, :default) in [true, "true", 1, "1"]
  end
end
