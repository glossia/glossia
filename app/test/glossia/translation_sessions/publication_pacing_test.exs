defmodule Glossia.TranslationSessions.PublicationPacingTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.Project
  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.PublicationPacing
  alias Glossia.TranslationSessions.Translate

  setup do
    user = TestHelpers.create_user("publication-pacing@test.com", "publication-pacing")
    {:ok, project} = Projects.create_project(user.account, %{handle: "pacing", name: "Pacing"})
    %{user: user, project: project}
  end

  defp admit(project, now, max_pushes \\ 4) do
    Translate.serialize_project_publication(project.id, fn ->
      assert Repo.in_transaction?()
      PublicationPacing.admit(project.id, now: now, max_pushes_per_hour: max_pushes)
    end)
  end

  test "spaces all pushes, rather than allowing a burst at the hour boundary", %{project: project} do
    now = ~U[2026-10-24 09:59:59.000000Z]
    assert :ok = admit(project, now)
    assert {:wait, 900_000} = admit(project, now)
    assert {:wait, 899_000} = admit(project, DateTime.add(now, 1))
    assert {:wait, 1} = admit(project, DateTime.add(now, 899_999, :millisecond))
    assert :ok = admit(project, DateTime.add(now, 900))
    assert {:wait, 900_000} = admit(project, DateTime.add(now, 900))
  end

  test "a replacement session inherits the project budget", %{user: user, project: project} do
    now = DateTime.utc_now()
    {:ok, _first} = TranslationSessions.create_session(user.account, project, %{commit_sha: "a"})
    assert :ok = admit(project, now)

    {:ok, _replacement} =
      TranslationSessions.start_continuous_session(project, %{commit_sha: "b"}, enqueue: false)

    assert {:wait, 900_000} = admit(project, now)
    assert Repo.get!(Project, project.id).translation_last_pushed_at == now
  end

  test "independent projects have independent budgets", %{user: user, project: project} do
    {:ok, other} = Projects.create_project(user.account, %{handle: "other", name: "Other"})
    now = DateTime.utc_now()
    assert :ok = admit(project, now)
    assert :ok = admit(other, now)
  end

  test "rounds up intervals for rates that do not divide an hour", %{project: project} do
    now = DateTime.utc_now()
    assert :ok = admit(project, now, 7)
    assert {:wait, 514_286} = admit(project, now, 7)
  end

  test "starts the next interval after a slow publication finishes", %{project: project} do
    finished_at =
      Translate.serialize_project_publication(project.id, fn ->
        PublicationPacing.run(project.id, fn ->
          Process.sleep(2)
          DateTime.utc_now()
        end)
      end)

    recorded_at = Repo.get!(Project, project.id).translation_last_pushed_at
    assert DateTime.compare(recorded_at, finished_at) in [:gt, :eq]
    assert {:wait, 900_000} = admit(project, recorded_at)
  end

  test "ambiguous failed attempts also consume a slot", %{project: project} do
    assert {:error, :timeout} =
             Translate.serialize_project_publication(project.id, fn ->
               PublicationPacing.run(project.id, fn -> {:error, :timeout} end)
             end)

    recorded_at = Repo.get!(Project, project.id).translation_last_pushed_at
    assert {:wait, 900_000} = admit(project, recorded_at)
  end

  test "rejects invalid rates instead of silently disabling the cap", %{project: project} do
    for invalid <- [0, -1, "4"] do
      assert_raise ArgumentError, fn -> admit(project, DateTime.utc_now(), invalid) end
    end
  end
end
