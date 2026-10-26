defmodule GlossiaWeb.Api.ProjectActivityApiController do
  use GlossiaWeb, :controller
  alias Glossia.Analytics.Queries
  alias Glossia.TranslationSessions
  alias GlossiaWeb.Api.{Pagination, Serialization}

  plug GlossiaWeb.Plugs.AuthorizeProject,
       :translation_read when action in [:translations, :translation]

  plug GlossiaWeb.Plugs.AuthorizeProject, :analytics_read when action == :analytics

  @session_fields [
    :id,
    :status,
    :commit_message,
    :source_language,
    :target_languages,
    :translated_content_count,
    :inserted_at,
    :summary
  ]

  def translations(conn, params) do
    with {:ok, pagination} <- Pagination.params(params),
         {:ok, {sessions, meta}} <-
           TranslationSessions.list_project_sessions(conn.assigns.project, pagination) do
      json(conn, %{
        sessions: Enum.map(sessions, &Map.take(&1, @session_fields)),
        meta: Serialization.meta(meta)
      })
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid_parameters"})
    end
  end

  def translation(conn, %{"id" => id}) do
    case TranslationSessions.get_project_session(conn.assigns.project, id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      session -> json(conn, GlossiaWeb.TranslationSnapshot.detail(session))
    end
  end

  def analytics(conn, params) do
    with {:ok, days} <- Pagination.integer(params["days"] || 30, 1, 365) do
      until = DateTime.utc_now()
      since = DateTime.add(until, -days * 86_400, :second)
      project = conn.assigns.project

      json(conn, %{
        summary: Queries.summary(project.id, since, until),
        top_pages: Queries.top_pages(project.id, since: since, until: until, limit: 10),
        traffic: Queries.traffic(project.id, since: since, until: until),
        days: days
      })
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid_parameters"})
    end
  rescue
    _ -> conn |> put_status(:service_unavailable) |> json(%{error: "analytics_unavailable"})
  end
end
