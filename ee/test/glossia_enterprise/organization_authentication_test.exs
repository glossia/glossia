defmodule GlossiaEnterprise.OrganizationAuthenticationTest do
  use Glossia.DataCase, async: true
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{
    Authz,
    MemberPermissions,
    Organizations,
    Repo,
    TestHelpers
  }

  alias GlossiaEnterprise.{OrganizationAuthentication, OrganizationDomainVerificationWorker}

  setup do
    admin = TestHelpers.create_user("owner@example.test", "owner")

    {:ok, %{organization: organization}} =
      Organizations.create_organization(admin, %{
        handle: "team-#{System.unique_integer([:positive])}",
        name: "Team"
      })

    {:ok, organization} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "google",
        "auth_domain" => "company-#{System.unique_integer([:positive])}.test"
      })

    %{admin: admin, organization: organization}
  end

  test "requires the exact verification record and an administrator", %{
    admin: admin,
    organization: organization
  } do
    refute OrganizationAuthentication.for_email("new@#{organization.auth_domain}")

    assert {:error, :verification_failed} =
             OrganizationAuthentication.verify(organization, admin, fn _ -> {:ok, ["wrong"]} end)

    outsider = TestHelpers.create_user("outsider@example.test", "outsider")

    assert {:error, :verification_failed} =
             OrganizationAuthentication.verify(organization, outsider, fn _ ->
               flunk("must not resolve for non-administrators")
             end)

    assert {:ok, verified} = verify(organization, admin)
    assert verified.auth_domain_verified_at

    assert OrganizationAuthentication.for_email("new@#{organization.auth_domain}").id ==
             organization.id
  end

  test "changing domain rotates the token and rejects stale verification", %{
    admin: admin,
    organization: organization
  } do
    {:ok, verified} = verify(organization, admin)

    {:ok, same} =
      OrganizationAuthentication.save(verified, admin, %{
        "auth_domain" => String.upcase(verified.auth_domain)
      })

    assert same.auth_domain_token == verified.auth_domain_token
    assert same.auth_domain_verified_at == verified.auth_domain_verified_at

    {:ok, changed} =
      OrganizationAuthentication.save(verified, admin, %{
        "auth_domain" => "different-#{System.unique_integer([:positive])}.test"
      })

    refute changed.auth_domain_verified_at
    refute changed.auth_domain_token == verified.auth_domain_token
    assert {:error, :domain_changed} = verify(verified, admin)
  end

  test "only administrators can change configuration", %{organization: organization} do
    outsider = TestHelpers.create_user("outsider@example.test", "outsider")

    assert {:error, :unauthorized} =
             OrganizationAuthentication.save(organization, outsider, %{"auth_provider" => ""})
  end

  test "Okta issuer is restricted and secrets are encrypted", %{
    admin: admin,
    organization: organization
  } do
    attrs = %{
      "auth_provider" => "okta",
      "auth_issuer" => "https://example.okta.com",
      "auth_client_id" => "client",
      "auth_client_secret" => "secret"
    }

    assert {:error, _} =
             OrganizationAuthentication.save(
               organization,
               admin,
               Map.put(attrs, "auth_issuer", "http://127.0.0.1")
             )

    assert {:error, _} =
             OrganizationAuthentication.save(
               organization,
               admin,
               Map.put(attrs, "auth_issuer", "https://example.okta.com.evil.test")
             )

    assert {:ok, saved} = OrganizationAuthentication.save(organization, admin, attrs)
    assert saved.auth_client_secret == "secret"

    %{rows: [[encrypted]]} =
      Repo.query!("SELECT auth_client_secret FROM organizations WHERE id = $1", [
        Ecto.UUID.dump!(organization.id)
      ])

    refute encrypted == "secret"

    assert {:ok, kept} =
             OrganizationAuthentication.save(saved, admin, %{"auth_client_secret" => ""})

    assert kept.auth_client_secret == "secret"
  end

  test "rejects unverified email, personal Google accounts, and mismatched domains", %{
    admin: admin,
    organization: organization
  } do
    {:ok, organization} = verify(organization, admin)
    info = identity(organization)

    for invalid <- [
          Map.put(info, "email_verified", false),
          Map.delete(info, "hd"),
          Map.put(info, "hd", "other.test"),
          Map.put(info, "email", "person@other.test"),
          Map.delete(info, "sub")
        ] do
      assert {:error, :invalid_identity} =
               OrganizationAuthentication.sign_in(organization, %{user: invalid, token: %{}})
    end
  end

  test "enrolls with basic permissions, keeps existing grants, and is idempotent", %{
    admin: admin,
    organization: organization
  } do
    {:ok, organization} = verify(organization, admin)
    response = %{user: identity(organization), token: %{}}
    assert {:ok, user} = OrganizationAuthentication.sign_in(organization, response)
    membership = Organizations.get_membership(organization, user)
    assert membership.role == "member"
    assert membership.scopes == MemberPermissions.basic_scopes()
    account = Organizations.get_organization(organization.id).account
    assert Authz.authorize?(:project_read, user, account)
    refute Authz.authorize?(:translation_write, user, account)
    refute Authz.authorize?(:discussion_write, user, account)
    refute Authz.authorize?(:project_write, user, account)

    assert {:ok, _} =
             MemberPermissions.update(
               organization,
               admin,
               user,
               membership.scopes ++ ["translation:write"]
             )

    assert {:ok, same} = OrganizationAuthentication.sign_in(organization, response)
    assert same.id == user.id
    assert Authz.authorize?(:translation_write, user, account)
    assert length(Organizations.list_members(organization)) == 2

    assert %{rows: sign_ins, total: 2} =
             GlossiaEnterprise.Audit.list_events(account, admin, %{
               "q" => "organization.signed_in"
             })

    assert Enum.all?(sign_ins, &(&1.user_id == user.id and &1.account_id == account.id))
  end

  test "disabled and stale providers cannot enroll", %{admin: admin, organization: organization} do
    {:ok, verified} = verify(organization, admin)
    {:ok, disabled} = OrganizationAuthentication.save(verified, admin, %{"auth_provider" => ""})
    assert is_nil(disabled.auth_provider)
    refute OrganizationAuthentication.for_email(identity(verified)["email"])

    assert {:error, :invalid_identity} =
             OrganizationAuthentication.sign_in(verified, %{user: identity(verified), token: %{}})
  end

  test "Okta cannot claim an existing account without its authenticated session", %{
    admin: admin,
    organization: organization
  } do
    {:ok, organization} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "okta",
        "auth_issuer" => "https://team.okta.com",
        "auth_client_id" => "client",
        "auth_client_secret" => "secret"
      })

    {:ok, organization} = verify(organization, admin)
    existing = TestHelpers.create_user("new@#{organization.auth_domain}", "existing")
    response = %{user: identity(organization), token: %{}}

    assert {:error, :identity_not_linked} =
             OrganizationAuthentication.sign_in(organization, response)

    assert {:ok, linked} =
             OrganizationAuthentication.sign_in(organization, response, link_user_id: existing.id)

    assert linked.id == existing.id
    assert {:ok, returning} = OrganizationAuthentication.sign_in(organization, response)
    assert returning.id == existing.id
  end

  test "Google cannot link an existing account by email alone", %{
    admin: admin,
    organization: organization
  } do
    {:ok, organization} = verify(organization, admin)
    existing = TestHelpers.create_user("new@#{organization.auth_domain}", "existing")
    response = %{user: identity(organization), token: %{}}

    assert {:error, :identity_not_linked} =
             OrganizationAuthentication.sign_in(organization, response)

    assert {:ok, linked} =
             OrganizationAuthentication.sign_in(organization, response, link_user_id: existing.id)

    assert linked.id == existing.id
  end

  test "removed members cannot automatically enroll again", %{
    admin: admin,
    organization: organization
  } do
    {:ok, organization} = verify(organization, admin)
    response = %{user: identity(organization), token: %{}}
    {:ok, user} = OrganizationAuthentication.sign_in(organization, response)
    assert {1, _} = Organizations.remove_member(organization, user, actor: admin)

    assert {:error, :membership_revoked} =
             OrganizationAuthentication.sign_in(organization, response)

    {:ok, _} = Organizations.add_member(organization, user)
    assert {:ok, _} = OrganizationAuthentication.sign_in(organization, response)
  end

  test "unverified claims cannot reserve a domain and verification expires", %{
    admin: admin,
    organization: organization
  } do
    {:ok, %{organization: other}} =
      Organizations.create_organization(admin, %{
        handle: "other-#{System.unique_integer([:positive])}"
      })

    {:ok, other} =
      OrganizationAuthentication.save(other, admin, %{
        "auth_provider" => "google",
        "auth_domain" => organization.auth_domain
      })

    {:ok, organization} = verify(organization, admin)
    assert {:error, :domain_already_verified} = verify(other, admin)

    expired =
      organization
      |> Ecto.Changeset.change(
        auth_domain_verified_at: DateTime.add(DateTime.utc_now(), -31, :day)
      )
      |> Repo.update!()

    refute OrganizationAuthentication.for_email("new@#{expired.auth_domain}")
    assert {:ok, _} = verify(other, admin)
  end

  test "empty domains return validation errors and provider changes clear secrets", %{
    admin: admin,
    organization: organization
  } do
    assert {:error, %Ecto.Changeset{}} =
             OrganizationAuthentication.save(organization, admin, %{"auth_domain" => ""})

    {:ok, okta} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "okta",
        "auth_issuer" => "https://team.okta.com",
        "auth_client_id" => "client",
        "auth_client_secret" => "secret"
      })

    {:ok, verified} = verify(okta, admin)

    {:ok, google} =
      OrganizationAuthentication.save(verified, admin, %{"auth_provider" => "google"})

    refute google.auth_domain_verified_at
    refute google.auth_client_secret
    refute google.auth_issuer
    refute google.auth_client_id
  end

  test "scheduled checks renew ownership only while its record remains present", %{
    admin: admin,
    organization: organization
  } do
    {:ok, organization} = verify(organization, admin)
    expired_at = DateTime.add(DateTime.utc_now(), -31, :day)

    expired =
      organization |> Ecto.Changeset.change(auth_domain_verified_at: expired_at) |> Repo.update!()

    assert :ok =
             OrganizationDomainVerificationWorker.renew(expired.id, fn _ -> {:ok, []} end)

    refute OrganizationAuthentication.for_email("new@#{expired.auth_domain}")

    assert :ok =
             TestHelpers.expect_event(
               "organization.domain_verified",
               fn ->
                 OrganizationDomainVerificationWorker.renew(expired.id, fn _ ->
                   {:ok, [OrganizationAuthentication.record_value(expired)]}
                 end)
               end,
               [{:user_id, nil}, {{:opt, :via}, "scheduled"}]
             )

    assert OrganizationAuthentication.for_email("new@#{expired.auth_domain}")
  end

  test "daily renewal queues only verified domains", %{admin: admin, organization: organization} do
    Oban.Testing.with_testing_mode(:manual, fn ->
      assert :ok = OrganizationDomainVerificationWorker.perform(%Oban.Job{args: %{}})

      refute_enqueued(
        worker: OrganizationDomainVerificationWorker,
        args: %{"organization_id" => organization.id}
      )

      {:ok, verified} = verify(organization, admin)
      assert :ok = OrganizationDomainVerificationWorker.perform(%Oban.Job{args: %{}})

      assert_enqueued(
        worker: OrganizationDomainVerificationWorker,
        args: %{"organization_id" => verified.id}
      )
    end)
  end

  defp verify(organization, admin),
    do:
      OrganizationAuthentication.verify(organization, admin, fn name ->
        assert name == OrganizationAuthentication.record_name(organization)
        {:ok, [OrganizationAuthentication.record_value(organization)]}
      end)

  defp identity(organization),
    do: %{
      "sub" => "user-123",
      "email" => "new@#{organization.auth_domain}",
      "email_verified" => true,
      "hd" => organization.auth_domain,
      "name" => "New teammate"
    }
end
