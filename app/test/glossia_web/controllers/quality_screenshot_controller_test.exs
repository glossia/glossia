defmodule GlossiaWeb.QualityScreenshotControllerTest do
  use GlossiaWeb.ConnCase, async: false

  alias Glossia.Quality
  alias Glossia.Quality.Artifacts
  alias Glossia.TestHelpers

  setup %{conn: conn} do
    previous_config = Application.get_env(:glossia, Artifacts)

    directory =
      Path.join(
        System.tmp_dir!(),
        "glossia-quality-screenshots-#{:erlang.unique_integer([:positive])}"
      )

    Application.put_env(:glossia, Artifacts, local_directory: directory)

    on_exit(fn ->
      if previous_config do
        Application.put_env(:glossia, Artifacts, previous_config)
      else
        Application.delete_env(:glossia, Artifacts)
      end

      File.rm_rf!(directory)
    end)

    user = TestHelpers.create_user("quality-screenshot@example.com", "quality-screenshot")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        handle: "captured-site",
        name: "Captured site"
      })

    {:ok, _profile} =
      Quality.upsert_profile(project, %{
        source_locale: "en",
        locale_origins: %{
          "en" => "https://example.com",
          "es" => "https://example.com/es"
        },
        seed_paths: ["/"],
        max_pages: 5
      })

    {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    screenshot_path = Artifacts.store_screenshot(run, "home.png", "captured-image")

    {:ok, page} =
      Quality.create_page(run, %{
        locale: "en",
        logical_path: "/",
        requested_url: "https://example.com/",
        final_url: "https://example.com/",
        title: "Home",
        document_locale: "en",
        visible_text: "Home",
        alternate_links: %{},
        screenshot_path: screenshot_path
      })

    %{
      conn: init_test_session(conn, %{user_id: user.id}),
      user: user,
      project: project,
      run: run,
      page: page
    }
  end

  test "serves a project screenshot to an authorized reviewer", %{
    conn: conn,
    user: user,
    project: project,
    run: run,
    page: page
  } do
    conn =
      get(
        conn,
        ~p"/#{user.account.handle}/#{project.handle}/-/qa/runs/#{run.id}/pages/#{page.id}/screenshot"
      )

    assert response(conn, 200) == "captured-image"
    assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
    assert get_resp_header(conn, "cache-control") == ["private, max-age=300, must-revalidate"]
  end

  test "does not expose a screenshot to a user outside the account", %{
    conn: conn,
    user: user,
    project: project,
    run: run,
    page: page
  } do
    outsider = TestHelpers.create_user("quality-outsider@example.com", "quality-outsider")
    conn = init_test_session(conn, %{user_id: outsider.id})

    conn =
      get(
        conn,
        ~p"/#{user.account.handle}/#{project.handle}/-/qa/runs/#{run.id}/pages/#{page.id}/screenshot"
      )

    assert response(conn, 404) == ""
  end
end
