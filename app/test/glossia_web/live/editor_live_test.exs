defmodule GlossiaWeb.EditorLiveTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Glossia.{Editor, Projects, Repo, TestHelpers}
  alias Glossia.Editor.File, as: EditorFile

  setup %{conn: conn} do
    user =
      TestHelpers.create_user(
        "editor-web-#{System.unique_integer([:positive])}@test.com",
        "editor-web"
      )

    {:ok, project} = Projects.create_project(user.account, %{handle: "website", name: "Website"})

    %{
      user: user,
      project: %{project | account: user.account},
      conn: init_test_session(conn, %{user_id: user.id})
    }
  end

  test "empty editor, sidebar entry, and structured drafts across navigation", c do
    path = ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor"
    {:ok, view, _} = live(c.conn, path)
    assert has_element?(view, "#platform-sidebar a[href$='/-/editor']", "Editor")

    assert has_element?(
             view,
             "#editor-files .noora-table-empty-state",
             "Your content starts here"
           )

    source =
      Repo.insert!(%EditorFile{
        project_id: c.project.id,
        path: "en/home.json",
        source_path: "en/home.json",
        locale: "en",
        format: "json",
        content: ~s({"title":"Welcome","count":7})
      })

    target =
      Repo.insert!(%EditorFile{
        project_id: c.project.id,
        path: "es/home.json",
        source_path: source.path,
        locale: "es",
        format: "json",
        content: ~s({"title":"Hola","count":7})
      })

    {:ok, view, _} =
      live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor/#{target.id}")

    assert has_element?(view, "[data-part='source']", "Welcome")
    assert has_element?(view, "textarea[aria-label='Title']", "Hola")
    refute has_element?(view, "textarea[aria-label='Count']")
    {:ok, [field]} = Glossia.Editor.Content.fields("json", target.content)
    form(view, "#editor-form", %{"values" => %{field.id => "Bienvenidos"}}) |> render_change()
    assert has_element?(view, "#editor-publish[disabled]")
    form(view, "#editor-form", %{"values" => %{field.id => "Bienvenidos"}}) |> render_submit()
    assert has_element?(view, "[data-part='save-status']", "Draft saved")

    {:ok, reloaded, _} =
      live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor/#{target.id}")

    assert has_element?(reloaded, "textarea", "Bienvenidos")

    assert Jason.decode!(Repo.get!(EditorFile, target.id).draft_content) == %{
             "title" => "Bienvenidos",
             "count" => 7
           }

    {:ok, filtered, _} =
      live(
        c.conn,
        ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor?#{%{search: "BIENVENIDOS", sort: "path", direction: "desc"}}"
      )

    assert has_element?(filtered, "#editor-search-results", "Bienvenidos")
    assert has_element?(filtered, "#editor-search-results", "es/home.json")
    refute has_element?(filtered, "#editor-search-results", "en/home.json")
    assert has_element?(filtered, "#editor-search-results a[href*='#{target.id}#editor-field-']")
  end

  test "Markdown visual editing preserves frontmatter and never renders executable HTML", c do
    record =
      Repo.insert!(%EditorFile{
        project_id: c.project.id,
        path: "guide.md",
        source_path: "guide.md",
        locale: "en",
        format: "markdown",
        content: "---\ntitle: Guide\npublished: true\n---\n# Welcome\n"
      })

    {:ok, view, _} =
      live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor/#{record.id}")

    assert has_element?(view, "#editor-preview h1", "Welcome")
    assert has_element?(view, "[data-part='visual-surface']")
    assert has_element?(view, "button", "Bold")
    refute has_element?(view, "textarea", "published: true")
    refute has_element?(view, "textarea[name='values[body]']")

    render_change(view, "change", %{
      "values" => %{"body" => "## Edited\n\n<script>alert(1)</script>\n"}
    })

    assert has_element?(view, "input[type='hidden'][name='values[body]'][value^='## Edited']")
    refute has_element?(view, "#editor-preview script")
    assert {:ok, record} = Editor.get_file(c.user, c.project, record.id)
    assert is_nil(record.draft_content)
  end

  test "content search finds nested text rather than filenames, keys, or old drafts", c do
    record =
      Repo.insert!(%EditorFile{
        project_id: c.project.id,
        path: "filename-only.json",
        source_path: "filename-only.json",
        locale: "es",
        format: "json",
        content: ~s({"old_key":"Outdated text","count":42}),
        draft_content:
          Jason.encode!(%{
            "old_key" => [%{"title" => String.duplicate("Intro ", 60) <> "Café [special]."}],
            "count" => 42
          })
      })

    path = ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor"
    {:ok, view, _} = live(c.conn, path)
    form(view, "[data-part='toolbar'] form", %{search: "CAFÉ [special]."}) |> render_change()

    assert_patch(
      view,
      ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor?#{%{search: "CAFÉ [special]."}}"
    )

    assert has_element?(view, "#editor-search-results", "Café [special].")
    assert has_element?(view, "#editor-search-results a[href*='#{record.id}#editor-field-']")

    for query <- ["filename-only", "old_key", "Outdated text", "42"] do
      {:ok, empty, _} =
        live(
          c.conn,
          ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor?#{%{search: query}}"
        )

      assert has_element?(empty, "#editor-search-results", "No matching text")
    end
  end

  test "writers select multiple saved drafts while conflicts and clean files stay out", c do
    records =
      for {path, draft, conflict} <- [
            {"a.json", "A draft", false},
            {"b.md", "B draft", false},
            {"c.txt", nil, false},
            {"d.txt", "conflict", true}
          ] do
        Repo.insert!(%EditorFile{
          project_id: c.project.id,
          path: path,
          source_path: path,
          locale: "en",
          format: "text",
          content: "original",
          draft_content: draft,
          conflict: conflict
        })
      end

    [a, b, clean, conflict] = records
    {:ok, view, _} = live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor")
    assert has_element?(view, "#editor-publish-many[disabled]")
    refute has_element?(view, "#editor-select-#{clean.id}")
    refute has_element?(view, "#editor-select-#{conflict.id}")
    render_hook(view, "select_file:#{a.id}", %{checked: true})
    render_hook(view, "select_file:#{b.id}", %{checked: true})
    assert has_element?(view, "#editor-publish-many:not([disabled])", "2 files")
    render_hook(view, "select_file:#{a.id}", %{checked: false})
    assert has_element?(view, "#editor-publish-many", "1 files")
  end

  test "recovered forms retain their original version and cannot overwrite newer drafts", c do
    record =
      Repo.insert!(%EditorFile{
        project_id: c.project.id,
        path: "page.txt",
        source_path: "page.txt",
        locale: "en",
        format: "text",
        content: "Original"
      })

    path = ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor/#{record.id}"
    {:ok, original, _} = live(c.conn, path)
    assert has_element?(original, "input[name='version'][value='1']")
    {:ok, _} = Editor.save(c.user, c.project, record.id, 1, %{"text" => "Bob saved"})

    {:ok, recovered, _} = live(c.conn, path)
    assert has_element?(recovered, "input[name='version'][value='2']")

    render_change(recovered, "change", %{
      "file_id" => record.id,
      "version" => "1",
      "values" => %{"text" => "Alice unsaved"}
    })

    assert has_element?(recovered, "input[name='version'][value='1']")
    form(recovered, "#editor-form") |> render_submit()
    assert has_element?(recovered, "[role='alert']", "changed")
    assert Repo.get!(EditorFile, record.id).draft_content == "Bob saved"
  end

  test "frozen publications remain retryable after a file becomes conflicted or inactive", c do
    for {conflict, active} <- [{true, true}, {false, false}] do
      record =
        Repo.insert!(%EditorFile{
          project_id: c.project.id,
          path: "page-#{conflict}.txt",
          source_path: "page-#{conflict}.txt",
          locale: "en",
          format: "text",
          content: "Original",
          draft_content: "Frozen draft",
          branch: "glossia/editor/frozen-#{conflict}",
          conflict: conflict,
          active: active
        })

      {:ok, view, _} =
        live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor/#{record.id}")

      assert has_element?(view, "#editor-publish:not([disabled])", "Retry pull request")
    end
  end

  test "anonymous visitors cannot read private repository files even on a public account", c do
    conn = build_conn() |> init_test_session(%{})

    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/editor")
    end
  end
end
