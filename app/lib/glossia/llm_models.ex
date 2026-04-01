defmodule Glossia.LlmModels do
  @moduledoc """
  Context for managing LLM model configurations per account.
  """

  import Ecto.Query

  alias Glossia.Accounts.{Account, LlmModel}
  alias Glossia.Repo

  def list_models(%Account{} = account, params \\ %{}) do
    LlmModel
    |> where(account_id: ^account.id)
    |> Flop.validate_and_run(params, for: LlmModel)
  end

  def get_model!(id, account_id) do
    Repo.one!(
      from m in LlmModel,
        where: m.id == ^id and m.account_id == ^account_id
    )
  end

  def get_model(id, account_id) do
    Repo.one(
      from m in LlmModel,
        where: m.id == ^id and m.account_id == ^account_id
    )
  end

  def get_model_by_handle(handle, account_id) do
    Repo.one(
      from m in LlmModel,
        where: m.handle == ^handle and m.account_id == ^account_id
    )
  end

  def create_model(%Account{} = account, %Glossia.Accounts.User{} = user, attrs) do
    %LlmModel{}
    |> LlmModel.changeset(attrs)
    |> Ecto.Changeset.put_change(:account_id, account.id)
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Repo.insert()
  end

  def update_model(%LlmModel{} = model, attrs) do
    model
    |> LlmModel.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_model(%LlmModel{} = model) do
    Repo.delete(model)
  end

  def change_model(%LlmModel{} = model, attrs \\ %{}) do
    LlmModel.changeset(model, attrs)
  end
end
