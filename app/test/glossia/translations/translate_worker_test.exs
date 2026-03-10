defmodule Glossia.Translations.TranslateWorkerTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.Translations
  alias Glossia.Translations.{TranslateWorker, Translation}
  alias Glossia.Projects
  alias GlossiaWeb.ApiTestHelpers

  setup do
    user = ApiTestHelpers.create_user("worker@test.com", "worker-user")
    account = user.account

    {:ok, project} =
      Projects.create_project(account, %{
        handle: "worker-proj-#{System.unique_integer([:positive])}",
        name: "Worker Project",
        setup_status: "completed",
        setup_target_languages: ["es", "fr"]
      })

    stub(Glossia.Sandbox.Docker, :create, fn _params -> {:ok, "glossia-sandbox-test"} end)
    stub(Glossia.Sandbox.Docker, :delete, fn _id -> :ok end)

    stub(Glossia.Sandbox.Docker, :execute, fn _id, _cmd, _opts ->
      {:ok, %{"exitCode" => 0, "result" => ""}}
    end)

    stub(Glossia.Sandbox.Docker, :upload_file, fn _id, _path, _content -> :ok end)
    stub(Glossia.Sandbox.Docker, :download_file, fn _id, _path -> {:error, :file_not_found} end)

    %{account: account, project: project}
  end

  describe "perform/1" do
    test "creates a translation for a commit", %{project: project} do
      stub(Glossia.Sandbox.Docker, :download_file, fn _id, _path ->
        {:ok, ~s({"status":"completed"})}
      end)

      assert :ok =
               TranslateWorker.perform(%Oban.Job{
                 args: %{
                   "project_id" => project.id,
                   "commit_sha" => "abc123",
                   "commit_message" => "feat: add new feature"
                 }
               })

      translations =
        Repo.all(
          from(t in Translation,
            where: t.project_id == ^project.id and t.commit_sha == "abc123"
          )
        )

      assert length(translations) == 1
      [translation] = translations
      assert translation.source_language == "en"
      assert translation.target_languages == ["es", "fr"]
      assert translation.commit_message == "feat: add new feature"
    end

    test "cancels active translations before creating a new one", %{
      account: account,
      project: project
    } do
      {:ok, existing} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "old-commit",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      stub(Glossia.Sandbox.Docker, :download_file, fn _id, _path ->
        {:ok, ~s({"status":"completed"})}
      end)

      assert :ok =
               TranslateWorker.perform(%Oban.Job{
                 args: %{
                   "project_id" => project.id,
                   "commit_sha" => "new-commit",
                   "commit_message" => "fix: bug fix"
                 }
               })

      cancelled = Repo.get!(Translation, existing.id)
      assert cancelled.status == "failed"
      assert cancelled.error =~ "superseded"
    end

    test "skips translation when no target languages configured", %{account: account} do
      {:ok, empty_project} =
        Projects.create_project(account, %{
          handle: "empty-proj-#{System.unique_integer([:positive])}",
          name: "Empty Project",
          setup_status: "completed",
          setup_target_languages: []
        })

      assert :ok =
               TranslateWorker.perform(%Oban.Job{
                 args: %{
                   "project_id" => empty_project.id,
                   "commit_sha" => "skip123",
                   "commit_message" => "should be skipped"
                 }
               })

      translations =
        Repo.all(
          from(t in Translation,
            where: t.project_id == ^empty_project.id
          )
        )

      assert translations == []
    end
  end
end
