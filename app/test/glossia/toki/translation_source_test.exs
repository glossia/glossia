defmodule Glossia.Toki.TranslationSourceTest do
  use Glossia.DataCase, async: true
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{
    LLMModels,
    MemberPermissions,
    Organizations,
    Projects,
    TestHelpers,
    Toki,
    TranslationSessions
  }

  alias Glossia.Toki.{Agent, Conversation, Message, ReplyWorker}

  @scopes ~w(toki:write toki:read translation:read)

  setup do
    unique = System.unique_integer([:positive])
    owner = TestHelpers.create_user("origin-#{unique}@test.com", "origin-#{unique}")
    member = TestHelpers.create_user("reader-#{unique}@test.com", "reader-#{unique}")

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(owner, %{handle: "origin-org-#{unique}"})

    {:ok, _} = Organizations.add_member(organization, member)
    {:ok, project} = Projects.create_project(account, %{handle: "app", name: "App"})
    project = Repo.preload(project, :account)

    {:ok, source} =
      TranslationSessions.create_session(account, project, %{
        summary: "SOURCE SUMMARY: translated the installation guide into Japanese.",
        commit_sha: "origin-sha"
      })

    {:ok, %{conversation: conversation}} =
      Toki.create_conversation(
        member,
        project,
        %{"id" => Ecto.UUID.generate(), "translation_session_id" => source.id},
        scopes: @scopes
      )

    {:ok, _} =
      LLMModels.create_model(account, owner, %{
        handle: "toki",
        model: "openai/gpt-4o-mini",
        api_key: "test-key",
        default: true
      })

    %{
      owner: owner,
      member: member,
      organization: organization,
      project: project,
      source: source,
      conversation: conversation
    }
  end

  test "worker uses the persisted exact source, bounded and labeled, even outside recent sessions",
       c do
    for _ <- 1..4 do
      {:ok, _} =
        TranslationSessions.create_session(c.project.account, c.project, %{summary: "RECENT"})
    end

    job = enqueue(c)

    expect(Req, :request, fn request ->
      [%{content: [%{text: prompt}]} | _] = request.options.context.messages
      assert prompt =~ "session-summary-level provenance"
      [_, json] = String.split(prompt, "Authorized project context:\n", parts: 2)
      data = JSON.decode!(json)
      assert data["translation_origin"]["translation_session_id"] == c.source.id
      assert data["translation_origin"]["commit_sha"] == "origin-sha"
      assert data["translation_origin"]["provenance"] == "session_summary"
      assert data["translation_origin"]["summary"] == c.source.summary
      assert String.length(data["translation_origin"]["summary"]) <= 1_000
      assert Enum.all?(data["recent_translations"], &(&1["summary"] == "RECENT"))
      refute prompt =~ "CLIENT FORGERY"
      response("Based only on this session summary, check the completed languages.")
    end)

    assert :ok = ReplyWorker.perform(job)
    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).status == "completed"
    assert Repo.aggregate(Message, :count) == 2

    assert {:ok, %{conversation: %{translation_session_id: id}}} =
             Toki.get_conversation(c.member, c.project, c.conversation.id, scopes: @scopes)

    assert id == c.source.id

    assert {:ok, replay} =
             Toki.create_conversation(
               c.member,
               c.project,
               %{"id" => c.conversation.id, "translation_session_id" => c.source.id},
               scopes: @scopes
             )

    assert replay.conversation.id == c.conversation.id
    assert length(replay.messages) == 2
    assert length(all_enqueued(worker: ReplyWorker)) == 1

    assert {:error, :insufficient_scope, "translation:read"} =
             Toki.get_conversation(c.member, c.project, c.conversation.id, scopes: ["toki:read"])
  end

  test "revoking translation permission alone fails before any model request or source leak", c do
    job = enqueue(c)
    deny_translation(c)
    stub(Req, :request, fn _ -> flunk("revoked source must not enter inference") end)
    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "not_authorized"
    assert Repo.aggregate(Message, :count) == 1

    assert {:error, :unauthorized} =
             Toki.get_conversation(c.member, c.project, c.conversation.id, scopes: @scopes)

    assert {:ok, {[], meta}} = Toki.list_conversations(c.member, c.project, %{}, scopes: @scopes)
    assert meta.total_count == 0

    assert {:error, :unauthorized} =
             Agent.reply(c.member, c.project, [], @scopes, c.conversation.id)
  end

  test "a reduced-scope queued turn cannot infer using a source-authorized older history", c do
    job = enqueue(c)
    stub(Req, :request, fn _ -> flunk("reduced scopes must not enter inference") end)
    job = %{job | args: Map.put(job.args, "scopes", ["toki:write"])}
    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "not_authorized"
    assert Repo.aggregate(Message, :count) == 1
  end

  test "deleted sources remain immutable references, inaccessible and never used for inference",
       c do
    job = enqueue(c)
    Repo.delete!(c.source)
    stub(Req, :request, fn _ -> flunk("missing source must not enter inference") end)
    assert :ok = ReplyWorker.perform(job)
    stored = Repo.get!(Conversation, c.conversation.id)
    assert stored.translation_session_id == c.source.id
    assert stored.error == "source_unavailable"
    assert Repo.aggregate(Message, :count) == 1

    assert {:error, :not_found} =
             Toki.get_conversation(c.member, c.project, stored.id, scopes: @scopes)

    assert {:ok, {[], _}} = Toki.list_conversations(c.member, c.project, %{}, scopes: @scopes)

    assert {:error, :not_found} =
             Toki.create_conversation(
               c.member,
               c.project,
               %{"id" => stored.id, "translation_session_id" => c.source.id},
               scopes: @scopes
             )

    assert {:error, :id_conflict} =
             Toki.create_conversation(c.member, c.project, %{"id" => stored.id}, scopes: @scopes)
  end

  test "a source moved to another project is rejected again before inference", c do
    job = enqueue(c)
    {:ok, other} = Projects.create_project(c.project.account, %{handle: "other", name: "Other"})
    Repo.update!(Ecto.Changeset.change(c.source, project_id: other.id))
    stub(Req, :request, fn _ -> flunk("foreign source must not enter inference") end)
    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "source_unavailable"
    assert Repo.aggregate(Message, :count) == 1
  end

  test "translation permission is rechecked after inference and output is discarded", c do
    job = enqueue(c)

    expect(Req, :request, fn _ ->
      deny_translation(c)
      response("SOURCE SUMMARY that must not be stored")
    end)

    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "not_authorized"
    assert Repo.aggregate(Message, :count) == 1
  end

  test "source existence is rechecked after inference and output is discarded", c do
    job = enqueue(c)

    expect(Req, :request, fn _ ->
      Repo.delete!(c.source)
      response("SOURCE SUMMARY that must not be stored")
    end)

    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "source_unavailable"
    assert Repo.aggregate(Message, :count) == 1
  end

  test "source account association must still match even if its project ID is unchanged", c do
    job = enqueue(c)
    Repo.update!(Ecto.Changeset.change(c.source, account_id: c.owner.account.id))
    stub(Req, :request, fn _ -> flunk("foreign-account source must not enter inference") end)
    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "source_unavailable"
    assert Repo.aggregate(Message, :count) == 1
    assert is_nil(TranslationSessions.get_project_session(c.project, c.source.id))
  end

  defp deny_translation(c) do
    {:ok, _} =
      MemberPermissions.update(
        c.organization,
        c.owner,
        c.member,
        ~w(project:read toki:read toki:write)
      )
  end

  defp enqueue(c) do
    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} =
        Toki.send_message(
          c.member,
          c.project,
          c.conversation.id,
          %{
            "id" => Ecto.UUID.generate(),
            "content" => "Explain this translation",
            "summary" => "CLIENT FORGERY",
            "translation_session_id" => Ecto.UUID.generate()
          },
          scopes: @scopes
        )
    end)

    [job] = all_enqueued(worker: ReplyWorker)
    job
  end

  defp response(text) do
    {:ok,
     %Req.Response{
       status: 200,
       body: %ReqLLM.Response{
         id: "response",
         model: "openai:gpt-4o-mini",
         context: ReqLLM.Context.new([]),
         message: ReqLLM.Context.assistant(text)
       }
     }}
  end
end
