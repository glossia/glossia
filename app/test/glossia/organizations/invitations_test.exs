defmodule Glossia.Organizations.InvitationsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Organizations
  alias Glossia.Accounts.{Account, OrganizationInvitation, User}

  setup do
    Mimic.stub(Glossia.Mailer, :deliver, fn _email -> {:ok, %{}} end)

    {:ok, %{account: account}} =
      Organizations.create_organization(create_user("admin@test.com", "orgadmin"), %{
        handle: "testorg-#{System.unique_integer([:positive])}",
        name: "Test Org"
      })

    org = Organizations.get_organization_for_account(account)

    %{org: org, account: account}
  end

  describe "create_invitation/3" do
    test "creates an invitation and sends email", %{org: org} do
      inviter = create_user("inviter@test.com", "inviter")
      Organizations.add_member(org, inviter, "admin")

      assert {:ok, invitation} =
               Organizations.create_invitation(org, inviter, %{
                 "email" => "newuser@test.com",
                 "role" => "member"
               })

      assert invitation.email == "newuser@test.com"
      assert invitation.role == "member"
      assert invitation.status == "pending"
      assert invitation.token != nil
      assert invitation.organization_id == org.id
      assert invitation.invited_by_id == inviter.id
      assert DateTime.compare(invitation.expires_at, DateTime.utc_now()) == :gt
    end

    test "returns error when user is already a member", %{org: org} do
      member = create_user("member@test.com", "member")
      Organizations.add_member(org, member, "member")

      inviter = create_user("inviter2@test.com", "inviter2")
      Organizations.add_member(org, inviter, "admin")

      assert {:error, :already_member} =
               Organizations.create_invitation(org, inviter, %{
                 "email" => "member@test.com",
                 "role" => "member"
               })
    end

    test "returns error when pending invitation already exists", %{org: org} do
      inviter = create_user("inviter3@test.com", "inviter3")
      Organizations.add_member(org, inviter, "admin")

      assert {:ok, _} =
               Organizations.create_invitation(org, inviter, %{
                 "email" => "dup@test.com",
                 "role" => "member"
               })

      assert {:error, :already_invited} =
               Organizations.create_invitation(org, inviter, %{
                 "email" => "dup@test.com",
                 "role" => "member"
               })
    end

    test "defaults invitations to member role in OSS", %{org: org} do
      inviter = create_user("inviter4@test.com", "inviter4")
      Organizations.add_member(org, inviter, "admin")

      assert {:ok, invitation} =
               Organizations.create_invitation(org, inviter, %{
                 "email" => "linguist@test.com",
                 "role" => "linguist"
               })

      assert invitation.role == "member"
    end
  end

  describe "get_invitation_by_token/1" do
    test "returns invitation with preloaded org", %{org: org} do
      inviter = create_user("inviter5@test.com", "inviter5")
      Organizations.add_member(org, inviter, "admin")

      {:ok, invitation} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "token@test.com",
          "role" => "member"
        })

      found = Organizations.get_invitation_by_token(invitation.token)
      assert found.id == invitation.id
      assert found.organization.id == org.id
      assert found.organization.account != nil
    end

    test "returns nil for non-existent token" do
      assert Organizations.get_invitation_by_token("nonexistent") == nil
    end
  end

  describe "accept_invitation/2" do
    test "creates membership and marks invitation accepted", %{org: org} do
      inviter = create_user("inviter6@test.com", "inviter6")
      Organizations.add_member(org, inviter, "admin")

      {:ok, invitation} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "accept@test.com",
          "role" => "linguist"
        })

      acceptor = create_user("accept@test.com", "acceptor")

      assert {:ok, %{invitation: updated, membership: membership}} =
               Organizations.accept_invitation(invitation, acceptor)

      assert updated.status == "accepted"
      assert membership.user_id == acceptor.id
      assert membership.organization_id == org.id
      assert membership.role == "member"
    end

    test "returns error for expired invitation", %{org: org} do
      inviter = create_user("inviter7@test.com", "inviter7")
      Organizations.add_member(org, inviter, "admin")

      token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
      expired_at = DateTime.add(DateTime.utc_now(), -1, :day)

      {:ok, invitation} =
        %OrganizationInvitation{organization_id: org.id, invited_by_id: inviter.id, token: token}
        |> OrganizationInvitation.changeset(%{
          email: "expired@test.com",
          role: "member",
          expires_at: expired_at
        })
        |> Repo.insert()

      acceptor = create_user("expired@test.com", "expireduser")
      assert {:error, :expired} = Organizations.accept_invitation(invitation, acceptor)
    end

    test "returns error when already accepted", %{org: org} do
      inviter = create_user("inviter8@test.com", "inviter8")
      Organizations.add_member(org, inviter, "admin")

      {:ok, invitation} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "double@test.com",
          "role" => "member"
        })

      acceptor = create_user("double@test.com", "doubleuser")

      assert {:ok, %{invitation: accepted}} =
               Organizations.accept_invitation(invitation, acceptor)

      assert {:error, :already_accepted} = Organizations.accept_invitation(accepted, acceptor)
    end

    test "returns error when user is already a member", %{org: org} do
      inviter = create_user("inviter9@test.com", "inviter9")
      Organizations.add_member(org, inviter, "admin")

      existing = create_user("existing@test.com", "existing")
      Organizations.add_member(org, existing, "member")

      {:ok, invitation} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "other@test.com",
          "role" => "member"
        })

      assert {:error, :already_member} = Organizations.accept_invitation(invitation, existing)
    end
  end

  describe "decline_invitation/1" do
    test "marks invitation as declined", %{org: org} do
      inviter = create_user("inviter10@test.com", "inviter10")
      Organizations.add_member(org, inviter, "admin")

      {:ok, invitation} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "decline@test.com",
          "role" => "member"
        })

      assert {:ok, updated} = Organizations.decline_invitation(invitation)
      assert updated.status == "declined"
    end
  end

  describe "revoke_invitation/1" do
    test "marks invitation as revoked", %{org: org} do
      inviter = create_user("inviter11@test.com", "inviter11")
      Organizations.add_member(org, inviter, "admin")

      {:ok, invitation} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "revoke@test.com",
          "role" => "member"
        })

      assert {:ok, updated} = Organizations.revoke_invitation(invitation)
      assert updated.status == "revoked"
    end
  end

  describe "list_members/1" do
    test "returns members with preloaded user and account", %{org: org} do
      member = create_user("listmem@test.com", "listmem")
      Organizations.add_member(org, member, "member")

      members = Organizations.list_members(org)
      assert length(members) >= 2
      assert Enum.all?(members, fn m -> m.user != nil && m.user.account != nil end)
    end
  end

  describe "list_pending_invitations/1" do
    test "returns only pending non-expired invitations", %{org: org} do
      inviter = create_user("inviter12@test.com", "inviter12")
      Organizations.add_member(org, inviter, "admin")

      {:ok, _} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "pending1@test.com",
          "role" => "member"
        })

      {:ok, declined} =
        Organizations.create_invitation(org, inviter, %{
          "email" => "pending2@test.com",
          "role" => "member"
        })

      Organizations.decline_invitation(declined)

      pending = Organizations.list_pending_invitations(org)
      assert length(pending) == 1
      assert hd(pending).email == "pending1@test.com"
    end
  end

  defp create_user(email, handle) do
    {:ok, account} =
      %Account{}
      |> Account.changeset(%{
        handle: "#{handle}-#{System.unique_integer([:positive])}",
        type: "user"
      })
      |> Repo.insert()

    {:ok, user} =
      %User{account_id: account.id}
      |> User.changeset(%{email: email})
      |> Repo.insert()

    %{user | account: account}
  end
end
