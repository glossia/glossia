defmodule Glossia.MCP.ListKitsTool do
  @moduledoc "List translation terminology kits for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Kits
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle to list kits for."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :kit_read, user, account) do
      case Kits.list_kits(account) do
        {:ok, {kits, _meta}} ->
          serialized =
            Enum.map(kits, fn kit ->
              %{
                handle: kit.handle,
                name: kit.name,
                description: kit.description,
                source_language: kit.source_language,
                target_languages: kit.target_languages,
                domain_tags: kit.domain_tags,
                visibility: kit.visibility,
                stars_count: kit.stars_count,
                inserted_at: kit.inserted_at
              }
            end)

          response =
            Response.tool()
            |> Response.text(JSON.encode!(serialized))

          {:reply, response, frame}

        {:error, _} ->
          {:error, Hermes.MCP.Error.execution("Failed to list kits"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
