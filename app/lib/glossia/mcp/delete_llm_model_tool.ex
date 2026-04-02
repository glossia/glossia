defmodule Glossia.MCP.DeleteLLMModelTool do
  @moduledoc "Delete an LLM model configuration from an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.LLMModels
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
    field :model_id, {:required, :string}, description: "ID of the model to delete"
  end

  @impl true
  def execute(%{"handle" => handle, "model_id" => model_id}, frame) do
    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :llm_model_write, user, account) do
      case LLMModels.get_model(model_id, account.id) do
        nil ->
          {:error, Hermes.MCP.Error.execution("Model not found"), frame}

        model ->
          case LLMModels.delete_model(account, user, model) do
            {:ok, _} ->
              response =
                Response.tool()
                |> Response.text(JSON.encode!(%{status: "deleted", handle: model.handle}))

              {:reply, response, frame}

            {:error, _} ->
              {:error, Hermes.MCP.Error.execution("Could not delete model"), frame}
          end
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
