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
    assert has_element?(view, "#setup-mode-picker [data-mode=automated]", "Automated setup")
    assert has_element?(view, "#setup-mode-picker [data-mode=manual]", "Manual configuration")

    assert has_element?(
             view,
             "#setup-mode-picker [data-mode=local]",
             "Set up locally with an agent"
           )
  end

  test "automated setup continues to the target languages", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")

    render_hook(view, "select_repo", @repository)
    render_click(view, "choose_setup_mode", %{"mode" => "automated"})

    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=languages")
    assert has_element?(view, "#language-picker")

    refute has_element?(view, "#language-es[data-selected]")
    view |> element("#language-es") |> render_click()
    assert has_element?(view, "#language-es[data-selected]")
    assert has_element?(view, "#language-picker", "1 language selected")
    assert Projects.get_project(user.account, "website") == nil
  end

  test "local setup retains instructions after creating the project without automated setup", %{
    conn: conn,
    user: user
  } do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")
    render_hook(view, "select_repo", @repository)
    view |> element("[data-mode=local] button") |> render_click()
    assert_patch(view, "/#{user.account.handle}/-/projects/new?step=local")
    assert has_element?(view, "#local-agent-server[readonly]")
    assert has_element?(view, "a[href='/docs/reference/mcp'][target='_blank']")
    assert has_element?(view, "#local-agent-prompt", "acme/website")

    assert has_element?(
             view,
             "#local-agent-prompt",
             "Use account #{user.account.handle} and project website"
           )

    assert has_element?(view, "#local-agent-prompt", "/mcp")
    assert has_element?(view, "#local-agent-prompt", "If it is missing, stop")
    assert has_element?(view, "#local-agent-prompt", "access is denied, continue")
    assert has_element?(view, "#local-agent-prompt", "Ask me which target languages")
    assert has_element?(view, "#local-agent-prompt", "Never create header-only target catalogs")

    assert has_element?(
             view,
             "#local-agent-prompt",
             "Do not translate target values during setup"
           )

    refute has_element?(view, "#local-agent-prompt", "Infer target languages conservatively")
    assert Projects.get_project(user.account, "website") == nil
    view |> element("button[phx-click=create_local_project]") |> render_click()
    resume_path = "/#{user.account.handle}/-/projects/new?project=website&step=local"
    assert_patch(view, resume_path)
    project = Projects.get_project(user.account, "website")
    assert project.github_repo_id == 424_242
    assert project.setup_status == nil
    assert project.setup_target_languages == []
    assert has_element?(view, "#local-agent-prompt")
    refute has_element?(view, "button[phx-click=create_local_project]")
    assert has_element?(view, "a[href='/#{user.account.handle}/website']", "Open project")

    render_hook(view, "create_local_project", %{})
    assert Projects.get_project(user.account, "website").id == project.id
    refute has_element?(view, "#local-agent-setup button", "Back")

    render_patch(view, "/#{user.account.handle}/-/projects/new?step=mode")
    assert_patch(view, resume_path)
    refute has_element?(view, "#setup-mode-picker")

    {:ok, resumed_view, _html} = live(conn, resume_path)
    assert has_element?(resumed_view, "#local-agent-prompt", "project website")
    assert has_element?(resumed_view, "#local-agent-setup", "Project created")
    refute has_element?(resumed_view, "button[phx-click=create_local_project]")

    {:ok, project_view, _html} = live(conn, "/#{user.account.handle}/website")
    assert has_element?(project_view, "#manual-configuration-notice a[href='#{resume_path}']")
  end

  test "local setup requires selecting a repository", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/-/projects/new?step=local")
    refute has_element?(view, "#local-agent-setup")
    assert has_element?(view, "#project-new", "Connect a Git provider")
  end

  test "local setup cannot resume a project from another account", %{conn: conn, user: user} do
    other_user = TestHelpers.create_user("other-project@test.com", "other-project")

    {:ok, _project} =
      Projects.create_project(other_user.account, %{
        handle: "private-project",
        name: "Private project",
        github_repo_id: 123,
        github_repo_full_name: "private/project"
      })

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/-/projects/new?project=private-project&step=local")

    refute has_element?(view, "#local-agent-setup")
    refute has_element?(view, "#project-new", "private/project")
  end

  test "local setup cannot resume an automated setup project", %{conn: conn, user: user} do
    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "automated",
        name: "Automated",
        github_repo_id: 123,
        github_repo_full_name: "acme/automated",
        setup_status: "running"
      })

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/-/projects/new?project=#{project.handle}&step=local")

    refute has_element?(view, "#local-agent-setup")
  end

  test "two local setup tabs adopt the same project", %{conn: conn, user: user} do
    {:ok, first_view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")
    {:ok, second_view, _html} = live(conn, "/#{user.account.handle}/-/projects/new")

    for view <- [first_view, second_view] do
      render_hook(view, "select_repo", @repository)
      render_click(view, "choose_setup_mode", %{"mode" => "local"})
    end

    render_click(first_view, "create_local_project", %{})
    first_project = Projects.get_project(user.account, "website")
    render_click(second_view, "create_local_project", %{})
    assert_patch(second_view, "/#{user.account.handle}/-/projects/new?project=website&step=local")
    assert Projects.get_project(user.account, "website").id == first_project.id
    assert has_element?(second_view, "#local-agent-setup", "Project created")
    refute has_element?(second_view, "[role=alert]", "has already been taken")
  end

  test "local project creation rejects a socket without write permission", %{user: user} do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, can_write: false, flash: %{}}}

    assert {:noreply, socket} =
             GlossiaWeb.DashboardLive.handle_event("create_local_project", %{}, socket)

    assert socket.assigns.flash["error"] == "You don't have permission to create projects here."
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
