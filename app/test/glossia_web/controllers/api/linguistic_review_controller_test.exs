defmodule GlossiaWeb.Api.LinguisticReviewControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{LinguisticReviews, Projects, Repo, TestHelpers, TranslationSessions}
  alias Glossia.TranslationSessions.TranslateWorker

  test "scoped shared reviews accept one decision and return its continuation", %{conn: conn} do
    unique = System.unique_integer([:positive])
    user = TestHelpers.create_user("review-api-#{unique}@test.com", "review-api-#{unique}")
    outsider = TestHelpers.create_user("review-outsider-#{unique}@test.com", "outsider-#{unique}")
    {:ok, project} = Projects.create_project(user.account, %{handle: "docs", name: "Docs"})
    project = Repo.preload(project, :account)
    {:ok, other} = Projects.create_project(user.account, %{handle: "other", name: "Other"})
    {:ok, foreign} = TranslationSessions.create_session(user.account, other, %{})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "running"})

    {:ok, review} =
      LinguisticReviews.request(
        session.id,
        %{
          source_path: "docs/start.txt",
          output_path: "es/start.txt",
          locale: "es",
          context_targets: %{"locale" => %{"path" => "L10N/es.md", "digest" => nil}}
        },
        String.duplicate("a", 64),
        %{
          reason: "missing_context",
          question: "Which kind of branch?",
          source: "Create a branch.",
          translation: "Crea una rama."
        }
      )

    {:ok, _} = LinguisticReviews.pause(session.id)

    list =
      ~p"/api/#{user.account.handle}/projects/#{project.handle}/translations/#{session.id}/reviews"

    answer =
      ~p"/api/#{user.account.handle}/projects/#{project.handle}/translations/#{session.id}/reviews/#{review.id}/answer"

    read = TestHelpers.authenticate(conn, user, ["translation:read"])
    write = TestHelpers.authenticate(conn, user, ~w(translation:read translation:write))

    assert conn |> get(list) |> json_response(401)

    assert conn
           |> TestHelpers.authenticate(outsider, ["translation:read"])
           |> get(list)
           |> json_response(403)

    assert [%{"id" => id, "question" => "Which kind of branch?"}] =
             read |> get(list) |> json_response(200) |> Map.fetch!("reviews")

    assert id == review.id

    assert read
           |> post(answer, %{answer: "Source control"})
           |> json_response(403)
           |> Map.fetch!("required_scope") == "translation:write"

    assert write |> post(answer, %{answer: "   "}) |> json_response(422)

    for id <- ["invalid", foreign.id, Ecto.UUID.generate()] do
      assert read
             |> get(
               ~p"/api/#{user.account.handle}/projects/#{project.handle}/translations/#{id}/reviews"
             )
             |> json_response(404)
    end

    Oban.Testing.with_testing_mode(:manual, fn ->
      conversation = Repo.get_by!(Glossia.Toki.Conversation, linguistic_review_id: review.id)
      turn = Ecto.UUID.generate()

      {:ok, _} =
        Glossia.Toki.send_message(user, project, conversation.id, %{
          "id" => turn,
          "content" => "It means source control."
        })

      {:ok, message} = Glossia.Toki.claim(turn)
      {:ok, _} = Glossia.Toki.finish(message, {:ok, "Use the source-control meaning."})
      resolution = Repo.get_by!(Glossia.Toki.Message, reply_to_id: turn)

      detail =
        conn
        |> TestHelpers.authenticate(user, ~w(toki:read translation:read))
        |> get(
          ~p"/api/#{user.account.handle}/projects/#{project.handle}/toki/conversations/#{conversation.id}"
        )
        |> json_response(200)

      assert detail["conversation"]["linguistic_review"]["id"] == review.id
      assert detail["conversation"]["linguistic_review"]["conversation_id"] == conversation.id
      assert [_, human, assistant] = detail["messages"]
      assert human["user_id"] == user.id
      assert human["status"] == "completed"
      assert assistant["reply_to_id"] == turn
      assert assistant["author"] == "Toki"

      attrs = %{
        answer: "A source-control branch.",
        resolution_message_id: resolution.id,
        guidance: "Branch means a source-control branch.",
        context_scope: "locale",
        context_path: "../../secret"
      }

      body = write |> post(answer, attrs) |> json_response(200)
      assert body["review"]["status"] == "answered"
      assert body["review"]["context_path"] == "L10N/es.md"
      assert is_binary(body["review"]["resumed_session_id"])
      assert write |> post(answer, attrs) |> json_response(200) == body

      assert write |> post(answer, %{answer: "A tree limb."}) |> json_response(409) == %{
               "error" => "already_answered"
             }

      assert length(all_enqueued(worker: TranslateWorker)) == 1
    end)
  end
end
