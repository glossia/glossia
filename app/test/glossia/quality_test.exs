defmodule Glossia.QualityTest do
  use Glossia.DataCase, async: true

  alias Glossia.Quality
  alias Glossia.TestHelpers
  alias Glossia.Translations.Context

  setup do
    user = TestHelpers.create_user("quality@example.com", "quality")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        handle: "quality-project",
        name: "Quality project"
      })

    %{user: user, project: project}
  end

  test "validates and normalizes a browser profile", %{project: project} do
    assert {:error, changeset} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{"en" => "https://example.com"},
               seed_paths: "pricing",
               max_pages: 100
             })

    assert %{locale_origins: [_], seed_paths: [_], max_pages: [_]} = errors_on(changeset)

    assert {:ok, profile} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => " https://example.com ",
                 "es" => "https://example.com/es"
               },
               seed_paths: "/\n/pricing\n",
               max_pages: 10
             })

    assert profile.locale_origins["en"] == "https://example.com"
    assert profile.seed_paths == ["/", "/pricing"]
  end

  test "bounds the total browser captures across locales", %{project: project} do
    origins = %{
      "xaa" => "https://xaa.example.com",
      "xab" => "https://xab.example.com",
      "xac" => "https://xac.example.com"
    }

    paths = Enum.map(1..50, &"/page-#{&1}")

    assert {:error, changeset} =
             Quality.upsert_profile(project, %{
               source_locale: "xaa",
               locale_origins: origins,
               seed_paths: paths,
               max_pages: 50
             })

    assert %{max_pages: [_message]} = errors_on(changeset)
  end

  test "allows only one active run per project", %{user: user, project: project} do
    create_profile(project)

    assert {:ok, _run} = Quality.create_run(user.account, project, user, enqueue: false)

    assert {:error, :quality_run_already_active} =
             Quality.create_run(user.account, project, user, enqueue: false)
  end

  test "cancelling an interrupted run frees the project for another run", %{
    user: user,
    project: project
  } do
    create_profile(project)
    assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    page = create_page(run)

    assert {:ok, cancelled} = Quality.cancel_run(run)
    assert cancelled.status == "cancelled"
    assert cancelled.completed_at

    assert {:error, :quality_run_not_active} = Quality.complete_run(run)

    assert {:error, :quality_run_not_active} =
             Quality.record_finding(run, page, finding_attrs())

    assert {:ok, replacement} =
             Quality.create_run(user.account, project, user, enqueue: false)

    assert replacement.status == "pending"
  end

  test "cancelling a run cancels its queued browser job", %{user: user, project: project} do
    create_profile(project)

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, run} = Quality.create_run(user.account, project, user)

      job =
        Repo.one!(
          from job in Oban.Job,
            where: fragment("?->>'run_id' = ?", job.args, ^to_string(run.id))
        )

      assert job.worker == Oban.Worker.to_string(Glossia.Quality.RunWorker)
      assert job.state == "available"

      assert {:ok, _cancelled} = Quality.cancel_run(run)
      assert Repo.get!(Oban.Job, job.id).state == "cancelled"
    end)
  end

  test "expires a running review that stopped reporting", %{user: user, project: project} do
    create_profile(project)
    assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    assert {:ok, running} = Quality.mark_run_running(run, nil)
    stale_at = DateTime.add(DateTime.utc_now(), -31, :minute)

    {1, _rows} =
      Repo.update_all(
        from(quality_run in Glossia.Quality.Run, where: quality_run.id == ^run.id),
        set: [updated_at: stale_at]
      )

    Quality.expire_stale_runs(project)

    failed = Quality.get_run!(project, running.id)
    assert failed.status == "failed"
    assert failed.error == "The browser worker stopped before the review completed."
  end

  test "paginates runs and prunes old browser evidence", %{user: user, project: project} do
    create_profile(project)

    pages =
      for index <- 1..26 do
        assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)

        assert {:ok, page} =
                 Quality.create_page(run, %{
                   locale: "es",
                   logical_path: "/page-#{index}",
                   requested_url: "https://example.com/es/page-#{index}",
                   visible_text: "Evidence for page #{index}"
                 })

        assert {:ok, _completed} = Quality.complete_run(run)
        page
      end

    assert {:ok, {runs, meta}} = Quality.list_runs(project)
    assert length(runs) == 25
    assert meta.total_pages == 2

    refute Repo.get(Glossia.Quality.Page, List.first(pages).id)

    assert Repo.get!(Glossia.Quality.Page, List.last(pages).id).visible_text ==
             "Evidence for page 26"
  end

  test "rejects locale and path values that cannot fit persisted evidence", %{project: project} do
    long_locale = "en-" <> String.duplicate("abcdefgh-", 8) <> "ab"

    assert {:error, locale_changeset} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => "https://example.com",
                 long_locale => "https://example.com/long"
               },
               seed_paths: ["/"],
               max_pages: 10
             })

    assert %{locale_origins: [_message]} = errors_on(locale_changeset)

    assert {:error, path_changeset} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => "https://example.com",
                 "es" => "https://example.com/es"
               },
               seed_paths: ["/" <> String.duplicate("a", 255)],
               max_pages: 10
             })

    assert %{seed_paths: [_message]} = errors_on(path_changeset)
  end

  test "deduplicates findings across runs and counts distinct findings", %{
    user: user,
    project: project
  } do
    profile = create_profile(project)
    {:ok, first_run} = Quality.create_run(user.account, project, user, enqueue: false)
    first_page = create_page(first_run)

    attrs = finding_attrs()
    assert {:ok, first_finding} = Quality.record_finding(first_run, first_page, attrs)
    assert {:ok, same_finding} = Quality.record_finding(first_run, first_page, attrs)
    assert same_finding.id == first_finding.id

    assert {:ok, completed} = Quality.complete_run(first_run)
    assert completed.pages_count == 1
    assert completed.findings_count == 1

    assert profile.project_id == project.id

    {:ok, second_run} = Quality.create_run(user.account, project, user, enqueue: false)
    second_page = create_page(second_run)
    assert {:ok, recurring} = Quality.record_finding(second_run, second_page, attrs)
    assert recurring.id == first_finding.id
    assert length(Quality.get_finding!(project, recurring.id).occurrences) == 2
  end

  test "approved finding translations become immutable project context", %{
    user: user,
    project: project
  } do
    create_profile(project)
    {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    page = create_page(run)
    {:ok, finding} = Quality.record_finding(run, page, finding_attrs())

    assert {:ok, first_context} =
             Quality.remember_translation(project, finding, user, "Configuración de la cuenta")

    assert first_context.version == 1
    assert [%{instruction: "Configuración de la cuenta"}] = first_context.entries

    assert %{version: 1, terminology: [term]} =
             Quality.resolve_project_context(project, 1, "es-MX")

    assert term.term == "Account settings"
    assert term.translation == "Configuración de la cuenta"

    assert {:ok, snapshot} = Context.snapshot(user.account, project)
    assert snapshot.project_context_version == 1

    locale_contexts =
      user.account
      |> Context.resolve_locales(project, snapshot, ["es-MX"])
      |> Context.prepare_locale_contexts()

    bundle =
      Context.build_bundle(
        snapshot,
        locale_contexts,
        "es-MX",
        "Open Account settings.",
        [],
        "content/account.md"
      )

    assert Context.prompt_body(bundle, "Open Account settings.", []) =~
             ~s("Account settings" → "Configuración de la cuenta")

    provenance = Context.provenance(bundle)
    assert provenance["project_context"]["version"] == 1
    refute Jason.encode!(provenance) =~ "Configuración"

    another_repository_file_bundle =
      Context.build_bundle(
        snapshot,
        locale_contexts,
        "es-MX",
        "Open Account settings.",
        [],
        "content/pricing.md"
      )

    assert Context.prompt_body(
             another_repository_file_bundle,
             "Open Account settings.",
             []
           ) =~ "Configuración de la cuenta"
  end

  test "project context versions store only deltas and preserve historical resolution", %{
    user: user,
    project: project
  } do
    create_profile(project)
    {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    page = create_page(run)
    {:ok, finding} = Quality.record_finding(run, page, finding_attrs())

    assert {:ok, first_context} =
             Quality.remember_translation(project, finding, user, "Configuración")

    assert {:ok, second_context} = Quality.remember_translation(project, finding, user, "Ajustes")

    assert first_context.version == 1
    assert second_context.version == 2
    assert [%{instruction: "Ajustes"}] = second_context.entries

    assert Repo.aggregate(Glossia.Quality.ProjectContextEntry, :count) == 2

    assert %{terminology: [%{translation: "Configuración"}]} =
             Quality.resolve_project_context(project, 1, "es")

    assert %{terminology: [%{translation: "Ajustes"}]} =
             Quality.resolve_project_context(project, 2, "es")
  end

  test "bounds translations approved into project context", %{user: user, project: project} do
    create_profile(project)
    {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    page = create_page(run)
    {:ok, finding} = Quality.record_finding(run, page, finding_attrs())

    assert {:error, :translation_too_long} =
             Quality.remember_translation(project, finding, user, String.duplicate("a", 4_001))
  end

  defp create_profile(project) do
    {:ok, profile} =
      Quality.upsert_profile(project, %{
        source_locale: "en",
        locale_origins: %{
          "en" => "https://example.com",
          "es" => "https://example.com/es"
        },
        seed_paths: ["/account"],
        max_pages: 10
      })

    profile
  end

  defp create_page(run) do
    {:ok, page} =
      Quality.create_page(run, %{
        locale: "es",
        logical_path: "/account",
        requested_url: "https://example.com/es/account",
        final_url: "https://example.com/es/account",
        document_locale: "es",
        visible_text: "Account settings"
      })

    page
  end

  defp finding_attrs do
    %{
      check: "possible_untranslated_content",
      category: "language",
      severity: "medium",
      title: "Possible untranslated content",
      description: "The translated page contains the source text.",
      locale: "es",
      logical_path: "/account",
      source_text: "Account settings",
      target_text: "Account settings",
      metadata: %{}
    }
  end
end
