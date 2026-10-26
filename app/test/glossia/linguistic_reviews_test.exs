defmodule Glossia.LinguisticReviewsTest do
  use Glossia.DataCase, async: true
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{
    LinguisticReviews,
    LLMModels,
    Projects,
    TestHelpers,
    Toki,
    Translations,
    TranslationSessions
  }

  alias Glossia.LinguisticReviews.Review
  alias Glossia.Push.Source
  alias Glossia.Toki.{Conversation, Message}
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions.{TranslationSession, TranslateWorker}

  setup do
    user =
      TestHelpers.create_user(
        "review-#{System.unique_integer([:positive])}@example.test",
        "review"
      )

    {:ok, project} = Projects.create_project(user.account, %{handle: "docs", name: "Docs"})
    project = Repo.preload(project, :account)

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "source",
        source_language: "en",
        target_languages: ["es"]
      })

    %{user: user, project: project, session: session}
  end

  test "matching fluent teammates share one goal and explicitly approve the current conversation decision",
       c do
    {:ok, owner} = Glossia.Accounts.update_user_profile(c.user, %{fluent_languages: ["es"]})

    teammate =
      TestHelpers.create_user("fluent-#{System.unique_integer([:positive])}@test.com", "fluent")

    {:ok, teammate} =
      Glossia.Accounts.update_user_profile(teammate, %{fluent_languages: ["es-MX"]})

    french =
      TestHelpers.create_user("french-#{System.unique_integer([:positive])}@test.com", "french")

    {:ok, french} = Glossia.Accounts.update_user_profile(french, %{fluent_languages: ["fr"]})

    {:ok, %{organization: org, account: account}} =
      Glossia.Organizations.create_organization(owner, %{
        handle: "goals-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Glossia.Organizations.add_member(org, teammate)
    {:ok, _} = Glossia.Organizations.add_member(org, french)
    {:ok, project} = Projects.create_project(account, %{handle: "docs", name: "Docs"})
    project = Repo.preload(project, :account)
    {:ok, session} = TranslationSessions.create_session(account, project, %{status: "running"})
    review = request!(session, "es/start.txt")

    assert LinguisticReviews.serialize(review).participants |> Enum.map(& &1.id) |> Enum.sort() ==
             Enum.sort([owner.id, teammate.id])

    conversation = Repo.get_by!(Conversation, linguistic_review_id: review.id)
    assert conversation.user_id == nil

    assert {:ok, %{conversation: %{id: id}}} =
             Toki.get_conversation(teammate, project, conversation.id)

    assert id == conversation.id
    {:ok, private} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})

    assert {:error, :not_found} =
             Toki.get_conversation(teammate, project, private.conversation.id)

    assert {:ok, {[%{id: ^id}], _}} = Toki.list_conversations(teammate, project)

    for user <- [owner, teammate] do
      assert {:ok, %{screen: "toki", id: ^id}} =
               Source.destination(user, "linguistic_input_needed", %{
                 "translation_session_id" => session.id,
                 "review_id" => review.id
               })
    end

    assert {:error, :source_unavailable} =
             Source.destination(french, "linguistic_input_needed", %{
               "translation_session_id" => session.id,
               "review_id" => review.id
             })

    refute LinguisticReviews.fluent?(["zh-Hans"], "zh-Hant-TW")
    refute LinguisticReviews.fluent?(["zh-CN"], "zh-TW")
    refute LinguisticReviews.fluent?(["sr-Latn"], "sr-Cyrl-RS")
    assert LinguisticReviews.fluent?(["zh"], "zh-TW")
    assert LinguisticReviews.fluent?(["es"], "es-419")

    opening = Repo.get_by!(Message, conversation_id: id, role: "assistant")

    assert {:error, :resolution_outdated} =
             LinguisticReviews.answer(owner, project, session.id, review.id, %{
               "answer" => "The opening question is not an agreed decision.",
               "resolution_message_id" => opening.id
             })

    turn = Ecto.UUID.generate()

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} =
        Toki.send_message(owner, project, id, %{
          "id" => turn,
          "content" => "This refers to a source-control release branch."
        })
    end)

    {:ok, message} = Toki.claim(turn)
    {:ok, _} = Toki.finish(message, {:ok, "Use the source-control meaning."})
    first = Repo.get_by!(Message, reply_to_id: turn)
    next = Ecto.UUID.generate()

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} =
        Toki.send_message(teammate, project, id, %{
          "id" => next,
          "content" => "Use the release-branch term, not a tree branch."
        })
    end)

    assert Repo.get!(Message, next).user_id == teammate.id

    attrs = %{
      "answer" => "Use the source-control release-branch meaning.",
      "resolution_message_id" => first.id
    }

    assert {:error, :conversation_busy} =
             LinguisticReviews.answer(owner, project, session.id, review.id, attrs)

    {:ok, message} = Toki.claim(next)

    {:ok, _} =
      Toki.finish(message, {:ok, "Agreed: use the source-control release-branch meaning."})

    assert {:error, :resolution_outdated} =
             LinguisticReviews.answer(owner, project, session.id, review.id, attrs)

    assert Repo.get!(Review, review.id).status == "open"

    refute Repo.exists?(
             from s in TranslationSession, where: s.continued_from_session_id == ^session.id
           )

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} = LinguisticReviews.pause(session.id)
      attrs = Map.put(attrs, "resolution_message_id", Repo.get_by!(Message, reply_to_id: next).id)

      assert {:ok,
              %{
                answer: "Use the source-control release-branch meaning.",
                resumed_session_id: resumed
              }} = LinguisticReviews.answer(owner, project, session.id, review.id, attrs)

      assert is_binary(resumed)
      assert {:ok, _} = LinguisticReviews.answer(owner, project, session.id, review.id, attrs)
      assert length(all_enqueued(worker: TranslateWorker)) == 1

      assert {:error, :goal_closed} =
               Toki.send_message(teammate, project, id, %{
                 "id" => Ecto.UUID.generate(),
                 "content" => "Late discussion"
               })
    end)

    assert {1, _} = Glossia.Organizations.remove_member(org, teammate)
    assert {:error, _} = Toki.get_conversation(teammate, project, id)
  end

  test "answered history cannot hide an open question behind the response limit", c do
    open = request!(c.session, "latest.txt")
    old = DateTime.add(open.inserted_at, -60)

    template =
      Map.take(
        open,
        ~w(translation_session_id source_path locale fingerprint reason question source_excerpt translation_excerpt context_targets)a
      )

    rows =
      for index <- 1..500 do
        Map.merge(template, %{
          id: Ecto.UUID.generate(),
          output_path: "history-#{index}.txt",
          status: "answered",
          answer: "Approved",
          inserted_at: old,
          updated_at: old
        })
      end

    Repo.insert_all(Review, rows)

    assert {:ok, [first | rest]} = LinguisticReviews.list(c.user, c.project, c.session.id)
    assert first.id == open.id
    assert length(rest) == 499
  end

  test "answers are replay-safe, and only the last answer after runner release queues a continuation",
       c do
    first = request!(c.session, "a.txt")
    second = request!(c.session, "b.txt")

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, %{status: "answered", resumed_session_id: nil}} =
               answer(c, first, %{"answer" => "A source-control branch."})

      assert all_enqueued(worker: TranslateWorker) == []
      assert {:ok, %{status: "awaiting_input"}} = LinguisticReviews.pause(c.session.id)
      assert all_enqueued(worker: TranslateWorker) == []

      attrs = %{
        "answer" => "A product launch.",
        "guidance" => "Launch refers to a product release.",
        "context_scope" => "project",
        "context_path" => "../../not-allowed"
      }

      assert {:ok, review} = answer(c, second, attrs)
      assert review.context_path == "L10N.md"
      assert is_binary(review.resumed_session_id)
      assert {:ok, %{resumed_session_id: resumed}} = answer(c, second, attrs)
      assert resumed == review.resumed_session_id
      assert length(all_enqueued(worker: TranslateWorker)) == 1
      continuation = Repo.get!(TranslationSession, resumed)
      assert continuation.continued_from_session_id == c.session.id
      assert continuation.commit_sha == c.session.commit_sha
      assert continuation.project_id == c.project.id
      assert Repo.get!(Review, first.id).resumed_session_id == resumed

      assert {:error, :already_answered} =
               answer(c, second, %{"answer" => "A different decision."})

      assert length(all_enqueued(worker: TranslateWorker)) == 1
    end)
  end

  test "a newer source supersedes waiting questions, and foreign IDs or read-only scopes cannot answer",
       c do
    review = request!(c.session, "a.txt")
    assert {:ok, %{status: "awaiting_input"}} = LinguisticReviews.pause(c.session.id)

    assert {:error, :insufficient_scope, "translation:write"} =
             LinguisticReviews.answer(
               c.user,
               c.project,
               c.session.id,
               review.id,
               %{"answer" => "No"},
               scopes: ["translation:read"]
             )

    {:ok, other} = Projects.create_project(c.user.account, %{handle: "other", name: "Other"})
    other = Repo.preload(other, :account)

    assert {:error, :not_found} =
             LinguisticReviews.answer(c.user, other, c.session.id, review.id, %{"answer" => "No"})

    assert {:error, :not_found} =
             LinguisticReviews.answer(c.user, c.project, Ecto.UUID.generate(), review.id, %{
               "answer" => "No"
             })

    assert {:ok, _} =
             TranslationSessions.start_continuous_session(
               c.project,
               %{commit_sha: "new-source", target_languages: ["es"]},
               enqueue: false
             )

    assert Repo.get!(Review, review.id).status == "stale"
    assert {:error, :stale} = answer(c, review, %{"answer" => "Too late"})

    assert Repo.aggregate(
             from(s in TranslationSession,
               where: s.continued_from_session_id == ^c.session.id
             ),
             :count
           ) == 0
  end

  test "cancelling a waiting run invalidates its questions and does not resume from a cached session",
       c do
    review = request!(c.session, "a.txt")

    TranslationSessions.broadcast_session_event(c.session, %{
      type: "item_awaiting_input",
      seq: 1,
      index: 0,
      output_path: "a.txt",
      locale: "es"
    })

    assert {:ok, _} = LinguisticReviews.pause(c.session.id)

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, %{status: "cancelled"}} = TranslationSessions.cancel_session(c.session)
      assert Repo.get!(Review, review.id).status == "stale"
      assert {:error, :stale} = answer(c, review, %{"answer" => "Too late"})
      assert {:error, :not_cancellable} = TranslationSessions.cancel_session(c.session)
      assert all_enqueued(worker: TranslateWorker) == []

      assert [%{status: :cancelled}] =
               c.session.id
               |> TranslationSessions.session_progress()
               |> Glossia.TranslationSessions.Progress.items()
    end)
  end

  @tag :tmp_dir
  test "real repository run holds only ambiguous output, then uses the answer and proposes locale guidance",
       c do
    root = c.tmp_dir
    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "test@example.test"])
    git!(root, ["config", "user.name", "Tester"])

    File.write!(Path.join(root, "L10N.md"), """
    ---
    source_language: en
    sources:
      "docs/*.txt": "es/*.txt"
    targets:
      es: Spanish
    ---
    Technical product documentation.
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join(root, "docs/a.txt"), "Launch a branch.")
    File.write!(Path.join(root, "docs/b.txt"), "Hello team.")
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "baseline"])

    {:ok, _} =
      LLMModels.create_model(c.user.account, c.user, %{
        handle: "writer",
        model: "openai/gpt-4o-mini",
        api_key: "test-writer"
      })

    {:ok, _} =
      LLMModels.create_model(c.user.account, c.user, %{
        handle: "judge",
        category: "decision",
        model: "typesafe/jev-latest",
        api_key: "test-judge"
      })

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      text =
        cond do
          payload["source_content"] == "Hello team." ->
            "Hola equipo."

          String.contains?(payload["custom_prompt"] || "", "source-control") ->
            "Crea una rama de publicación."

          true ->
            "Lanza una rama."
        end

      {:ok, %{text: text, model: "openai/gpt-4o-mini", provider: "openai"}}
    end)

    stub(Req, :post, fn _url, opts ->
      %{state: state, questions: questions} = Keyword.fetch!(opts, :json)

      missing =
        String.starts_with?(state.source, "Launch a branch.") and
          not String.contains?(state.document_instructions || "", "source-control")

      answers =
        Map.new(questions, fn {key, question} ->
          choice = if key == "human_input" and missing, do: "missing_context", else: "none"

          value =
            if question.type == "score",
              do: %{"type" => "score", "score" => 8.0, "confidence" => 0.2},
              else: %{"type" => "choice", "choice" => choice, "confidence" => 0.2}

          {key, value}
        end)

      {:ok, %Req.Response{status: 200, body: %{"answers" => answers}}}
    end)

    assert {:awaiting_input, changes} =
             RepositoryRun.translate_repository(c.session, c.user.account, root, ["es"],
               translation_concurrency: 1
             )

    assert File.read!(Path.join(root, "es/b.txt")) == "Hola equipo."
    refute File.exists?(Path.join(root, "es/a.txt"))
    refute Enum.any?(changes, &(&1.path == "es/a.txt"))

    assert [%{status: :awaiting_input}, %{status: :done}] =
             c.session.id
             |> TranslationSessions.session_progress()
             |> Glossia.TranslationSessions.Progress.items()

    assert {:ok, [review]} = LinguisticReviews.list(c.user, c.project, c.session.id)
    assert review.source_excerpt == "Launch a branch."

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, %{translated_content_count: 1}} = LinguisticReviews.pause(c.session.id)

      assert {:ok, answered} =
               answer(c, review, %{
                 "answer" => "A source-control release branch.",
                 "guidance" => "Branch means a source-control branch, not a tree limb.",
                 "context_scope" => "locale"
               })

      continuation = Repo.get!(TranslationSession, answered.resumed_session_id)
      {:ok, continuation} = TranslationSessions.start_session(continuation)
      git!(root, ["add", "."])
      git!(root, ["commit", "-q", "-m", "checkpoint independent file"])

      assert {:ok, resumed_changes} =
               RepositoryRun.translate_repository(continuation, c.user.account, root, ["es"],
                 translation_concurrency: 1
               )

      assert File.read!(Path.join(root, "es/a.txt")) == "Crea una rama de publicación."
      refute Enum.any?(resumed_changes, &(&1.path == "es/b.txt"))
      proposal = Enum.find(resumed_changes, &(&1.path == "L10N/es.md"))
      assert proposal.content =~ "Branch means a source-control branch"
      refute File.exists?(Path.join(root, "L10N/es.md"))
      refute LinguisticReviews.open_for_session?(continuation.id)

      File.write!(Path.join(root, "docs/a.txt"), "Launch a branch.\nDifferent source context.")

      assert {:awaiting_input, _} =
               RepositoryRun.translate_repository(continuation, c.user.account, root, ["es"],
                 translation_concurrency: 1
               )

      assert LinguisticReviews.open_for_session?(continuation.id)
    end)
  end

  defp request!(session, output) do
    {:ok, review} =
      LinguisticReviews.request(
        session.id,
        %{
          source_path: "docs/source.txt",
          output_path: output,
          locale: "es",
          context_targets: %{
            "project" => %{"path" => "L10N.md", "digest" => nil},
            "locale" => %{"path" => "L10N/es.md", "digest" => nil}
          }
        },
        String.duplicate("a", 64),
        %{
          reason: "missing_context",
          question: "Which meaning applies?",
          source: "Source",
          translation: "Target"
        }
      )

    review
  end

  defp answer(c, review, attrs) do
    current = Repo.get!(Review, review.id)

    resolution =
      current.resolution_message_id ||
        if current.status == "open" do
          conversation = Repo.get_by!(Conversation, linguistic_review_id: review.id)
          turn = Ecto.UUID.generate()

          {:ok, _} =
            Toki.send_message(c.user, c.project, conversation.id, %{
              "id" => turn,
              "content" => attrs["answer"]
            })

          {:ok, message} = Toki.claim(turn)
          {:ok, _} = Toki.finish(message, {:ok, "Proposed decision: " <> attrs["answer"]})
          Repo.get_by!(Message, reply_to_id: turn).id
        end

    LinguisticReviews.answer(
      c.user,
      c.project,
      c.session.id,
      review.id,
      Map.put(attrs, "resolution_message_id", resolution)
    )
  end

  defp git!(root, args) do
    {_output, 0} =
      MuonTrap.cmd(
        "git",
        ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-C", root | args],
        into: "",
        timeout: 10_000
      )
  end
end
