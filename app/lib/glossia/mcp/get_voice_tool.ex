defmodule Glossia.MCP.GetVoiceTool do
  @moduledoc "Get the current voice configuration for an account, optionally resolved for a specific locale."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Voices
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

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
    handle = params["handle"]

    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :voice_read, user, account) do
      locale = params["locale"]
      version = params["version"]

      voice =
        cond do
          locale ->
            Voices.get_resolved_voice(account, locale)

          version ->
            Voices.get_voice_version(account, version)

          true ->
            Voices.get_latest_voice(account)
        end

      case voice do
        nil ->
          {:error, Hermes.MCP.Error.execution("No voice configured for '#{handle}'"), frame}

        %Accounts.Voice{} = v ->
          response =
            Response.tool()
            |> Response.text(JSON.encode!(serialize_voice(v)))

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

  defp serialize_voice(voice) do
    %{
      version: voice.version,
      tone: voice.tone,
      formality: voice.formality,
      target_audience: voice.target_audience,
      guidelines: voice.guidelines,
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
