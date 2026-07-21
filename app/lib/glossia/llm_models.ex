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
  Returns the account's default translation model.

  Prefers the model explicitly flagged as `default`; otherwise falls back to the
  first model by handle for legacy data that has not been backfilled. Returns
  `nil` when the account has no models.
  """
  def default_model(%Account{} = account), do: default_model(account.id)

  def default_model(account_id) do
    Repo.one(
      from m in LLMModel,
        where: m.account_id == ^account_id,
        order_by: [desc: m.default, asc: m.handle],
        limit: 1
    )
  end

  def create_model(%Account{} = account, %User{} = user, attrs) do
    result =
      Repo.transaction(fn ->
        make_default? = requested_default?(attrs) or not account_has_models?(account.id)

        if make_default?, do: clear_default(account.id)

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
        if requested_default?(attrs), do: clear_default(account.id)

        case model
             |> LLMModel.changeset(attrs, require_api_key: false)
             |> Repo.update() do
          {:ok, updated} ->
            ensure_default(account.id)
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
        case Repo.delete(model) do
          {:ok, deleted} ->
            ensure_default(account.id)
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

  defp account_has_models?(account_id) do
    Repo.exists?(from m in LLMModel, where: m.account_id == ^account_id)
  end

  defp clear_default(account_id) do
    Repo.update_all(
      from(m in LLMModel, where: m.account_id == ^account_id and m.default == true),
      set: [default: false]
    )
  end

  defp ensure_default(account_id) do
    if account_has_models?(account_id) and not explicitly_defaulted?(account_id) do
      account_id
      |> first_model()
      |> Ecto.Changeset.change(default: true)
      |> Repo.update!()
    end
  end

  defp explicitly_defaulted?(account_id) do
    Repo.exists?(
      from m in LLMModel,
        where: m.account_id == ^account_id and m.default == true
    )
  end

  defp first_model(account_id) do
    Repo.one!(
      from m in LLMModel,
        where: m.account_id == ^account_id,
        order_by: [asc: m.handle],
        limit: 1
    )
  end

  defp requested_default?(attrs) do
    Map.get(attrs, "default") in [true, "true", 1, "1"] or
      Map.get(attrs, :default) in [true, "true", 1, "1"]
  end
end
