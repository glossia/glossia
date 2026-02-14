defmodule GlossiaWeb.Api.VoiceApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  import Ecto.Query

  def show(conn, %{"handle" => handle} = params) do
    account = get_account_by_handle(handle)

    unless account do
      conn |> put_status(:not_found) |> json(%{error: "account not found"}) |> halt()
    else
      locale = params["locale"]
      version = params["version"]

      voice =
        cond do
          locale ->
            Accounts.get_resolved_voice(account, locale)

          version ->
            Accounts.get_voice_version(account, String.to_integer(version))

          true ->
            Accounts.get_latest_voice(account)
        end

      case voice do
        nil ->
          conn |> put_status(:not_found) |> json(%{error: "no voice configured"})

        %Accounts.Voice{} = v ->
          conn |> json(serialize_voice(v))

        %{} = resolved ->
          conn |> json(resolved)
      end
    end
  end

  def create(conn, %{"handle" => handle} = params) do
    account = get_account_by_handle(handle)

    unless account do
      conn |> put_status(:not_found) |> json(%{error: "account not found"}) |> halt()
    else
      attrs = %{
        tone: params["tone"],
        formality: params["formality"],
        target_audience: params["target_audience"],
        guidelines: params["guidelines"],
        change_note: params["change_note"],
        overrides: params["overrides"] || []
      }

      user = conn.assigns[:current_user]

      case Accounts.create_voice(account, attrs, user) do
        {:ok, %{voice: voice, overrides: overrides}} ->
          Glossia.Auditing.record("voice.created", account, user,
            resource_type: "voice",
            resource_id: to_string(voice.version),
            resource_path: "/#{handle}/voice/#{voice.version}",
            summary: attrs.change_note || "Updated voice configuration"
          )

          voice = %{voice | overrides: overrides}

          conn
          |> put_status(:created)
          |> json(serialize_voice(voice))

        {:error, _step, changeset, _changes} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    end
  end

  def history(conn, %{"handle" => handle} = params) do
    account = get_account_by_handle(handle)

    unless account do
      conn |> put_status(:not_found) |> json(%{error: "account not found"}) |> halt()
    else
      case Accounts.list_voice_versions(account, params) do
        {:ok, {versions, meta}} ->
          conn
          |> json(%{
            versions:
              Enum.map(versions, fn v ->
                %{
                  version: v.version,
                  change_note: v.change_note,
                  inserted_at: v.inserted_at
                }
              end),
            meta: serialize_meta(meta)
          })

        {:error, meta} ->
          conn
          |> put_status(:bad_request)
          |> json(%{errors: meta.errors})
      end
    end
  end

  defp get_account_by_handle(handle) do
    Account
    |> where(handle: ^handle)
    |> Repo.one()
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

  defp serialize_meta(%Flop.Meta{} = meta) do
    %{
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      current_page: meta.current_page,
      page_size: meta.page_size,
      has_next_page?: meta.has_next_page?,
      has_previous_page?: meta.has_previous_page?
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
