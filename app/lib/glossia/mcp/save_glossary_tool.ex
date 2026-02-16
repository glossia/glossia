defmodule Glossia.MCP.SaveGlossaryTool do
  @moduledoc "Create a new glossary version for an account."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.ChangesetErrors
  alias Glossia.Auditing
  alias Glossia.Glossaries
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle to save glossary for."

    field :change_note, :string,
      description: "Optional note describing what changed in this version."

    field :entries, {:required, {:array, :map}},
      description:
        "List of glossary entries. Each entry is an object with: term (required), definition (optional), case_sensitive (boolean, default false), translations (array of {locale, translation} objects)."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :glossary_write, user, account) do
      attrs = %{
        change_note: params["change_note"],
        entries: params["entries"] || []
      }

      case Glossaries.create_glossary(account, attrs, user) do
        {:ok, %{glossary: glossary, entries: entries}} ->
          Auditing.record("glossary.created", account, user,
            resource_type: "glossary",
            resource_id: to_string(glossary.version),
            resource_path: "/#{handle}/glossary/#{glossary.version}",
            summary: glossary.change_note || "Updated glossary."
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                version: glossary.version,
                change_note: glossary.change_note,
                entry_count: length(entries)
              })
            )

          {:reply, response, frame}

        {:error, _step, changeset, _changes} ->
          errors = ChangesetErrors.to_inline_string(changeset)
          {:error, Hermes.MCP.Error.execution("Validation failed: #{errors}"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
