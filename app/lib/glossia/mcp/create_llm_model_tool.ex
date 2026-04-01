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
      description: "Model ID in provider:model format (e.g. anthropic:claude-sonnet-4-20250514)"

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
    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :llm_model_write, user, account) do
      attrs = %{
        "handle" => model_handle,
        "model" => model,
        "api_key" => api_key
      }

      case LLMModels.create_model(account, user, attrs) do
        {:ok, created} ->
          Glossia.Auditing.record("llm_model.created", account, user,
            resource_type: "llm_model",
            resource_id: to_string(created.id),
            resource_path: "/#{account.handle}/-/settings/models",
            summary: "Created LLM model \"#{created.handle}\""
          )

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
