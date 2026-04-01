defmodule Glossia.LLMModels do
  @moduledoc """
  Context for managing LLM model configurations per account.
  """

  import Ecto.Query

  alias Glossia.Accounts.{Account, LLMModel, User}
  alias Glossia.Auditing
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

  def create_model(%Account{} = account, %User{} = user, attrs) do
    result =
      %LLMModel{}
      |> LLMModel.changeset(attrs)
      |> Ecto.Changeset.put_change(:account_id, account.id)
      |> Ecto.Changeset.put_change(:created_by_id, user.id)
      |> Repo.insert()

    with {:ok, model} <- result do
      Auditing.record("llm_model.created", account, user,
        resource_type: "llm_model",
        resource_id: to_string(model.id),
        resource_path: "/#{account.handle}/-/settings/models",
        summary: "Created LLM model \"#{model.handle}\""
      )

      {:ok, model}
    end
  end

  def update_model(%Account{} = account, %User{} = user, %LLMModel{} = model, attrs) do
    result =
      model
      |> LLMModel.changeset(attrs, require_api_key: false)
      |> Repo.update()

    with {:ok, updated} <- result do
      Auditing.record("llm_model.updated", account, user,
        resource_type: "llm_model",
        resource_id: to_string(updated.id),
        resource_path: "/#{account.handle}/-/settings/models/#{updated.id}",
        summary: "Updated LLM model \"#{updated.handle}\""
      )

      {:ok, updated}
    end
  end

  def delete_model(%Account{} = account, %User{} = user, %LLMModel{} = model) do
    result = Repo.delete(model)

    with {:ok, deleted} <- result do
      Auditing.record("llm_model.deleted", account, user,
        resource_type: "llm_model",
        resource_id: to_string(deleted.id),
        resource_path: "/#{account.handle}/-/settings/models",
        summary: "Deleted LLM model \"#{deleted.handle}\""
      )

      {:ok, deleted}
    end
  end

  def change_model(%LLMModel{} = model, attrs \\ %{}) do
    LLMModel.changeset(model, attrs)
  end
end
