defmodule Glossia.Push.Source do
  @moduledoc false
  import Ecto.Query
  alias Glossia.Accounts.Project
  alias Glossia.{Authz, LinguisticReviews, Repo, Toki}
  alias Glossia.LinguisticReviews.Review
  alias Glossia.Toki.{Conversation, Message}
  alias Glossia.TranslationSessions.TranslationSession

  def normalize("toki_completed", source),
    do: ids(source, ~w(conversation_id message_id))

  def normalize("linguistic_input_needed", source) when is_map(source) do
    if map_size(source) == 2,
      do: ids(source, ~w(translation_session_id review_id)),
      else: ids(source, ~w(translation_session_id))
  end

  def normalize(_, _), do: :error

  def destination(user, kind, source, opts \\ [])

  def destination(user, "toki_completed", source, opts) do
    conversation_id = source["conversation_id"]
    message_id = source["message_id"]

    with %Conversation{} = conversation <- Repo.get(Conversation, conversation_id),
         true <- recipient?(user, conversation),
         %Project{} = project <- project(conversation.project_id),
         :ok <- Toki.authorize_project(:toki_read, user, project, opts),
         {:ok, _} <- Toki.conversation_source(user, project, conversation, opts),
         %Message{conversation_id: ^conversation_id, role: "user", status: "completed"} <-
           Repo.get(Message, message_id),
         true <-
           Repo.exists?(
             from m in Message,
               where:
                 m.conversation_id == ^conversation_id and m.reply_to_id == ^message_id and
                   m.role == "assistant" and m.status == "completed"
           ) do
      {:ok,
       %{
         account: project.account.handle,
         project: project.handle,
         screen: "toki",
         id: conversation_id
       }}
    else
      _ -> {:error, :source_unavailable}
    end
  end

  def destination(user, "linguistic_input_needed", source, opts) do
    with %TranslationSession{} = session <-
           Repo.get(TranslationSession, source["translation_session_id"]),
         %Project{} = project <- project(session.project_id),
         true <- session.account_id == project.account_id,
         :ok <- Authz.authorize(:translation_read, user, project.account, opts),
         :ok <- Authz.authorize(:project_read, user, project.account),
         :ok <- Toki.authorize_project(:toki_read, user, project, opts),
         %Review{} = review <- review_for(user, session.id, source["review_id"]),
         %Conversation{} = conversation <-
           Repo.get_by(Conversation, linguistic_review_id: review.id),
         {:ok, _} <- Toki.conversation_source(user, project, conversation, opts) do
      {:ok,
       %{
         account: project.account.handle,
         project: project.handle,
         screen: "toki",
         id: conversation.id
       }}
    else
      _ -> {:error, :source_unavailable}
    end
  end

  defp recipient?(user, %Conversation{linguistic_review_id: nil, user_id: id}), do: user.id == id

  defp recipient?(user, conversation) do
    case Repo.get(Review, conversation.linguistic_review_id) do
      nil -> false
      review -> LinguisticReviews.invited?(user, review)
    end
  end

  defp review_for(user, session_id, review_id) do
    query =
      from r in Review, where: r.translation_session_id == ^session_id and r.status == "open"

    query = if review_id, do: where(query, [r], r.id == ^review_id), else: query
    query |> Repo.all() |> Enum.find(&LinguisticReviews.invited?(user, &1))
  end

  defp project(id) do
    case Repo.get(Project, id) do
      nil -> nil
      project -> Repo.preload(project, :account)
    end
  end

  defp ids(source, keys) when is_map(source) do
    allowed = keys ++ Enum.map(keys, &String.to_existing_atom/1)

    if map_size(source) == length(keys) and Enum.all?(Map.keys(source), &(&1 in allowed)) do
      source = Map.new(source, fn {key, value} -> {to_string(key), value} end)

      Enum.reduce_while(keys, {:ok, %{}}, fn key, {:ok, result} ->
        case Ecto.UUID.cast(source[key]) do
          {:ok, id} -> {:cont, {:ok, Map.put(result, key, id)}}
          _ -> {:halt, :error}
        end
      end)
    else
      :error
    end
  end

  defp ids(_, _), do: :error
end
