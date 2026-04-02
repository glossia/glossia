defmodule Glossia.MCP.ListLLMModelsTool do
  @moduledoc "List LLM model configurations for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.LLMModels
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
  end

  @impl true
  def execute(%{"handle" => handle}, frame) do
    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :llm_model_read, user, account) do
      {:ok, {models, _meta}} = LLMModels.list_models(account)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(models, fn m ->
              %{
                id: m.id,
                handle: m.handle,
                model: m.model,
                inserted_at: m.inserted_at,
                updated_at: m.updated_at
              }
            end)
          )
        )

      {:reply, response, frame}
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
