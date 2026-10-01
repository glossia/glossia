defmodule GlossiaWeb.DashboardLiveProjectNewTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions

  @repository %{
    "repo-id" => "424242",
    "full-name" => "acme/website",
    "name" => "website",
    "default-branch" => "main",
    "description" => "Marketing website",
    "development" => "false",
    "owner-login" => "acme"
  }

  setup %{conn: conn} do
    user = TestHelpers.create_user("project-new@test.com", "project-new")

    %{conn: init_test_session(conn, %{user_id: user.id}), user: user}
  end

  test "selecting a repository asks how the project should be set up", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")

    render_hook(view, "select_repo", @repository)

    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=mode")
    assert has_element?(view, "#setup-mode-picker", "acme/website")
    assert has_element?(view, "#setup-modes", "Automated setup")
    assert has_element?(view, "#setup-modes", "Manual configuration")
  end

  test "automated setup continues to the target languages", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")

    render_hook(view, "select_repo", @repository)
    render_click(view, "choose_setup_mode", %{"mode" => "automated"})

    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=languages")
    assert has_element?(view, "#language-picker")
    assert Projects.get_project(user.account, "website") == nil
  end

  test "manual configuration creates the project without running setup", %{
    conn: conn,
    user: user
  } do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")

    render_hook(view, "select_repo", @repository)

    {:ok, project_view, _html} =
      view
      |> render_click("choose_setup_mode", %{"mode" => "manual"})
      |> follow_redirect(conn, "/#{user.account.handle}/website")

    project = Projects.get_project(user.account, "website")

    assert project.github_repo_id == 424_242
    assert project.github_repo_full_name == "acme/website"
    assert project.github_repo_default_branch == "main"
    assert project.setup_status == nil
    assert project.setup_target_languages == []

    assert has_element?(project_view, "#manual-configuration-notice")
    refute has_element?(project_view, "#setup-progress-card")
  end

  test "the manual configuration notice goes away after the first translation run", %{
    conn: conn,
    user: user
  } do
    {:ok, project} =
      Projects.create_project(user.account, %{handle: "website", name: "website"})

    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")
    assert has_element?(view, "#manual-configuration-notice")

    {:ok, _session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "first-sha",
        commit_message: "Add L10N.md",
        status: "completed",
        outcome: "translated",
        source_language: "en",
        target_languages: []
      })

    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")
    refute has_element?(view, "#manual-configuration-notice")
  end

  test "the setup step cannot be opened without a repository", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new?step=mode")

    refute has_element?(view, "#setup-mode-picker")
  end
end
