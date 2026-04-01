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
    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :llm_model_write, user, account) do
      case LLMModels.get_model(model_id, account.id) do
        nil ->
          {:error, Hermes.MCP.Error.execution("Model not found"), frame}

        model ->
          case LLMModels.delete_model(model) do
            {:ok, _} ->
              Glossia.Auditing.record("llm_model.deleted", account, user,
                resource_type: "llm_model",
                resource_id: to_string(model.id),
                resource_path: "/#{account.handle}/-/settings/models",
                summary: "Deleted LLM model \"#{model.handle}\""
              )

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
