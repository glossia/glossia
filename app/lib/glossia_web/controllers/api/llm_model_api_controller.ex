defmodule GlossiaWeb.Api.LlmModelApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.LlmModels
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def index(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :llm_model_read, account) do
          {:ok, conn} ->
            case LlmModels.list_models(account, params) do
              {:ok, {models, meta}} ->
                conn
                |> json(%{
                  models: Enum.map(models, &serialize_model/1),
                  meta: Serialization.meta(meta)
                })

              {:error, meta} ->
                conn |> put_status(:bad_request) |> json(%{errors: meta.errors})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def show(conn, %{"handle" => handle, "id" => id}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :llm_model_read, account) do
          {:ok, conn} ->
            case LlmModels.get_model(id, account.id) do
              nil ->
                conn |> put_status(:not_found) |> json(%{error: "model not found"})

              model ->
                conn |> json(%{model: serialize_model(model)})
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
        case ApiAuthorization.authorize(conn, :llm_model_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]

            attrs = %{
              "handle" => params["model_handle"],
              "model" => params["model"],
              "api_key" => params["api_key"]
            }

            case LlmModels.create_model(account, user, attrs) do
              {:ok, model} ->
                Glossia.Auditing.record("llm_model.created", account, user,
                  resource_type: "llm_model",
                  resource_id: to_string(model.id),
                  resource_path: "/#{handle}/-/settings/models",
                  summary: "Created LLM model \"#{model.handle}\""
                )

                conn
                |> put_status(:created)
                |> json(%{model: serialize_model(model)})

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: Glossia.ChangesetErrors.to_map(changeset)})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def update(conn, %{"handle" => handle, "id" => id} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :llm_model_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]

            case LlmModels.get_model(id, account.id) do
              nil ->
                conn |> put_status(:not_found) |> json(%{error: "model not found"})

              model ->
                attrs =
                  %{}
                  |> maybe_put("handle", params["model_handle"])
                  |> maybe_put("model", params["model"])
                  |> maybe_put("api_key", params["api_key"])

                case LlmModels.update_model(model, attrs) do
                  {:ok, updated} ->
                    Glossia.Auditing.record("llm_model.updated", account, user,
                      resource_type: "llm_model",
                      resource_id: to_string(updated.id),
                      resource_path: "/#{handle}/-/settings/models/#{updated.id}",
                      summary: "Updated LLM model \"#{updated.handle}\""
                    )

                    conn |> json(%{model: serialize_model(updated)})

                  {:error, changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> json(%{errors: Glossia.ChangesetErrors.to_map(changeset)})
                end
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def delete(conn, %{"handle" => handle, "id" => id}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :llm_model_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]

            case LlmModels.get_model(id, account.id) do
              nil ->
                conn |> put_status(:not_found) |> json(%{error: "model not found"})

              model ->
                case LlmModels.delete_model(model) do
                  {:ok, _} ->
                    Glossia.Auditing.record("llm_model.deleted", account, user,
                      resource_type: "llm_model",
                      resource_id: to_string(model.id),
                      resource_path: "/#{handle}/-/settings/models",
                      summary: "Deleted LLM model \"#{model.handle}\""
                    )

                    conn |> json(%{status: "deleted"})

                  {:error, _} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> json(%{error: "could not delete model"})
                end
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp serialize_model(model) do
    %{
      id: model.id,
      handle: model.handle,
      model: model.model,
      inserted_at: model.inserted_at,
      updated_at: model.updated_at
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
