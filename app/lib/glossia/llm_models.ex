defmodule Glossia.LLMModels do
  @moduledoc """
  Context for managing LLM model configurations per account.
  """

  import Ecto.Query

  alias Glossia.Accounts.{Account, LLMModel}
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

  def create_model(%Account{} = account, %Glossia.Accounts.User{} = user, attrs) do
    %LLMModel{}
    |> LLMModel.changeset(attrs)
    |> Ecto.Changeset.put_change(:account_id, account.id)
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Repo.insert()
  end

  def update_model(%LLMModel{} = model, attrs) do
    model
    |> LLMModel.changeset(attrs, require_api_key: false)
    |> Repo.update()
  end

  def delete_model(%LLMModel{} = model) do
    Repo.delete(model)
  end

  def change_model(%LLMModel{} = model, attrs \\ %{}) do
    LLMModel.changeset(model, attrs)
  end
end
