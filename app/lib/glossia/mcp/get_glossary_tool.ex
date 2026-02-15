defmodule Glossia.MCP.GetGlossaryTool do
  @moduledoc "Get the current glossary for an account, optionally resolved for a specific locale."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Glossaries
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle to get glossary for."

    field :locale, :string,
      description:
        "Optional locale (e.g. 'ja', 'de', 'es-MX'). If provided, returns only entries with translations for that locale."

    field :version, :integer,
      description:
        "Optional version number. If provided, returns that specific version instead of the latest."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :glossary_read, user, account) do
      locale = params["locale"]
      version = params["version"]

      glossary =
        cond do
          locale ->
            Glossaries.get_resolved_glossary(account, locale)

          version ->
            Glossaries.get_glossary_version(account, version)

          true ->
            Glossaries.get_latest_glossary(account)
        end

      case glossary do
        nil ->
          {:error, Hermes.MCP.Error.execution("No glossary configured for '#{handle}'"), frame}

        %Accounts.Glossary{} = g ->
          response =
            Response.tool()
            |> Response.text(JSON.encode!(serialize_glossary(g)))

          {:reply, response, frame}

        %{} = resolved ->
          response =
            Response.tool()
            |> Response.text(JSON.encode!(resolved))

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end

  defp serialize_glossary(glossary) do
    %{
      version: glossary.version,
      change_note: glossary.change_note,
      inserted_at: glossary.inserted_at,
      entries:
        Enum.map(glossary.entries, fn entry ->
          %{
            term: entry.term,
            definition: entry.definition,
            case_sensitive: entry.case_sensitive,
            translations:
              Enum.map(entry.translations, fn t ->
                %{locale: t.locale, translation: t.translation}
              end)
          }
        end)
    }
  end
end
