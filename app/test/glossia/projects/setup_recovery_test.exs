defmodule Glossia.Projects.SetupRecoveryTest do
  use Glossia.DataCase, async: false

  alias Glossia.Accounts.Project
  alias Glossia.Projects.SetupRecovery
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("setup-recovery@test.com", "setup-recovery")
    %{account: user.account}
  end

  test "ordinary test startup leaves persisted setups untouched", %{account: account} do
    projects =
      for status <- ~w(failed pending running completed) do
        Repo.insert!(%Project{
          account_id: account.id,
          handle: status,
          name: status,
          setup_status: status
        })
      end

    assert :ignore = SetupRecovery.start_link([])

    for project <- projects do
      assert Repo.get!(Project, project.id).setup_status == project.setup_status
    end
  end

  test "explicit recovery discards failed setups under test-owned sandbox access", %{
    account: account
  } do
    failed =
      Repo.insert!(%Project{
        account_id: account.id,
        handle: "failed",
        name: "Failed",
        setup_status: "failed"
      })

    completed =
      Repo.insert!(%Project{
        account_id: account.id,
        handle: "completed",
        name: "Completed",
        setup_status: "completed"
      })

    recovery = start_supervised!({SetupRecovery, enabled: true})
    :sys.get_state(recovery)

    refute Repo.get(Project, failed.id)
    assert Repo.get!(Project, completed.id).setup_status == "completed"
  end
end
