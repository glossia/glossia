defmodule Babel.AccountsTest do
  use Babel.DataCase, async: true

  alias Babel.Accounts
  alias Babel.Repo

  test "creates an account for a Google Workspace identity on first access" do
    identity = identity()

    assert {:ok, account} = Accounts.provision_pomerium_account(identity, "glossia.ai")
    assert account.email == identity.email
    assert account.name == identity.name
    assert account.pomerium_id == identity.pomerium_id
    assert account.last_seen_at
    assert Repo.get_by!(Babel.Accounts.Account, email: identity.email).id == account.id
  end

  test "reuses the account on later requests" do
    identity = identity()
    assert {:ok, first_account} = Accounts.provision_pomerium_account(identity, "glossia.ai")

    assert {:ok, second_account} =
             Accounts.provision_pomerium_account(%{identity | name: "Updated name"}, "glossia.ai")

    assert second_account.id == first_account.id
    assert second_account.name == "Updated name"
  end

  test "rejects an identity outside the configured Workspace domain" do
    assert {:error, :invalid_identity} =
             Accounts.provision_pomerium_account(
               %{identity() | email: "person@example.com"},
               "glossia.ai"
             )
  end

  test "does not associate an existing email with another Pomerium identity" do
    identity = identity()
    assert {:ok, _account} = Accounts.provision_pomerium_account(identity, "glossia.ai")

    assert {:error, :identity_conflict} =
             Accounts.provision_pomerium_account(
               %{identity | pomerium_id: "google/another-user"},
               "glossia.ai"
             )
  end

  defp identity do
    suffix = System.unique_integer([:positive])

    %{
      email: "operator-#{suffix}@glossia.ai",
      name: "Glossia operator",
      pomerium_id: "google/operator-#{suffix}"
    }
  end
end
