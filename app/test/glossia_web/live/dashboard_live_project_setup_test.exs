defmodule GlossiaWeb.DashboardLiveProjectSetupTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.TestHelpers

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
  end

  test "failed setup exposes a Noora progress panel and retry action", %{conn: conn} do
    user = TestHelpers.create_user("project-retry@test.com", "project-retry")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "failed-setup",
        name: "Failed setup",
        github_repo_id: 321,
        github_repo_full_name: "example/failed-setup",
        github_repo_default_branch: "main",
        setup_status: "failed",
        setup_error: "The setup environment took too long to start. Please retry setup.",
        setup_target_languages: ["es"]
      })

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")

    assert has_element?(view, "#setup-progress-card.noora-card")

    assert has_element?(
             view,
             "#setup-progress-card .noora-alert",
             "The setup environment took too long to start. Please retry setup."
           )

    assert has_element?(view, "#setup-progress-card .noora-button", "Retry setup")
  end
end
