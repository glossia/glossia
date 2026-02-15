defmodule Glossia.MCP.SaveVoiceTool do
  @moduledoc "Create a new voice version for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.ChangesetErrors
  alias Glossia.Voices
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle to save voice for."

    field :tone, :string,
      description: "Voice tone: casual, formal, playful, authoritative, or neutral."

    field :formality, :string,
      description: "Formality level: informal, neutral, formal, or very_formal."

    field :target_audience, :string, description: "Description of the target audience."

    field :guidelines, :string, description: "Detailed writing/brand guidelines in Markdown."

    field :change_note, :string,
      description: "Optional note describing what changed in this version."

    field :overrides, {:array, :map},
      description:
        "Language-specific overrides. Each override is an object with: locale (required), tone, formality, target_audience, guidelines. Non-null fields override the base voice for that locale."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :voice_write, user, account) do
      attrs = %{
        tone: params["tone"],
        formality: params["formality"],
        target_audience: params["target_audience"],
        guidelines: params["guidelines"],
        change_note: params["change_note"],
        overrides: params["overrides"] || []
      }

      case Voices.create_voice(account, attrs, user) do
        {:ok, %{voice: voice, overrides: overrides}} ->
          voice = %{voice | overrides: overrides}

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                version: voice.version,
                tone: voice.tone,
                formality: voice.formality,
                target_audience: voice.target_audience,
                guidelines: voice.guidelines,
                change_note: voice.change_note,
                overrides:
                  Enum.map(overrides, fn o ->
                    %{locale: o.locale, tone: o.tone, formality: o.formality}
                  end)
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
