defmodule Glossia.TokiTest do
  use Glossia.DataCase, async: true
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{
    Authz,
    LinguisticReviews,
    LLMModels,
    Projects,
    TestHelpers,
    Toki,
    TranslationSessions
  }

  alias Glossia.Toki.{Agent, Conversation, Message, RecoveryWorker, ReplyWorker}

  setup do
    unique = System.unique_integer([:positive])
    user = TestHelpers.create_user("toki-#{unique}@example.test", "toki")
    {:ok, project} = Projects.create_project(user.account, %{handle: "app", name: "Application"})
    project = Repo.preload(project, :account)

    {:ok, _} =
      LLMModels.create_model(user.account, user, %{
        handle: "companion",
        model: "openai/gpt-4o-mini",
        api_key: "test-provider-key"
      })

    {:ok, detail} = Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})
    %{user: user, project: project, conversation: detail.conversation}
  end

  test "running claims are durable, redelivery never infers twice, recovery ignores late responses",
       context do
    %{user: user, project: project, conversation: conversation} = context
    id = Ecto.UUID.generate()
    assert {:ok, _} = enqueue(user, project, conversation, id)
    [job] = all_enqueued(worker: ReplyWorker)
    assert {:ok, message} = Toki.claim(id)
    assert Repo.get!(Conversation, conversation.id).status == "running"
    assert {:error, :already_claimed} = Toki.claim(id)
    assert :ok = ReplyWorker.perform(job)
    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert Repo.get!(Message, id).status == "running"

    from(m in Message, where: m.id == ^id)
    |> Repo.update_all(set: [updated_at: DateTime.add(DateTime.utc_now(), -121)])

    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert Repo.get!(Conversation, conversation.id).error == "inference_interrupted"
    assert {:error, :already_finished} = Toki.finish(message, {:ok, "A late response"})
    assert :ok = ReplyWorker.perform(job)
    assert Repo.aggregate(Message, :count) == 1
    assert {:ok, %{conversation: %{status: "failed"}}} = enqueue(user, project, conversation, id)
    assert length(all_enqueued(worker: ReplyWorker)) == 1
  end

  test "orphaned queued turns expire, and delayed jobs and client replays never infer", context do
    %{user: user, project: project, conversation: conversation} = context
    id = Ecto.UUID.generate()
    assert {:ok, _} = enqueue(user, project, conversation, id)
    [job] = all_enqueued(worker: ReplyWorker)

    from(m in Message, where: m.id == ^id)
    |> Repo.update_all(set: [updated_at: DateTime.add(DateTime.utc_now(), -600)])

    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert Repo.get!(Conversation, conversation.id).status == "queued"

    from(m in Message, where: m.id == ^id)
    |> Repo.update_all(set: [updated_at: DateTime.add(DateTime.utc_now(), -901)])

    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert Repo.get!(Message, id).status == "failed"
    assert Repo.get!(Conversation, conversation.id).status == "failed"
    assert Repo.get!(Conversation, conversation.id).error == "inference_interrupted"
    assert {:error, :already_claimed} = Toki.claim(id)
    assert :ok = ReplyWorker.perform(job)
    assert Repo.aggregate(Message, :count) == 1
    assert {:ok, %{conversation: %{status: "failed"}}} = enqueue(user, project, conversation, id)
    assert length(all_enqueued(worker: ReplyWorker)) == 1

    assert {:ok, %{conversation: %{status: "queued"}}} =
             enqueue(user, project, conversation, Ecto.UUID.generate())

    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, conversation.id).status == "queued"
    assert Repo.aggregate(Message, :count) == 2
  end

  test "provider errors, exceptions, exits, empty and oversized output are safe failures",
       context do
    %{user: user, project: project, conversation: initial} = context

    for {result, error} <- [
          {{:error, "secret-provider-response test-provider-key"}, "inference_failed"},
          {{:ok, " "}, "invalid_provider_response"},
          {{:ok, String.duplicate("a", 8_001)}, "invalid_provider_response"},
          {:raise, "inference_failed"},
          {:exit, "inference_failed"}
        ] do
      {:ok, %{conversation: conversation}} =
        Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})

      assert {:ok, _} = enqueue(user, project, conversation, Ecto.UUID.generate())

      stub(Req, :request, fn _request ->
        case result do
          :raise -> raise "secret provider error"
          :exit -> exit(:provider_failed)
          {:ok, text} -> provider_response(text)
          result -> result
        end
      end)

      [job | _] = all_enqueued(worker: ReplyWorker)
      assert :ok = ReplyWorker.perform(job)

      assert {:ok, %{conversation: failed, messages: [%{role: "user"}]}} =
               Toki.get_conversation(user, project, conversation.id)

      assert failed.status == "failed"
      assert failed.error == error
    end

    assert Repo.get!(Conversation, initial.id).status == "completed"
  end

  test "history and model context are bounded, latest input stays complete, data scopes are respected",
       context do
    %{user: user, project: project} = context

    {:ok, _} =
      TranslationSessions.create_session(user.account, project, %{
        status: "completed",
        summary: "Sensitive translated context"
      })

    messages = for _ <- 1..20, do: %Message{role: "user", content: String.duplicate("x", 8_000)}

    expect(Req, :request, fn request ->
      [
        %{role: :system, content: [%{text: prompt}]},
        %{role: :user, content: [%{text: transcript}]}
      ] = request.options.context.messages

      data = JSON.decode!(transcript)
      assert length(data) == 10
      assert String.length(List.last(data)["content"]) == 8_000
      assert Enum.all?(Enum.drop(data, -1), &(String.length(&1["content"]) == 2_000))
      refute prompt =~ "Sensitive translated context"
      provider_response("Real provider output")
    end)

    assert {:ok, "Real provider output"} = Agent.reply(user, project, messages, ["toki:write"])

    expect(Req, :request, fn request ->
      [%{content: [%{text: prompt}]} | _] = request.options.context.messages
      assert prompt =~ "Sensitive translated context"
      provider_response("With translation context")
    end)

    assert {:ok, "With translation context"} =
             Agent.reply(user, project, messages, ["toki:write", "translation:read"])
  end

  test "shared goals infer as the human actor with bounded context, and cancellation discards late replies",
       c do
    conversation = goal_conversation(c)
    assert is_nil(conversation.user_id)
    turn = Ecto.UUID.generate()
    assert {:ok, _} = enqueue(c.user, c.project, conversation, turn)
    [job] = all_enqueued(worker: ReplyWorker)

    expect(Req, :request, fn request ->
      [%{content: [%{text: prompt}]}, %{content: [%{text: transcript}]}] =
        request.options.context.messages

      assert List.last(JSON.decode!(transcript))["user_id"] == c.user.id
      assert prompt =~ "Which branch meaning?"
      assert prompt =~ "Create a branch before release."
      assert prompt =~ "shared conversation"
      assert prompt =~ "only explicit"
      provider_response("Use the release-branch meaning; please approve the decision.")
    end)

    assert :ok = ReplyWorker.perform(job)

    assert {:ok, %{messages: [_, %{user_id: author}, %{role: "assistant"}]}} =
             Toki.get_conversation(c.user, c.project, conversation.id)

    assert author == c.user.id

    next = Ecto.UUID.generate()
    assert {:ok, _} = enqueue(c.user, c.project, conversation, next)
    [job | _] = all_enqueued(worker: ReplyWorker)

    expect(Req, :request, fn _request ->
      session = TranslationSessions.get_session!(conversation.translation_session_id)
      assert {:ok, _} = TranslationSessions.cancel_session(session)
      provider_response("This reply arrived after the goal became stale.")
    end)

    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Message, next).status == "failed"
    refute Repo.exists?(from m in Message, where: m.reply_to_id == ^next)
  end

  test "five pending turns across private chats and shared goals bound queued model work",
       context do
    %{user: user, project: project} = context

    goal = goal_conversation(context)
    assert {:ok, _} = enqueue(user, project, goal, Ecto.UUID.generate())

    for _ <- 1..4 do
      {:ok, %{conversation: conversation}} =
        Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})

      assert {:ok, _} = enqueue(user, project, conversation, Ecto.UUID.generate())
    end

    {:ok, other_project} =
      Projects.create_project(user.account, %{handle: "other", name: "Other"})

    other_project = Repo.preload(other_project, :account)

    {:ok, %{conversation: other}} =
      Toki.create_conversation(user, other_project, %{"id" => Ecto.UUID.generate()})

    assert {:error, :too_many_pending} =
             enqueue(user, other_project, other, Ecto.UUID.generate())

    assert length(all_enqueued(worker: ReplyWorker)) == 5
    assert Repo.aggregate(from(m in Message, where: m.role == "user"), :count) == 5
  end

  test "hourly inference limit does not reject UUID replay or persist rejected input", context do
    %{user: user, project: project, conversation: conversation} = context
    id = Ecto.UUID.generate()
    assert {:ok, _} = enqueue(user, project, conversation, id)

    for _ <- 1..29 do
      assert {:allow, _} = Glossia.RateLimiter.hit("toki:user:#{user.id}", :timer.hours(1), 30)
    end

    assert {:ok, _} = enqueue(user, project, conversation, id)

    {:ok, %{conversation: other}} =
      Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})

    assert {:error, :rate_limited} = enqueue(user, project, other, Ecto.UUID.generate())
    assert Repo.aggregate(Message, :count) == 1
    assert length(all_enqueued(worker: ReplyWorker)) == 1
  end

  test "conversation and complete history have hard storage limits", context do
    %{user: user, project: project, conversation: conversation} = context
    now = DateTime.utc_now()

    rows =
      for _ <- 1..100,
          do: %{
            id: Ecto.UUID.generate(),
            conversation_id: conversation.id,
            role: "user",
            content: "Earlier message",
            status: "failed",
            inserted_at: now,
            updated_at: now
          }

    Repo.insert_all(Message, rows)
    assert {:error, :message_limit} = enqueue(user, project, conversation, Ecto.UUID.generate())
    assert {:ok, %{messages: messages}} = Toki.get_conversation(user, project, conversation.id)
    assert length(messages) == 100

    rows =
      for _ <- 1..99,
          do: %{
            id: Ecto.UUID.generate(),
            user_id: user.id,
            project_id: project.id,
            inserted_at: now,
            updated_at: now
          }

    Repo.insert_all(Conversation, rows)

    assert {:error, :conversation_limit} =
             Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})

    assert {:ok, _} = Toki.create_conversation(user, project, %{"id" => conversation.id})
  end

  test "even a platform administrator cannot override private ownership", context do
    other =
      TestHelpers.create_user(
        "superadmin-#{System.unique_integer([:positive])}@example.test",
        "superadmin"
      )

    assert :ok = Glossia.Roles.set_super_admin(other, true)
    refute Authz.authorize?(:toki_read, other, context.conversation)
    refute Authz.authorize?(:toki_write, other, context.conversation)

    assert {:error, :not_found} =
             Toki.get_conversation(other, context.project, context.conversation.id)
  end

  defp provider_response(text) do
    {:ok,
     %Req.Response{
       status: 200,
       body: %ReqLLM.Response{
         id: "provider-response",
         model: "openai:gpt-4o-mini",
         context: ReqLLM.Context.new([]),
         message: ReqLLM.Context.assistant(text)
       }
     }}
  end

  defp enqueue(user, project, conversation, id) do
    Oban.Testing.with_testing_mode(:manual, fn ->
      Toki.send_message(user, project, conversation.id, %{"id" => id, "content" => "Hello Toki"})
    end)
  end

  defp goal_conversation(c) do
    {:ok, session} =
      TranslationSessions.create_session(c.user.account, c.project, %{status: "running"})

    {:ok, review} =
      LinguisticReviews.request(
        session.id,
        %{source_path: "en.md", output_path: "es.md", locale: "es", context_targets: %{}},
        String.duplicate("a", 64),
        %{
          reason: "missing_context",
          question: "Which branch meaning?",
          source: "Create a branch before release.",
          translation: "Crea una rama."
        }
      )

    Repo.get_by!(Conversation, linguistic_review_id: review.id)
  end
end
