defmodule Glossia.Voices do
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Accounts.{Account, User, Voice, VoiceOverride}
  alias Glossia.Events
  alias Glossia.Repo

  import Ecto.Query

  def get_latest_voice(%Account{id: account_id}) do
    Tracer.with_span "glossia.voices.get_latest_voice" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      Voice
      |> where(account_id: ^account_id)
      |> order_by(desc: :version)
      |> limit(1)
      |> preload([:overrides, created_by: :account])
      |> Repo.one()
    end
  end

  def get_voice_version(%Account{id: account_id}, version) do
    Tracer.with_span "glossia.voices.get_voice_version" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.voice.version", version}
      ])

      Voice
      |> where(account_id: ^account_id, version: ^version)
      |> preload([:overrides, created_by: :account])
      |> Repo.one()
    end
  end

  def get_previous_voice_version(%Account{id: account_id}, version) do
    Tracer.with_span "glossia.voices.get_previous_voice_version" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.voice.version", version}
      ])

      Voice
      |> where([v], v.account_id == ^account_id and v.version < ^version)
      |> order_by(desc: :version)
      |> limit(1)
      |> preload([:overrides, created_by: :account])
      |> Repo.one()
    end
  end

  def list_voice_versions(%Account{id: account_id}, params \\ %{}) do
    Tracer.with_span "glossia.voices.list_voice_versions" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      query =
        Voice
        |> where(account_id: ^account_id)
        |> preload(created_by: :account)

      Flop.validate_and_run(query, params, for: Voice)
    end
  end

  def create_voice(%Account{id: account_id} = account, attrs, user \\ nil, opts \\ []) do
    Tracer.with_span "glossia.voices.create_voice" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.user.id", if(match?(%User{}, user), do: to_string(user.id), else: "")}
      ])

      overrides_attrs = attrs["overrides"] || attrs[:overrides] || []
      created_by_id = if match?(%User{}, user), do: user.id, else: nil

      Ecto.Multi.new()
      |> Ecto.Multi.run(:next_version, fn repo, _changes ->
        max =
          Voice
          |> where(account_id: ^account_id)
          |> select([v], max(v.version))
          |> repo.one()

        {:ok, (max || 0) + 1}
      end)
      |> Ecto.Multi.insert(:voice, fn %{next_version: version} ->
        %Voice{account_id: account_id, created_by_id: created_by_id}
        |> Voice.changeset(Map.put(attrs, :version, version))
      end)
      |> Ecto.Multi.run(:overrides, fn repo, %{voice: voice} ->
        results =
          Enum.map(overrides_attrs, fn override_attrs ->
            %VoiceOverride{voice_id: voice.id}
            |> VoiceOverride.changeset(override_attrs)
            |> repo.insert()
          end)

        case Enum.find(results, &match?({:error, _}, &1)) do
          nil -> {:ok, Enum.map(results, fn {:ok, o} -> o end)}
          {:error, changeset} -> {:error, changeset}
        end
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{voice: voice}} = ok ->
          Tracer.set_attributes([{"glossia.voice.version", voice.version}])

          if match?(%User{}, user) do
            Events.emit("voice.created", account, user,
              resource_type: "voice",
              resource_id: to_string(voice.version),
              resource_path: "/#{account.handle}/-/voice/#{voice.version}",
              summary: "Updated voice settings.",
              via: Keyword.get(opts, :via)
            )
          end

          ok

        other ->
          other
      end
    end
  end

  def get_resolved_voice(%Account{} = account, locale) do
    Tracer.with_span "glossia.voices.get_resolved_voice" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.locale", to_string(locale)}
      ])

      case get_latest_voice(account) do
        nil ->
          nil

        voice ->
          base = %{
            version: voice.version,
            tone: voice.tone,
            formality: voice.formality,
            target_audience: voice.target_audience,
            guidelines: voice.guidelines,
            description: voice.description,
            target_countries: voice.target_countries,
            cultural_notes: voice.cultural_notes
          }

          override = Enum.find(voice.overrides, &(&1.locale == locale))

          if override do
            base
            |> maybe_override(:tone, override.tone)
            |> maybe_override(:formality, override.formality)
            |> maybe_override(:target_audience, override.target_audience)
            |> maybe_override(:guidelines, override.guidelines)
            |> Map.put(:locale, locale)
          else
            base
          end
      end
    end
  end

  defp maybe_override(map, _key, nil), do: map
  defp maybe_override(map, key, value), do: Map.put(map, key, value)
end
