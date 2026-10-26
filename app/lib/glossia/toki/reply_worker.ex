defmodule Glossia.Toki.ReplyWorker do
  @moduledoc "Generates one authorized reply, never retries an already claimed inference."
  use Oban.Worker, queue: :toki, max_attempts: 1

  alias Glossia.{Accounts, Projects, Repo, Toki}
  alias Glossia.Toki.{Agent, Conversation}

  @impl Oban.Worker
  def timeout(_job), do: 90_000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_id" => message_id, "scopes" => scopes}}) do
    case Toki.claim(message_id) do
      {:ok, message} ->
        result = generate(message, scopes)
        Toki.finish(message, result)
        :ok

      {:error, :already_claimed} ->
        :ok
    end
  end

  defp generate(message, scopes) do
    conversation = Repo.get!(Conversation, message.conversation_id)
    user = Accounts.get_user(message.user_id || conversation.user_id)
    project = Projects.get_project_by_id(conversation.project_id)

    with :ok <- authorize_reply(user, project, conversation, scopes),
         %{messages: messages} <- Toki.detail(conversation),
         {:ok, text} <- Agent.reply(user, project, messages, scopes, conversation.id),
         :ok <-
           authorize_reply(
             Accounts.get_user(user.id),
             Projects.get_project_by_id(conversation.project_id),
             conversation,
             scopes
           ) do
      if is_binary(text) and String.trim(text) != "" and String.length(text) <= 8_000 and
           byte_size(text) <= 32_000 do
        {:ok, text}
      else
        {:error, "invalid_provider_response"}
      end
    else
      {:error, :provider_unavailable} -> {:error, "provider_unavailable"}
      {:error, :unauthorized} -> {:error, "not_authorized"}
      {:error, :insufficient_scope, _scope} -> {:error, "not_authorized"}
      {:error, :not_found} -> {:error, "source_unavailable"}
      _ -> {:error, "inference_failed"}
    end
  rescue
    _ -> {:error, "inference_failed"}
  catch
    :exit, _ -> {:error, "inference_failed"}
  end

  defp authorize_reply(nil, _project, _conversation, _scopes), do: {:error, :unauthorized}
  defp authorize_reply(_user, nil, _conversation, _scopes), do: {:error, :unauthorized}

  defp authorize_reply(user, project, conversation, scopes) do
    with :ok <- Toki.authorize_project(:toki_write, user, project, scopes: scopes),
         {:ok, _source} <- Toki.conversation_source(user, project, conversation, scopes: scopes),
         true <- Toki.open?(conversation) do
      :ok
    else
      false -> {:error, :not_found}
      error -> error
    end
  end
end
