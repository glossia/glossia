defmodule GlossiaWeb.GithubWebhookControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  alias Glossia.Projects
  alias Glossia.TranslationSessions.TranslationSession
  alias GlossiaWeb.ApiTestHelpers

  import Ecto.Query

  setup do
    user = ApiTestHelpers.create_user("webhook-ctrl@test.com", "webhook-ctrl")
    account = user.account

    {:ok, project} =
      Projects.create_project(account, %{
        handle: "webhook-proj-#{System.unique_integer([:positive])}",
        name: "Webhook Project",
        github_repo_id: 54321,
        github_repo_full_name: "acme/webhook-project",
        github_repo_default_branch: "main",
        setup_status: "completed",
        setup_target_languages: ["ja"]
      })

    stub(Glossia.Github.Webhook, :verify, fn _headers, _payload, _secret -> :ok end)

    %{project: project}
  end

  describe "POST /webhooks/github" do
    test "creates a translation session for a valid push event", %{conn: conn, project: project} do
      payload =
        JSON.encode!(%{
          "ref" => "refs/heads/main",
          "repository" => %{"id" => project.github_repo_id},
          "head_commit" => %{
            "id" => "webhook-sha-123",
            "message" => "docs: update readme"
          }
        })

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-github-event", "push")
        |> post("/webhooks/github", payload)

      assert conn.status == 200

      sessions =
        Glossia.Repo.all(
          from(s in TranslationSession,
            where: s.project_id == ^project.id and s.commit_sha == "webhook-sha-123"
          )
        )

      assert length(sessions) == 1
    end

    test "passes event type from x-github-event header", %{conn: conn} do
      payload =
        JSON.encode!(%{
          "action" => "opened",
          "installation" => %{"id" => 999, "account" => %{"login" => "test"}}
        })

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-github-event", "installation")
        |> post("/webhooks/github", payload)

      assert conn.status == 200
    end

    test "returns 400 for invalid signature", %{conn: conn} do
      stub(Glossia.Github.Webhook, :verify, fn _headers, _payload, _secret ->
        {:error, :invalid_signature}
      end)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-github-event", "push")
        |> post("/webhooks/github", JSON.encode!(%{"ref" => "refs/heads/main"}))

      assert conn.status == 400
    end
  end
end
