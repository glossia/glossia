defmodule GlossiaEnterprise.AuditTest do
  use Glossia.DataCase, async: true

  alias Glossia.{Events, Organizations, TestHelpers}
  alias GlossiaEnterprise.Audit

  setup do
    admin = TestHelpers.create_user("audit-owner@example.test", "audit-owner")

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(admin, %{
        handle: "audit-#{System.unique_integer([:positive])}"
      })

    %{admin: admin, organization: organization, account: account}
  end

  test "domain mutations persist actor snapshots without credentials", %{
    admin: admin,
    account: account,
    organization: organization
  } do
    assert %{rows: [created]} = Audit.list_events(account, admin)
    assert created.name == "organization.created"
    assert created.resource_id == organization.id
    assert created.actor_handle == admin.account.handle
    assert created.actor_email == admin.email
    assert created.user_id == admin.id
    assert created.occurred_at

    Events.emit("authentication.changed", account, admin,
      resource_type: "organization",
      resource_id: organization.id,
      summary: "Changed identity provider",
      via: "dashboard",
      metadata: %{client_secret: "do-not-store"},
      token: "do-not-store"
    )

    admin |> Ecto.Changeset.change(email: "renamed@example.test") |> Repo.update!()
    assert %{rows: [record]} = Audit.list_events(account, admin, %{"q" => "identity provider"})
    assert record.actor_email == "audit-owner@example.test"
    assert record.metadata == %{"via" => "dashboard"}
    refute inspect(record) =~ "do-not-store"
  end

  test "rolled-back mutations do not leave audit records", %{
    admin: admin,
    account: account,
    organization: organization
  } do
    assert {:error, :cancelled} =
             Repo.transaction(fn ->
               assert {:ok, _} =
                        Organizations.update_organization(organization, %{name: "Cancelled"},
                          actor: admin
                        )

               assert %{rows: [_]} =
                        Audit.list_events(account, admin, %{"q" => "organization.updated"})

               Repo.rollback(:cancelled)
             end)

    assert %{rows: []} = Audit.list_events(account, admin, %{"q" => "organization.updated"})
    refute Organizations.get_organization(organization.id).name == "Cancelled"
  end

  test "only the organization's administrators can read or discover its events", %{
    admin: admin,
    account: account,
    organization: organization
  } do
    member = TestHelpers.create_user("audit-member@example.test", "audit-member")
    outsider = TestHelpers.create_user("audit-outsider@example.test", "audit-outsider")
    {:ok, _} = Organizations.add_member(organization, member)

    {:ok, %{account: other}} =
      Organizations.create_organization(outsider, %{
        handle: "other-#{System.unique_integer([:positive])}"
      })

    Events.emit("private.other_event", other, outsider)

    for visibility <- ["private", "public"] do
      account = account |> Ecto.Changeset.change(visibility: visibility) |> Repo.update!()

      for actor <- [member, outsider, nil] do
        refute Audit.authorized?(actor, account)
        assert_raise Ecto.NoResultsError, fn -> Audit.list_events(account, actor) end
        assert_raise Ecto.NoResultsError, fn -> Audit.filter_values(account, actor) end
      end

      assert Audit.authorized?(admin, account)
      refute "private.other_event" in Audit.filter_values(account, admin)
      assert %{rows: []} = Audit.list_events(account, admin, %{"q" => "private.other_event"})
    end
  end

  test "search, both event operators, sorting, and pagination compose", %{
    admin: admin,
    account: account
  } do
    for n <- 1..51 do
      name = "page." <> String.pad_leading(to_string(n), 2, "0")
      Events.emit(name, account, nil, summary: "Synthetic page event")
    end

    params = %{"q" => "page.", "sort" => "name", "dir" => "asc"}
    assert %{rows: first, total: 51, page: 1} = Audit.list_events(account, admin, params)
    assert length(first) == 50
    assert hd(first).name == "page.01"
    assert List.last(first).name == "page.50"

    assert %{rows: [last], total: 51, page: 2} =
             Audit.list_events(account, admin, Map.put(params, "page", "2"))

    assert last.name == "page.51"
    assert is_nil(last.user_id)

    filter = %{id: "event", operator: :==, value: "page.17"}
    assert %{rows: [match], total: 1} = Audit.list_events(account, admin, params, [filter])
    assert match.name == "page.17"
    assert %{total: 50} = Audit.list_events(account, admin, params, [%{filter | operator: :!=}])

    assert %{rows: [descending | _]} =
             Audit.list_events(account, admin, %{params | "dir" => "desc"})

    assert descending.name == "page.51"

    assert %{sort: "occurred_at", direction: "desc", page: 1} =
             Audit.list_events(account, admin, %{
               "sort" => "invalid",
               "dir" => "invalid",
               "page" => "-1"
             })
  end

  test "enterprise builds configure the audit extension" do
    assert Application.fetch_env!(:glossia, :audit_extension) == Audit
    assert Glossia.Extensions.audit_children() == Audit.children()
  end
end
