defmodule Glossia.TranslationSessions.PublicationLockTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias Glossia.Accounts.{Account, Project}
  alias Glossia.Repo
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.Translate

  # Separate, committed connections are intentional: sandbox callers sharing
  # one connection cannot reproduce a runner racing a webhook on another node.
  test "a replacement waits for publication metadata to commit before inheriting it" do
    {account, project, session} =
      Sandbox.unboxed_run(Repo, fn ->
        account =
          Repo.insert!(%Account{handle: "publication-lock-#{System.unique_integer([:positive])}"})

        project = Repo.insert!(%Project{account_id: account.id, handle: "lock", name: "Lock"})

        {:ok, session} =
          TranslationSessions.create_session(account, project, %{
            commit_sha: "old-source",
            status: "running"
          })

        {account, project, session}
      end)

    on_exit(fn -> Sandbox.unboxed_run(Repo, fn -> Repo.delete!(account) end) end)
    test_pid = self()

    publisher =
      Task.async(fn ->
        Sandbox.unboxed_run(Repo, fn ->
          Translate.serialize_project_publication(project.id, fn ->
            send(test_pid, :publishing)

            receive do
              :finish_push -> :ok
            after
              5_000 -> flunk("publisher was not released")
            end

            TranslationSessions.update_session_publication(session, %{
              publication_branch: "glossia/translate-old-source",
              publication_commit_sha: "published-commit",
              pull_request_url: "https://github.com/example/repo/pull/1",
              pull_request_number: 1
            })
          end)
        end)
      end)

    assert_receive :publishing, 1_000

    # This fails with the old :global lock even if both test tasks happen to
    # share a node: the publication must actually hold a PostgreSQL row lock.
    Sandbox.unboxed_run(Repo, fn ->
      error =
        assert_raise Postgrex.Error, fn ->
          Repo.query!("SELECT id FROM projects WHERE id = $1 FOR UPDATE NOWAIT", [
            Ecto.UUID.dump!(project.id)
          ])
        end

      assert error.postgres.code == :lock_not_available
    end)

    replacement =
      Task.async(fn ->
        Sandbox.unboxed_run(Repo, fn ->
          TranslationSessions.start_continuous_session(
            project,
            %{commit_sha: "new-source"},
            enqueue: false
          )
        end)
      end)

    assert Task.yield(replacement, 20) == nil
    send(publisher.pid, :finish_push)
    assert {:ok, _} = Task.await(publisher)
    assert {:ok, next} = Task.await(replacement)
    assert next.continued_from_session_id == session.id
    assert next.publication_commit_sha == "published-commit"
    assert next.publication_branch == "glossia/translate-old-source"
    assert next.pull_request_number == 1
  end
end
