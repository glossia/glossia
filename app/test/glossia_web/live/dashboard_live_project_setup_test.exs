defmodule GlossiaWeb.DashboardLiveProjectSetupTest do
  use GlossiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers

  setup do
    setup_config = Application.fetch_env!(:glossia, Glossia.Projects.Setup)

    Application.put_env(
      :glossia,
      Glossia.Projects.Setup,
      setup_config
      |> Keyword.put(:minimax_api_key, nil)
      |> Keyword.put(:harness_model, nil)
      |> Keyword.put(:model, nil)
      |> Keyword.put(:opencode_config, %{})
    )

    on_exit(fn ->
      Application.put_env(:glossia, Glossia.Projects.Setup, setup_config)
    end)

    :ok
  end

  test "new project journey uses Noora controls and keeps step progress visible", %{conn: conn} do
    user = TestHelpers.create_user("project-setup@test.com", "project-setup")
    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")

    assert has_element?(view, "#project-new [data-part='wizard-progress'] .noora-progress-bar")
    assert has_element?(view, "#project-new .noora-alert .noora-button")

    view
    |> render_hook("select_repo", %{
      "repo-id" => "123",
      "full-name" => "example/product",
      "name" => "product",
      "default-branch" => "main",
      "description" => "Example repository",
      "development" => "true",
      "owner-login" => "example"
    })

    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=languages")
    assert has_element?(view, "#language-picker.noora-card")
    assert has_element?(view, ".noora-text-input #language-search")
    assert has_element?(view, "#languages.noora-table")
    assert has_element?(view, "#language-es .noora-button", "Select")

    view
    |> element("#language-es .noora-button")
    |> render_click()

    assert has_element?(view, "#language-es .noora-status-badge", "Selected")
    assert has_element?(view, "#language-picker .noora-button", "Set up project")

    view
    |> element("#language-picker .noora-button", "Set up project")
    |> render_click()

    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=setup")
    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=languages")

    refute Repo.get_by(Glossia.Accounts.Project, github_repo_id: 123)

    assert render(view) =~
             "Project setup failed, so the project was not created. The localization setup model is not configured."
  end

  test "failed setup removes a provisional project and redirects its open page", %{conn: conn} do
    user = TestHelpers.create_user("project-retry@test.com", "project-retry")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "failed-setup",
        name: "Failed setup",
        github_repo_id: 321,
        github_repo_full_name: "example/failed-setup",
        github_repo_default_branch: "main",
        setup_status: "pending",
        setup_target_languages: ["es"]
      })

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")

    {:ok, failed} =
      Projects.update_project_setup_status(project, "failed", "The setup environment failed.")

    assert {:ok, discarded} = Projects.discard_failed_project_setup(failed)
    Projects.broadcast_setup_failure(discarded, discarded.setup_error)

    assert_redirect(view, "/#{user.account.handle}")
    refute Repo.get(Glossia.Accounts.Project, project.id)
  end

  test "reapplying setup page parameters does not duplicate setup events", %{conn: conn} do
    user = TestHelpers.create_user("project-events@test.com", "project-events")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "active-setup",
        name: "Active setup",
        setup_status: "running",
        setup_target_languages: ["es"]
      })

    path = "/#{user.account.handle}/#{project.handle}"
    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _html} = live(conn, path)

    render_patch(view, path)

    Projects.broadcast_setup_event(project, %{
      sequence: 1,
      event_type: "status",
      content: "Inspecting the localization files.",
      metadata: "{}"
    })

    event_rows =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#setup-events .setup-event-row")

    assert Enum.count(event_rows) == 1
  end

  test "project overview shows an open setup pull request until it is merged", %{conn: conn} do
    user = TestHelpers.create_user("project-merge-notice@test.com", "project-merge-notice")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "awaiting-merge",
        name: "Awaiting merge",
        github_repo_id: 9_001,
        setup_status: "completed",
        setup_pull_request_number: 92,
        setup_pull_request_url: "https://github.com/glossia/glossia/pull/92",
        setup_pull_request_state: "open"
      })

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")

    assert has_element?(view, "#setup-pull-request-notice", "Finish setting up Glossia")

    assert has_element?(
             view,
             "#setup-pull-request-notice a[href='https://github.com/glossia/glossia/pull/92']",
             "Open pull request"
           )

    assert {:ok, merged} =
             Projects.update_setup_pull_request_state(
               9_001,
               92,
               "merged",
               ~U[2026-07-22 16:30:00.000000Z]
             )

    Projects.broadcast_setup_pull_request(merged)

    refute has_element?(view, "#setup-pull-request-notice")
    assert has_element?(view, "#commits-table")
  end

  test "project overview explains when the setup pull request was closed", %{conn: conn} do
    user = TestHelpers.create_user("project-closed-notice@test.com", "project-closed-notice")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "closed-setup",
        name: "Closed setup",
        github_repo_id: 9_002,
        setup_status: "completed",
        setup_pull_request_number: 12,
        setup_pull_request_url: "https://github.com/example/product/pull/12",
        setup_pull_request_state: "closed"
      })

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")

    assert has_element?(view, "#setup-pull-request-notice", "Setup pull request was closed")
    assert render(view) =~ "closed without being merged"
    assert has_element?(view, "#setup-pull-request-notice", "View pull request")
  end
end
