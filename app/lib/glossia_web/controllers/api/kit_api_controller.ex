defmodule GlossiaWeb.Api.KitApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Auditing
  alias Glossia.ChangesetErrors
  alias Glossia.Kits
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def index(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :kit_read, account) do
          {:ok, conn} ->
            case Kits.list_kits(account, params) do
              {:ok, {kits, meta}} ->
                json(conn, %{
                  kits: Enum.map(kits, &serialize_kit/1),
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

  def show(conn, %{"handle" => handle, "kit_handle" => kit_handle}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :kit_read, account) do
          {:ok, conn} ->
            case Kits.get_kit_by_handle(account, kit_handle) do
              nil ->
                conn |> put_status(:not_found) |> json(%{error: "kit not found"})

              kit ->
                json(conn, serialize_kit_with_terms(kit))
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
        case ApiAuthorization.authorize(conn, :kit_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]

            case Kits.create_kit(account, user, params) do
              {:ok, kit} ->
                Auditing.record("kit.created", account, user,
                  resource_type: "kit",
                  resource_id: to_string(kit.id),
                  resource_path: "/#{handle}/kits/#{kit.handle}",
                  summary: "Created kit #{kit.handle} via API"
                )

                conn
                |> put_status(:created)
                |> json(serialize_kit(kit))

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: ChangesetErrors.to_map(changeset)})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def create_term(conn, %{"handle" => handle, "kit_handle" => kit_handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :kit_write, account) do
          {:ok, conn} ->
            case Kits.get_kit_by_handle(account, kit_handle) do
              nil ->
                conn |> put_status(:not_found) |> json(%{error: "kit not found"})

              kit ->
                user = conn.assigns[:current_user]

                case Kits.add_term(kit, params) do
                  {:ok, term} ->
                    Auditing.record("kit_term.created", account, user,
                      resource_type: "kit_term",
                      resource_id: to_string(term.id),
                      resource_path: "/#{handle}/kits/#{kit.handle}",
                      summary: "Added term \"#{term.source_term}\" to kit #{kit.handle} via API"
                    )

                    conn
                    |> put_status(:created)
                    |> json(serialize_term(term))

                  {:error, changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> json(%{errors: ChangesetErrors.to_map(changeset)})
                end
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp serialize_kit(kit) do
    %{
      handle: kit.handle,
      name: kit.name,
      description: kit.description,
      source_language: kit.source_language,
      target_languages: kit.target_languages,
      domain_tags: kit.domain_tags,
      visibility: kit.visibility,
      stars_count: kit.stars_count,
      inserted_at: kit.inserted_at
    }
  end

  defp serialize_kit_with_terms(kit) do
    kit
    |> serialize_kit()
    |> Map.put(:terms, Enum.map(kit.terms, &serialize_term/1))
  end

  defp serialize_term(term) do
    %{
      id: term.id,
      source_term: term.source_term,
      definition: term.definition,
      tags: term.tags,
      translations:
        Enum.map(term.translations, fn t ->
          %{
            language: t.language,
            translated_term: t.translated_term,
            usage_note: t.usage_note
          }
        end),
      inserted_at: term.inserted_at
    }
  end
end
