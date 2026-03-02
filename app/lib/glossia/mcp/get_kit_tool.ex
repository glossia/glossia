defmodule Glossia.MCP.GetKitTool do
  @moduledoc "Get a translation terminology kit by handle, including all terms and translations."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Kits
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle."
    field :kit_handle, {:required, :string}, description: "Kit handle within the account."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]
    kit_handle = params["kit_handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :kit_read, user, account) do
      case Kits.get_kit_by_handle(account, kit_handle) do
        nil ->
          {:error, Hermes.MCP.Error.execution("Kit '#{kit_handle}' not found for '#{handle}'"),
           frame}

        kit ->
          serialized = %{
            handle: kit.handle,
            name: kit.name,
            description: kit.description,
            source_language: kit.source_language,
            target_languages: kit.target_languages,
            domain_tags: kit.domain_tags,
            visibility: kit.visibility,
            stars_count: kit.stars_count,
            inserted_at: kit.inserted_at,
            terms:
              Enum.map(kit.terms, fn term ->
                %{
                  id: term.id,
                  source_term: term.source_term,
                  definition: term.definition,
                  tags: term.tags,
                  translations:
                    Enum.map(term.translations, fn t ->
                      %{
                        language: t.language,
                        translated_term: t.translated_term,
                        usage_note: t.usage_note
                      }
                    end)
                }
              end)
          }

          response =
            Response.tool()
            |> Response.text(JSON.encode!(serialized))

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
