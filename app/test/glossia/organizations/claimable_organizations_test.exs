defmodule Glossia.Organizations.ClaimableOrganizationsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Organizations
  alias Glossia.TestHelpers

  test "creates a public organization without a member and lets one user claim it" do
    handle = "claimable-#{System.unique_integer([:positive])}"
    claimant = TestHelpers.create_user("claimant-#{handle}@example.com", "claimant")

    assert {:ok, %{account: account, organization: organization}} =
             Organizations.create_claimable_organization(%{
               handle: handle,
               name: "Claimable organization"
             })

    assert account.visibility == "public"
    assert organization.claimable
    assert Organizations.list_members(organization) == []

    assert {:ok, %{organization: claimed_organization, membership: membership}} =
             Organizations.claim_organization(organization, claimant)

    refute claimed_organization.claimable
    assert membership.user_id == claimant.id
    assert membership.role == "admin"

    assert [%{user_id: user_id, role: "admin"}] = Organizations.list_members(claimed_organization)
    assert user_id == claimant.id
  end

  test "does not let a second user claim an organization" do
    handle = "single-claim-#{System.unique_integer([:positive])}"
    first_claimant = TestHelpers.create_user("first-#{handle}@example.com", "first")
    second_claimant = TestHelpers.create_user("second-#{handle}@example.com", "second")

    {:ok, %{organization: organization}} =
      Organizations.create_claimable_organization(%{handle: handle, name: "Single claim"})

    assert {:ok, _result} = Organizations.claim_organization(organization, first_claimant)

    assert {:error, :not_claimable} =
             Organizations.claim_organization(organization, second_claimant)
  end
end
