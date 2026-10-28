defmodule GlossiaEnterpriseWeb.SCIMControllerTest do
  use GlossiaWeb.ConnCase, async: true
  alias Glossia.{Accounts, Authz, MemberPermissions, Organizations, Repo, TestHelpers}
  alias GlossiaEnterprise.{OrganizationAuthentication, SCIM}
  alias GlossiaEnterprise.SCIM.Token
  use Oban.Testing, repo: Glossia.Repo
  import Swoosh.TestAssertions

  @patch_schema "urn:ietf:params:scim:api:messages:2.0:PatchOp"

  setup do
    admin = TestHelpers.create_user("owner@example.test", "scim-owner")

    {:ok, %{organization: organization}} =
      Organizations.create_organization(
        admin,
        %{handle: "scim-#{System.unique_integer([:positive])}"}
      )

    {:ok, %{token: token, plaintext: plaintext}} =
      SCIM.create_token(organization, admin, %{name: "Okta"})

    %{
      organization: Repo.preload(organization, :account),
      admin: admin,
      token: token,
      plaintext: plaintext
    }
  end

  test "authenticates only dedicated SCIM tokens and revocation takes effect immediately",
       context do
    assert Repo.get!(Token, context.token.id).token_hash != context.plaintext
    conn = get(build_conn(), ~p"/scim/v2/Users")
    assert body(conn, 401)["status"] == "401"
    assert get_resp_header(conn, "www-authenticate") != []
    assert body(get(api("glsa_not_a_scim_token"), ~p"/scim/v2/Users"), 401)["status"] == "401"

    conn = get(api(context.plaintext), ~p"/scim/v2/ServiceProviderConfig")
    assert body(conn, 200)["patch"]["supported"]
    assert get_resp_header(conn, "cache-control") == ["no-store"]

    outsider = TestHelpers.create_user("outsider@example.test", "outsider")

    assert {:error, :unauthorized} =
             SCIM.create_token(context.organization, outsider, %{name: "No"})

    assert {:error, :unauthorized} =
             SCIM.revoke_token(context.organization, outsider, context.token.id)

    assert {:ok, _} = SCIM.revoke_token(context.organization, context.admin, context.token.id)
    assert body(get(api(context.plaintext), ~p"/scim/v2/Users"), 401)["status"] == "401"
  end

  test "provisions, filters, updates, deactivates and reactivates an organization member",
       context do
    conn =
      post(
        api(context.plaintext),
        ~p"/scim/v2/Users",
        Jason.encode!(%{
          userName: "Jamie@company.test",
          displayName: "Jamie Smith",
          externalId: "okta-jamie"
        })
      )

    resource = body(conn, 201)
    id = resource["id"]
    assert resource["userName"] == "jamie@company.test"
    assert resource["active"]
    assert get_resp_header(conn, "location") == [resource["meta"]["location"]]
    user = Accounts.get_user(id)

    assert Organizations.get_membership(context.organization, user).scopes ==
             MemberPermissions.basic_scopes()

    refute Authz.authorize?(:translation_write, user, context.organization.account)
    assert Accounts.list_user_identities(user) == []

    duplicate =
      post(api(context.plaintext), ~p"/scim/v2/Users", Jason.encode!(%{userName: user.email}))
      |> body(201)

    assert duplicate["id"] == id

    for filter <- [~s(userName eq "JAMIE@company.test"), ~s(externalId eq "okta-jamie")] do
      page = get(api(context.plaintext), ~p"/scim/v2/Users?#{%{filter: filter}}") |> body(200)
      assert page["totalResults"] == 1
      assert [%{"id" => ^id}] = page["Resources"]
    end

    changed =
      patch_user(context, id, [
        %{op: "Replace", value: %{displayName: "Jamie Updated", active: true}}
      ])
      |> body(200)

    assert changed["displayName"] == "Jamie Updated"
    assert changed["active"]

    other = Accounts.ensure_personal_organization!(user)
    assert response(delete(api(context.plaintext), ~p"/scim/v2/Users/#{id}"), 204) == ""
    refute Organizations.get_membership(context.organization, user)
    assert Organizations.get_membership(other, user)
    refute Authz.authorize?(:organization_read, user, context.organization.account)
    refute body(get(api(context.plaintext), ~p"/scim/v2/Users/#{id}"), 200)["active"]

    assert patch_user(context, id, [%{op: "replace", path: "active", value: true}])
           |> body(200)
           |> Map.fetch!("active")

    assert Organizations.get_membership(context.organization, user)
  end

  test "tenant boundaries and immutable email prevent existing-account takeover", context do
    outsider = TestHelpers.create_user("existing@company.test", "existing")

    conn =
      post(api(context.plaintext), ~p"/scim/v2/Users", Jason.encode!(%{userName: outsider.email}))

    assert body(conn, 409)["scimType"] == "uniqueness"

    assert body(get(api(context.plaintext), ~p"/scim/v2/Users/#{outsider.id}"), 404)["status"] ==
             "404"

    assert body(
             patch_user(context, outsider.id, [%{op: "replace", path: "active", value: false}]),
             404
           )["status"] == "404"

    {:ok, _} = Organizations.add_member(context.organization, outsider)

    conn =
      post(api(context.plaintext), ~p"/scim/v2/Users", Jason.encode!(%{userName: outsider.email}))

    assert body(conn, 201)["id"] == outsider.id
    refute SCIM.claim_identity(context.organization, outsider)

    conn =
      patch_user(context, outsider.id, [
        %{op: "replace", path: "userName", value: "victim@company.test"}
      ])

    assert body(conn, 400)["scimType"] == "mutability"
    assert Accounts.get_user(outsider.id).email == outsider.email

    assert body(get(api(context.plaintext), ~p"/scim/v2/Users/not-a-uuid"), 404)["status"] ==
             "404"

    {:ok, %{organization: second}} =
      Organizations.create_organization(outsider, %{
        handle: "other-#{System.unique_integer([:positive])}"
      })

    assert {:error, :not_found} = SCIM.revoke_token(second, outsider, context.token.id)
    assert {:ok, _} = SCIM.authenticate_token(context.plaintext)
  end

  test "invalid requests fail without applying earlier operations", context do
    for invalid <- [
          %{userName: []},
          %{userName: "invalid"},
          %{userName: "new@example.test", active: "false"}
        ] do
      assert body(post(api(context.plaintext), ~p"/scim/v2/Users", Jason.encode!(invalid)), 400)[
               "scimType"
             ] == "invalidValue"
    end

    conn =
      patch_user(context, context.admin.id, [
        %{op: "replace", path: "displayName", value: "Must not persist"},
        %{op: "replace", path: "password", value: "unsupported"}
      ])

    assert body(conn, 400)["scimType"] == "invalidPath"

    refute body(get(api(context.plaintext), ~p"/scim/v2/Users/#{context.admin.id}"), 200)[
             "displayName"
           ] == "Must not persist"

    assert body(
             patch_user(context, context.admin.id, [
               %{op: "replace", path: "active", value: false}
             ]),
             409
           )["status"] == "409"

    assert Organizations.get_membership(context.organization, context.admin).role == "admin"

    for filter <- [~s(userName co "example"), ~s(password eq "x"), ~s(userName eq "unterminated)] do
      assert body(get(api(context.plaintext), ~p"/scim/v2/Users?#{%{filter: filter}}"), 400)[
               "scimType"
             ] == "invalidFilter"
    end

    page = get(api(context.plaintext), ~p"/scim/v2/Users?#{%{count: 0}}") |> body(200)
    assert page["totalResults"] == 1
    assert page["Resources"] == []
    assert page["itemsPerPage"] == 0

    assert body(get(api(context.plaintext), ~p"/scim/v2/Users?#{%{count: "1junk"}}"), 400)[
             "status"
           ] == "400"
  end

  test "synthetic groups change roles atomically and preserve a final administrator", context do
    member = TestHelpers.create_user("linguist@example.test", "linguist")
    {:ok, _} = Organizations.add_member(context.organization, member)

    page =
      get(
        api(context.plaintext),
        ~p"/scim/v2/Groups?#{%{filter: ~s(displayName eq "Linguists")}}"
      )
      |> body(200)

    assert [%{"id" => "linguists", "members" => []}] = page["Resources"]

    conn =
      patch_group(context, "linguists", [
        %{op: "add", path: "members", value: [%{value: member.id}]}
      ])

    assert [%{"value" => id}] = body(conn, 200)["members"]
    assert id == member.id
    assert Organizations.get_membership(context.organization, member).role == "linguist"

    conn =
      patch_group(context, "linguists", [
        %{op: "remove", path: ~s(members[value eq "#{member.id}"])},
        %{op: "add", path: "members", value: [%{value: Uniq.UUID.uuid7()}]}
      ])

    assert body(conn, 404)["status"] == "404"
    assert Organizations.get_membership(context.organization, member).role == "linguist"

    # Replacing the sole admin is allowed when the replacement is promoted first.
    conn =
      patch_group(context, "admins", [
        %{op: "replace", path: "members", value: [%{value: member.id}]}
      ])

    assert [%{"value" => ^id}] = body(conn, 200)["members"]
    assert Organizations.get_membership(context.organization, context.admin).role == "member"

    assert Organizations.get_membership(context.organization, context.admin).scopes ==
             MemberPermissions.basic_scopes()

    refute Authz.authorize?(:project_write, context.admin, context.organization.account)

    conn =
      patch_group(context, "admins", [%{op: "remove", path: ~s(members[value eq "#{member.id}"])}])

    assert body(conn, 409)["status"] == "409"
  end

  test "only SCIM-created accounts can link their first organization identity without a prior login",
       context do
    {:ok, organization} =
      OrganizationAuthentication.save(context.organization, context.admin, %{
        "auth_provider" => "google",
        "auth_domain" => "company-#{System.unique_integer([:positive])}.test"
      })

    {:ok, organization} =
      OrganizationAuthentication.verify(organization, context.admin, fn _ ->
        {:ok, [OrganizationAuthentication.record_value(organization)]}
      end)

    email = "new@#{organization.auth_domain}"

    resource =
      post(api(context.plaintext), ~p"/scim/v2/Users", Jason.encode!(%{userName: email}))
      |> body(201)

    response = %{
      user: %{
        "sub" => "idp-new",
        "email" => email,
        "email_verified" => true,
        "hd" => organization.auth_domain
      },
      token: %{}
    }

    assert {:ok, user} = OrganizationAuthentication.sign_in(organization, response)
    assert user.id == resource["id"]
    assert {:ok, _} = SCIM.deactivate_user(organization, user.id)

    assert {:error, :membership_revoked} =
             OrganizationAuthentication.sign_in(organization, response)

    assert {:ok, _} = SCIM.update_user(organization, user.id, %{active: true})
    assert {:ok, _} = OrganizationAuthentication.sign_in(organization, response)

    inactive =
      post(
        api(context.plaintext),
        ~p"/scim/v2/Users",
        Jason.encode!(%{userName: "inactive@#{organization.auth_domain}", active: false})
      )
      |> body(201)

    refute inactive["active"]

    assert {:error, _} =
             OrganizationAuthentication.sign_in(
               organization,
               put_in(response.user, %{
                 "sub" => "inactive",
                 "email" => inactive["userName"],
                 "email_verified" => true,
                 "hd" => organization.auth_domain
               })
             )
  end

  test "attachment emails are transactional, idempotent, and skip revoked access", context do
    Oban.Testing.with_testing_mode(:manual, fn ->
      worker = GlossiaEnterprise.SCIM.AttachmentNotifierWorker

      {:ok, %{user: user}} =
        SCIM.provision_user(context.organization, %{user_name: "notified@company.test"})

      [job] = all_enqueued(worker: worker)
      assert job.args == %{"user_id" => user.id, "organization_id" => context.organization.id}
      assert :ok = perform_job(worker, job.args)

      assert_email_sent(fn email ->
        assert email.to == [{"", user.email}]
        assert email.text_body =~ "automated user provisioning (SCIM)"
        assert email.text_body =~ "contact your identity provider administrator"
        assert email.html_body =~ ~p"/#{context.organization.account.handle}"
      end)

      {:ok, _} = SCIM.provision_user(context.organization, %{user_name: user.email})
      assert length(all_enqueued(worker: worker)) == 1

      # Provisioning validation runs after membership creation and job insertion.
      assert {:error, %Ecto.Changeset{}} =
               SCIM.provision_user(context.organization, %{
                 user_name: "rolled-back@company.test",
                 external_id: String.duplicate("x", 256)
               })

      assert length(all_enqueued(worker: worker)) == 1
      refute Accounts.get_user_by_email("rolled-back@company.test")
      {:ok, _} = SCIM.deactivate_user(context.organization, user.id)
      assert :ok = perform_job(worker, job.args)
      assert_no_email_sent()
      {:ok, _} = SCIM.update_user(context.organization, user.id, %{active: true})
      assert length(all_enqueued(worker: worker)) == 2
    end)
  end

  defp api(token) do
    build_conn()
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/scim+json")
    |> put_req_header("content-type", "application/scim+json")
  end

  defp patch_user(context, id, operations),
    do:
      patch(
        api(context.plaintext),
        ~p"/scim/v2/Users/#{id}",
        Jason.encode!(%{schemas: [@patch_schema], Operations: operations})
      )

  defp patch_group(context, id, operations),
    do:
      patch(
        api(context.plaintext),
        ~p"/scim/v2/Groups/#{id}",
        Jason.encode!(%{schemas: [@patch_schema], Operations: operations})
      )

  defp body(conn, status) do
    assert get_resp_header(conn, "content-type") == ["application/scim+json; charset=utf-8"]
    conn |> response(status) |> Jason.decode!()
  end
end
