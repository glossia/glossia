defmodule Glossia.AccountsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.{Organization, OrganizationMembership}
  alias Glossia.TestHelpers

  describe "personal organizations" do
    test "OAuth users are created with a personal organization" do
      {:ok, user} =
        Accounts.find_or_create_user_from_oauth(:github, %{
          user: %{
            "sub" => "github-personal-organization",
            "preferred_username" => "personal-organization-user",
            "email" => "personal-organization@test.com",
            "name" => "Personal Organization User",
            "picture" => nil
          },
          token: %{"access_token" => "github-token"}
        })

      organization = Repo.get_by!(Organization, account_id: user.account_id)

      membership =
        Repo.get_by!(OrganizationMembership, user_id: user.id, organization_id: organization.id)

      assert organization.name == Accounts.personal_organization_name()
      assert membership.role == "admin"
      assert user.has_access
      assert user.account.has_access
    end

    test "ensure_personal_organization!/1 is idempotent" do
      user = TestHelpers.create_user("personal-idempotent@test.com", "personal-idempotent")

      organization = Accounts.ensure_personal_organization!(user)
      same_organization = Accounts.ensure_personal_organization!(user)

      memberships =
        OrganizationMembership
        |> where(user_id: ^user.id, organization_id: ^organization.id)
        |> Repo.all()

      assert same_organization.id == organization.id
      assert length(memberships) == 1
      assert hd(memberships).role == "admin"
    end
  end
end
