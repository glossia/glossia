defmodule GlossiaWeb.Api.TokiApiController do
  use GlossiaWeb, :controller
  alias Glossia.ChangesetErrors
  alias Glossia.Toki
  alias GlossiaWeb.Api.{Pagination, Serialization}

  plug GlossiaWeb.Plugs.AuthorizeProject, :toki_read when action in [:index, :show]
  plug GlossiaWeb.Plugs.AuthorizeProject, :toki_write when action in [:create, :message]

  def index(conn, params) do
    with {:ok, pagination} <- Pagination.params(params),
         {:ok, {conversations, meta}} <-
           Toki.list_conversations(
             conn.assigns.current_user,
             conn.assigns.project,
             pagination,
             scopes: conn.assigns.scopes
           ) do
      json(conn, %{
        conversations: Enum.map(conversations, &serialize_conversation/1),
        meta: Serialization.meta(meta)
      })
    else
      _ -> error(conn, :bad_request, "invalid_parameters")
    end
  end

  def create(conn, params) do
    Toki.create_conversation(conn.assigns.current_user, conn.assigns.project, params,
      scopes: conn.assigns.scopes
    )
    |> respond(conn, :created)
  end

  def show(conn, %{"id" => id}) do
    Toki.get_conversation(conn.assigns.current_user, conn.assigns.project, id,
      scopes: conn.assigns.scopes
    )
    |> respond(conn, :ok)
  end

  def message(conn, %{"id" => conversation_id}) do
    # Path IDs and client message IDs are different fields. Read the UUID from
    # the JSON body, not Phoenix's merged params (where the path wins).
    Toki.send_message(
      conn.assigns.current_user,
      conn.assigns.project,
      conversation_id,
      conn.body_params,
      scopes: conn.assigns.scopes
    )
    |> respond(conn, :accepted)
  end

  defp respond({:ok, detail}, conn, status) do
    status =
      if status == :accepted and detail.conversation.status not in ["queued", "running"],
        do: :ok,
        else: status

    conn
    |> put_status(status)
    |> json(%{
      conversation: serialize_conversation(detail.conversation),
      messages: Enum.map(detail.messages, &serialize_message/1)
    })
  end

  defp respond({:error, %Ecto.Changeset{} = changeset}, conn, _),
    do:
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: ChangesetErrors.to_map(changeset)})

  defp respond({:error, :insufficient_scope, scope}, conn, status),
    do: respond({:error, {:insufficient_scope, scope}}, conn, status)

  defp respond({:error, {:insufficient_scope, scope}}, conn, _) do
    conn
    |> put_resp_header(
      "www-authenticate",
      ~s(Bearer error="insufficient_scope", scope="#{scope}")
    )
    |> put_status(:forbidden)
    |> json(%{error: "insufficient_scope", required_scope: scope})
  end

  defp respond({:error, reason}, conn, _) do
    status =
      case reason do
        :not_found -> :not_found
        :unauthorized -> :forbidden
        reason when reason in [:conversation_busy, :id_conflict, :goal_closed] -> :conflict
        reason when reason in [:rate_limited, :too_many_pending] -> :too_many_requests
        _ -> :unprocessable_entity
      end

    error(conn, status, to_string(reason))
  end

  defp error(conn, status, error), do: conn |> put_status(status) |> json(%{error: error})

  defp serialize_conversation(conversation),
    do:
      conversation
      |> Map.take([:id, :title, :status, :updated_at, :error, :translation_session_id])
      |> Map.put(
        :linguistic_review,
        if(conversation.linguistic_review,
          do: Glossia.LinguisticReviews.serialize(conversation.linguistic_review)
        )
      )

  defp serialize_message(message) do
    author =
      cond do
        message.role == "assistant" -> "Toki"
        message.user -> message.user.name || "Linguist"
        true -> "Linguist"
      end

    message
    |> Map.take([:id, :role, :content, :inserted_at, :user_id, :status, :reply_to_id])
    |> Map.put(:author, author)
  end
end
