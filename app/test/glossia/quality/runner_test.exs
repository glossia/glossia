defmodule Glossia.Quality.RunnerTest do
  use Glossia.DataCase, async: false

  alias Glossia.Quality
  alias Glossia.Quality.Runner
  alias Glossia.TestHelpers

  defmodule FakeAdapter do
    @behaviour Glossia.Sandbox

    def create(params), do: {:ok, to_string(params.id)}
    def execute(_sandbox_id, _command, _opts), do: {:ok, %{}}
    def delete(_sandbox_id), do: :ok
    def download_file(_sandbox_id, _path), do: {:ok, ""}
    def upload_file(_sandbox_id, _path, _content), do: :ok
    def delete_file(_sandbox_id, _path), do: :ok
    def repo_path(_sandbox_id), do: {:ok, "/repo"}
    def start_agent_session(_sandbox_id, _caller, _opts), do: {:ok, self()}
  end

  defmodule FakeBrowser do
    def health_check(_sandbox, _browser_policy), do: :ok

    def capture(_run, _sandbox, "https://example.com/", _artifact_name, browser_policy) do
      assert browser_policy.resolver_rules =~ "MAP example.com "
      assert browser_policy.resolver_rules =~ "MAP * ~NOTFOUND"

      {:ok,
       %{
         title: "Account",
         document_locale: "en",
         visible_text: "Manage your account settings from this page.",
         alternate_links: %{"ES_es" => "https://example.com/es"},
         content_hash: String.duplicate("a", 64),
         screenshot_path: nil
       }}
    end

    def capture(_run, _sandbox, "https://example.com/es", _artifact_name, _browser_policy) do
      {:ok,
       %{
         title: "Cuenta",
         document_locale: "es",
         visible_text: "Manage your account settings from this page.",
         alternate_links: %{"en" => "https://example.com/"},
         content_hash: String.duplicate("b", 64),
         screenshot_path: nil
       }}
    end
  end

  defmodule UnavailableBrowser do
    def health_check(_sandbox, _browser_policy), do: {:error, :browser_sandbox_unavailable}
  end

  test "captures locale pages, persists findings, and destroys its sandbox" do
    user = TestHelpers.create_user("quality-runner@example.com", "quality-runner")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        handle: "quality-runner",
        name: "Quality runner"
      })

    assert {:ok, _profile} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => "https://example.com",
                 "es" => "https://example.com/es"
               },
               seed_paths: ["/"],
               max_pages: 10
             })

    assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)

    assert :ok =
             Runner.run(run.id, sandbox_adapter: FakeAdapter, browser: FakeBrowser)

    completed = Quality.get_run!(project, run.id)
    assert completed.status == "completed"
    assert completed.pages_count == 2
    assert completed.findings_count == 1
    assert completed.sandbox.status == "terminated"

    assert [%{check: "possible_untranslated_content", locale: "es"}] =
             Quality.list_findings(project, run_id: run.id)

    assert Enum.map(Quality.list_session_events(completed), & &1.kind) == [
             "session_started",
             "navigation_started",
             "page_captured",
             "navigation_started",
             "page_captured",
             "analysis_started",
             "finding_recorded",
             "session_completed"
           ]
  end

  test "fails clearly when the browser cannot start securely" do
    user = TestHelpers.create_user("quality-browser-health@example.com", "quality-browser-health")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        handle: "quality-browser-health",
        name: "Quality browser health"
      })

    assert {:ok, _profile} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => "https://example.com",
                 "es" => "https://example.com/es"
               },
               seed_paths: ["/"],
               max_pages: 10
             })

    assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)

    assert {:error, :browser_sandbox_unavailable} =
             Runner.run(run.id, sandbox_adapter: FakeAdapter, browser: UnavailableBrowser)

    failed = Quality.get_run!(project, run.id)
    assert failed.status == "failed"
    assert failed.error == "The browser could not start securely in the review environment."
    assert failed.sandbox.status == "terminated"
  end
end
