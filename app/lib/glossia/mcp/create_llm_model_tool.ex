defmodule Glossia.MCP.CreateLLMModelTool do
  @moduledoc "Create an LLM model configuration for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.LLMModels
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"

    field :model_handle, {:required, :string},
      description: "Unique handle for the model within the account"

    field :model, {:required, :string},
      description:
        "Model ID in provider:model format (e.g. anthropic:claude-sonnet-4-20250514). Browse available models at https://models.dev"

    field :api_key, {:required, :string}, description: "Provider API key"
  end

  @impl true
  def execute(
        %{
          "handle" => handle,
          "model_handle" => model_handle,
          "model" => model,
          "api_key" => api_key
        },
        frame
      ) do
    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :llm_model_write, user, account) do
      attrs = %{
        "handle" => model_handle,
        "model" => model,
        "api_key" => api_key
      }

      case LLMModels.create_model(account, user, attrs) do
        {:ok, created} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                id: created.id,
                handle: created.handle,
                model: created.model
              })
            )

          {:reply, response, frame}

        {:error, _changeset} ->
          {:error, Hermes.MCP.Error.execution("Could not create model"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
