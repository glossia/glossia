defmodule Glossia.MCP.SaveVoiceTool do
  @moduledoc "Create a new voice version for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

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
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]

      case Account |> where(handle: ^handle) |> Repo.one() do
        nil ->
          {:error, Error.execution("Account '#{handle}' not found"), frame}

        account ->
          attrs = %{
            tone: params["tone"],
            formality: params["formality"],
            target_audience: params["target_audience"],
            guidelines: params["guidelines"],
            change_note: params["change_note"],
            overrides: params["overrides"] || []
          }

          case Accounts.create_voice(account, attrs, user) do
            {:ok, %{voice: voice, overrides: overrides}} ->
              voice = %{voice | overrides: overrides}

              response =
                Response.tool()
                |> Response.text(
                  Jason.encode!(%{
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
              errors = format_errors(changeset)
              {:error, Error.execution("Validation failed: #{errors}"), frame}
          end
      end
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join(", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
  end
end
