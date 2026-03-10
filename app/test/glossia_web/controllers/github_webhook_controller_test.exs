defmodule GlossiaWeb.GithubWebhookControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  alias Glossia.Projects
  alias Glossia.Translations.Translation
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
    stub(Glossia.Sandbox.Docker, :create, fn _params -> {:ok, "glossia-sandbox-test"} end)
    stub(Glossia.Sandbox.Docker, :delete, fn _id -> :ok end)

    stub(Glossia.Sandbox.Docker, :execute, fn _id, _cmd, _opts ->
      {:ok, %{"exitCode" => 0, "result" => ""}}
    end)

    stub(Glossia.Sandbox.Docker, :upload_file, fn _id, _path, _content -> :ok end)

    stub(Glossia.Sandbox.Docker, :download_file, fn _id, _path ->
      {:ok, ~s({"status":"completed"})}
    end)

    %{project: project}
  end

  describe "POST /webhooks/github" do
    test "creates a translation for a valid push event", %{conn: conn, project: project} do
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

      translations =
        Glossia.Repo.all(
          from(t in Translation,
            where: t.project_id == ^project.id and t.commit_sha == "webhook-sha-123"
          )
        )

      assert length(translations) == 1
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
