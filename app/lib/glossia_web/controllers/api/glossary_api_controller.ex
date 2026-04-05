defmodule GlossiaWeb.Api.GlossaryApiController do
  use GlossiaWeb, :controller

  alias Glossia.ChangesetErrors
  alias Glossia.Accounts
  alias Glossia.Glossaries
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def show(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :glossary_read, account) do
          {:ok, conn} ->
            locale = params["locale"]
            version_str = params["version"]

            glossary_result =
              cond do
                locale ->
                  {:ok, Glossaries.get_resolved_glossary(account, locale)}

                is_binary(version_str) ->
                  case Integer.parse(version_str) do
                    {version, ""} -> {:ok, Glossaries.get_glossary_version(account, version)}
                    _ -> {:error, :invalid_version}
                  end

                true ->
                  {:ok, Glossaries.get_latest_glossary(account)}
              end

            case glossary_result do
              {:error, :invalid_version} ->
                conn |> put_status(:bad_request) |> json(%{error: "invalid_version"})

              {:ok, nil} ->
                conn |> put_status(:not_found) |> json(%{error: "no glossary configured"})

              {:ok, %Accounts.Glossary{} = g} ->
                conn |> json(serialize_glossary(g))

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
        case ApiAuthorization.authorize(conn, :glossary_write, account) do
          {:ok, conn} ->
            attrs = %{
              change_note: params["change_note"],
              entries: params["entries"] || []
            }

            user = conn.assigns[:current_user]

            case Glossaries.create_glossary(account, attrs, user, via: :api) do
              {:ok, %{glossary: glossary, entries: entries}} ->
                glossary = %{glossary | entries: entries}

                conn
                |> put_status(:created)
                |> json(serialize_glossary(glossary))

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
        case ApiAuthorization.authorize(conn, :glossary_read, account) do
          {:ok, conn} ->
            case Glossaries.list_glossary_versions(account, params) do
              {:ok, {versions, meta}} ->
                conn
                |> json(%{
                  versions:
                    Enum.map(versions, fn g ->
                      %{
                        version: g.version,
                        change_note: g.change_note,
                        inserted_at: g.inserted_at
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
