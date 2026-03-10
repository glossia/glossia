defmodule Glossia.TranslationsTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.Translations
  alias Glossia.Projects
  alias GlossiaWeb.ApiTestHelpers

  setup do
    user = ApiTestHelpers.create_user("translations@test.com", "translations-user")
    account = user.account

    {:ok, project} =
      Projects.create_project(account, %{
        handle: "trans-proj-#{System.unique_integer([:positive])}",
        name: "Translations Project"
      })

    stub(Glossia.Sandbox.Docker, :delete, fn _id -> :ok end)

    %{account: account, project: project}
  end

  describe "cancel_active_translations/1" do
    test "cancels pending translations", %{account: account, project: project} do
      {:ok, translation} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "abc123",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert {:ok, 1} = Translations.cancel_active_translations(project)

      updated = Repo.get!(Translations.Translation, translation.id)
      assert updated.status == "failed"
      assert updated.error == "Cancelled: superseded by newer commit"
      assert updated.completed_at != nil
    end

    test "cancels running translations", %{account: account, project: project} do
      {:ok, translation} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "def456",
          "status" => "running",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert {:ok, 1} = Translations.cancel_active_translations(project)

      updated = Repo.get!(Translations.Translation, translation.id)
      assert updated.status == "failed"
    end

    test "does not cancel already completed or failed translations", %{
      account: account,
      project: project
    } do
      {:ok, _completed} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "comp1",
          "status" => "completed",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      {:ok, _failed} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "fail1",
          "status" => "failed",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert {:ok, 0} = Translations.cancel_active_translations(project)
    end

    test "cancels multiple active translations", %{account: account, project: project} do
      for sha <- ["aaa", "bbb", "ccc"] do
        Translations.create_translation(account, project, %{
          "commit_sha" => sha,
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })
      end

      assert {:ok, 3} = Translations.cancel_active_translations(project)
    end

    test "does not affect translations from other projects", %{
      account: account,
      project: project
    } do
      {:ok, other_project} =
        Projects.create_project(account, %{
          handle: "other-proj-#{System.unique_integer([:positive])}",
          name: "Other Project"
        })

      {:ok, _own} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "own1",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      {:ok, other} =
        Translations.create_translation(account, other_project, %{
          "commit_sha" => "other1",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["fr"]
        })

      assert {:ok, 1} = Translations.cancel_active_translations(project)

      other_updated = Repo.get!(Translations.Translation, other.id)
      assert other_updated.status == "pending"
    end

    test "deletes sandbox when cancelling translation with sandbox_id", %{
      account: account,
      project: project
    } do
      {:ok, translation} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "sandbox1",
          "status" => "running",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      {:ok, _} = Translations.update_translation_sandbox_id(translation, "glossia-sandbox-123")

      expect(Glossia.Sandbox.Docker, :delete, fn "glossia-sandbox-123" -> :ok end)

      assert {:ok, 1} = Translations.cancel_active_translations(project)
    end
  end

  describe "get_translation/1" do
    test "returns nil for invalid UUID", %{} do
      assert Translations.get_translation("not-a-uuid") == nil
    end

    test "returns nil for non-existent UUID", %{} do
      assert Translations.get_translation(Ecto.UUID.generate()) == nil
    end

    test "returns translation with preloaded associations", %{
      account: account,
      project: project
    } do
      {:ok, translation} =
        Translations.create_translation(account, project, %{
          "commit_sha" => "xyz",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      result = Translations.get_translation(translation.id)
      assert result.id == translation.id
      assert result.project.id == project.id
      assert result.account.id == account.id
    end
  end
end
