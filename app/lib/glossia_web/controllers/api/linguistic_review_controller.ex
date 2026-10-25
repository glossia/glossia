defmodule GlossiaWeb.Api.LinguisticReviewController do
  use GlossiaWeb, :controller
  alias Glossia.{ChangesetErrors, LinguisticReviews}

  plug GlossiaWeb.Plugs.AuthorizeProject, :translation_read when action == :index
  plug GlossiaWeb.Plugs.AuthorizeProject, :translation_write when action == :answer

  def index(conn, %{"id" => id}) do
    case LinguisticReviews.list(conn.assigns.current_user, project(conn), id,
           scopes: conn.assigns.scopes
         ) do
      {:ok, reviews} -> json(conn, %{reviews: Enum.map(reviews, &LinguisticReviews.serialize/1)})
      error -> respond(conn, error)
    end
  end

  def answer(conn, %{"id" => id, "review_id" => review_id}) do
    case LinguisticReviews.answer(
           conn.assigns.current_user,
           project(conn),
           id,
           review_id,
           conn.body_params,
           scopes: conn.assigns.scopes
         ) do
      {:ok, review} -> json(conn, %{review: LinguisticReviews.serialize(review)})
      error -> respond(conn, error)
    end
  end

  defp project(conn), do: Glossia.Repo.preload(conn.assigns.project, :account)

  defp respond(conn, {:error, %Ecto.Changeset{} = changeset}),
    do:
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: ChangesetErrors.to_map(changeset)})

  defp respond(conn, {:error, :insufficient_scope, scope}),
    do:
      conn
      |> put_status(:forbidden)
      |> json(%{error: "insufficient_scope", required_scope: scope})

  defp respond(conn, {:error, reason}) do
    status =
      case reason do
        :not_found ->
          :not_found

        :unauthorized ->
          :forbidden

        reason
        when reason in [:stale, :already_answered, :resolution_outdated, :conversation_busy] ->
          :conflict

        _ ->
          :unprocessable_entity
      end

    conn |> put_status(status) |> json(%{error: to_string(reason)})
  end
end
