defmodule Glossia.MCP.GetVoiceTool do
  @moduledoc "Get the current voice configuration for an account, optionally resolved for a specific locale."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Account handle to get voice for."

    field :locale, :string,
      description:
        "Optional locale (e.g. 'ja', 'de', 'es-MX'). If provided, returns the merged/resolved voice for that locale."

    field :version, :integer,
      description:
        "Optional version number. If provided, returns that specific version instead of the latest."
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
          locale = params["locale"]
          version = params["version"]

          voice =
            cond do
              locale ->
                Accounts.get_resolved_voice(account, locale)

              version ->
                Accounts.get_voice_version(account, version)

              true ->
                Accounts.get_latest_voice(account)
            end

          case voice do
            nil ->
              {:error, Error.execution("No voice configured for '#{handle}'"), frame}

            %Accounts.Voice{} = v ->
              response =
                Response.tool()
                |> Response.text(Jason.encode!(serialize_voice(v)))

              {:reply, response, frame}

            %{} = resolved ->
              response =
                Response.tool()
                |> Response.text(Jason.encode!(resolved))

              {:reply, response, frame}
          end
      end
    end
  end

  defp serialize_voice(voice) do
    %{
      version: voice.version,
      tone: voice.tone,
      formality: voice.formality,
      target_audience: voice.target_audience,
      guidelines: voice.guidelines,
      change_note: voice.change_note,
      inserted_at: voice.inserted_at,
      overrides:
        Enum.map(voice.overrides, fn o ->
          %{
            locale: o.locale,
            tone: o.tone,
            formality: o.formality,
            target_audience: o.target_audience,
            guidelines: o.guidelines
          }
        end)
    }
  end
end
