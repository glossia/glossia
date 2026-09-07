defmodule Glossia.TemporaryAccessTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Authz
  alias Glossia.Repo
  alias Glossia.TemporaryAccess
  alias Glossia.TemporaryAccess.Grant
  alias Glossia.TestHelpers

  setup do
    owner =
      TestHelpers.create_user("owner-#{System.unique_integer([:positive])}@example.com", "owner")

    recipient =
      TestHelpers.create_user(
        "support-#{System.unique_integer([:positive])}@glossia.ai",
        "support"
      )

    organization = Accounts.ensure_personal_organization!(owner)

    {:ok, owner: owner, recipient: recipient, organization: organization}
  end

  test "records a bounded audited grant and activates it for the verified Pomerium identity", %{
    owner: owner,
    recipient: recipient,
    organization: organization
  } do
    assert {:ok, grant} =
             TemporaryAccess.grant(organization, recipient, %{
               "duration_minutes" => 30,
               "requested_by_email" => "operator@glossia.ai",
               "requested_by_pomerium_id" => "google/operator",
               "reason" => "Investigate the translation configuration reported by support."
             })

    assert grant.recipient_email == recipient.email
    assert grant.requested_by_email == "operator@glossia.ai"
    assert DateTime.diff(grant.expires_at, DateTime.utc_now(), :minute) in 29..30

    assert {:ok, bound_grant} =
             TemporaryAccess.authorize_pomerium_access(recipient, owner.account, %{
               email: recipient.email,
               subject: "google/support"
             })

    temporary_user =
      TemporaryAccess.attach_pomerium_access(recipient, %{
        "user_id" => recipient.id,
        "grant_id" => bound_grant.id
      })

    assert TemporaryAccess.active?(temporary_user, owner.account)
    assert Authz.authorize?(:project_read, temporary_user, owner.account)
    refute Authz.authorize?(:project_write, temporary_user, owner.account)
    refute Authz.authorize?(:members_read, temporary_user, owner.account)
    refute Authz.authorize?(:api_credentials_read, temporary_user, owner.account)
  end

  test "will not bind an existing grant to a different Pomerium subject", %{
    owner: owner,
    recipient: recipient,
    organization: organization
  } do
    assert {:ok, _grant} = grant(organization, recipient)

    assert {:ok, _grant} =
             TemporaryAccess.authorize_pomerium_access(recipient, owner.account, %{
               email: recipient.email,
               subject: "google/first-subject"
             })

    assert {:error, :grant_not_found} =
             TemporaryAccess.authorize_pomerium_access(recipient, owner.account, %{
               email: recipient.email,
               subject: "google/second-subject"
             })
  end

  test "expires access without relying on a background job", %{
    owner: owner,
    recipient: recipient,
    organization: organization
  } do
    assert {:ok, grant} = grant(organization, recipient)

    assert {:ok, bound_grant} =
             TemporaryAccess.authorize_pomerium_access(recipient, owner.account, %{
               email: recipient.email,
               subject: "google/support"
             })

    temporary_user =
      TemporaryAccess.attach_pomerium_access(recipient, %{
        "user_id" => recipient.id,
        "grant_id" => bound_grant.id
      })

    {1, _} =
      Grant
      |> where(id: ^grant.id)
      |> Repo.update_all(set: [expires_at: DateTime.add(DateTime.utc_now(), -1, :second)])

    refute TemporaryAccess.active?(temporary_user, owner.account)
    refute Authz.authorize?(:project_read, temporary_user, owner.account)
  end

  test "rejects a target outside the Glossia email domain", %{
    recipient: recipient,
    organization: organization
  } do
    assert {:error, changeset} =
             TemporaryAccess.grant(organization, recipient, %{
               "duration_minutes" => 30,
               "requested_by_email" => "operator@example.com",
               "requested_by_pomerium_id" => "google/operator",
               "reason" => "Investigate the translation configuration reported by support."
             })

    assert {"must be a @glossia.ai email address", []} = changeset.errors[:requested_by_email]
  end

  defp grant(organization, recipient) do
    TemporaryAccess.grant(organization, recipient, %{
      "duration_minutes" => 30,
      "requested_by_email" => "operator@glossia.ai",
      "requested_by_pomerium_id" => "google/operator",
      "reason" => "Investigate the translation configuration reported by support."
    })
  end
end
