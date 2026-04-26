defmodule GlossiaWeb.Api.VoiceApiController do
  use GlossiaWeb, :controller

  alias Glossia.ChangesetErrors
  alias Glossia.Accounts
  alias Glossia.Voices
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def show(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :voice_read, account) do
          {:ok, conn} ->
            locale = params["locale"]
            version_str = params["version"]

            voice_result =
              cond do
                locale ->
                  {:ok, Voices.get_resolved_voice(account, locale)}

                is_binary(version_str) ->
                  case Integer.parse(version_str) do
                    {version, ""} -> {:ok, Voices.get_voice_version(account, version)}
                    _ -> {:error, :invalid_version}
                  end

                true ->
                  {:ok, Voices.get_latest_voice(account)}
              end

            case voice_result do
              {:error, :invalid_version} ->
                conn |> put_status(:bad_request) |> json(%{error: "invalid_version"})

              {:ok, nil} ->
                conn |> put_status(:not_found) |> json(%{error: "no voice configured"})

              {:ok, %Accounts.Voice{} = v} ->
                conn |> json(serialize_voice(v))

              {:ok, %{} = resolved} ->
                conn |> json(resolved)
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def create(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :voice_write, account) do
          {:ok, conn} ->
            attrs = %{
              tone: params["tone"],
              formality: params["formality"],
              target_audience: params["target_audience"],
              guidelines: params["guidelines"],
              overrides: params["overrides"] || []
            }

            user = conn.assigns[:current_user]

            case Voices.create_voice(account, attrs, user, via: :api) do
              {:ok, %{voice: voice, overrides: overrides}} ->
                voice = %{voice | overrides: overrides}

                conn
                |> put_status(:created)
                |> json(serialize_voice(voice))

              {:error, _step, changeset, _changes} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: ChangesetErrors.to_map(changeset)})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def history(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :voice_read, account) do
          {:ok, conn} ->
            case Voices.list_voice_versions(account, params) do
              {:ok, {versions, meta}} ->
                conn
                |> json(%{
                  versions:
                    Enum.map(versions, fn v ->
                      %{
                        version: v.version,
                        inserted_at: v.inserted_at
                      }
                    end),
                  meta: Serialization.meta(meta)
                })

              {:error, meta} ->
                conn
                |> put_status(:bad_request)
                |> json(%{errors: meta.errors})
            end

          {:error, conn} ->
            conn
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
