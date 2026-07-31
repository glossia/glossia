defmodule Glossia.Analytics.SettingsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Analytics.Settings
  alias Glossia.Projects
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("analytics-settings@test.com", "analytics-settings")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "proj-#{System.unique_integer([:positive])}",
        name: "Analytics Project",
        setup_target_languages: ["de", "fr"]
      })

    %{project: project}
  end

  defp unique_domain, do: "site-#{System.unique_integer([:positive])}.com"

  describe "upsert_for_project/2" do
    test "creates settings, normalizing the domain", %{project: project} do
      domain = unique_domain()

      assert {:ok, settings} =
               Settings.upsert_for_project(project.id, %{domain: "https://WWW.#{domain}/"})

      assert settings.domain == domain
      assert settings.project_id == project.id
    end

    test "updates the existing row instead of inserting a second one", %{project: project} do
      first = unique_domain()
      second = unique_domain()

      {:ok, created} = Settings.upsert_for_project(project.id, %{domain: first})
      {:ok, updated} = Settings.upsert_for_project(project.id, %{domain: second})

      assert created.id == updated.id
      assert updated.domain == second
    end

    test "returns an error changeset for a blank domain", %{project: project} do
      assert {:error, %Ecto.Changeset{}} = Settings.upsert_for_project(project.id, %{domain: ""})
    end
  end

  describe "get_for_project/1" do
    test "returns the row for the project or nil", %{project: project} do
      assert Settings.get_for_project(project.id) == nil

      {:ok, settings} = Settings.upsert_for_project(project.id, %{domain: unique_domain()})
      assert Settings.get_for_project(project.id).id == settings.id
    end
  end

  describe "fetch_for_collection/1" do
    test "resolves an enabled domain to the project and its target languages", %{project: project} do
      domain = unique_domain()
      {:ok, _} = Settings.upsert_for_project(project.id, %{domain: domain})

      assert %{project_id: project_id, target_languages: ["de", "fr"], enabled: true} =
               Settings.fetch_for_collection("https://#{domain}/some/page")

      assert project_id == project.id
    end

    test "returns nil for an unknown or blank domain" do
      assert Settings.fetch_for_collection(unique_domain()) == nil
      assert Settings.fetch_for_collection("") == nil
    end

    test "returns nil when the domain is disabled", %{project: project} do
      domain = unique_domain()
      {:ok, settings} = Settings.upsert_for_project(project.id, %{domain: domain})

      settings
      |> Ecto.Changeset.change(enabled: false)
      |> Repo.update!()

      Glossia.Analytics.SettingsCache.delete(domain)

      assert Settings.fetch_for_collection(domain) == nil
    end
  end
end
