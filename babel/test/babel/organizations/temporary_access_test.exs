defmodule Babel.Organizations.TemporaryAccessTest do
  use ExUnit.Case, async: true

  alias Babel.Organizations
  alias Babel.Organizations.Organization

  test "sends a valid grant request with the verified Babel requester" do
    organization = %Organization{glossia_organization_id: Ecto.UUID.generate()}
    requester = %{email: "operator@glossia.ai", pomerium_id: "google/operator"}

    client = fn organization_id, attributes, [] ->
      assert organization_id == organization.glossia_organization_id

      assert attributes == %{
               "email" => "support@glossia.ai",
               "duration_minutes" => 30,
               "reason" => "Investigate the translation configuration reported by support.",
               "requested_by_email" => "operator@glossia.ai",
               "requested_by_pomerium_id" => "google/operator"
             }

      {:ok, %{"temporary_access_grant_id" => Ecto.UUID.generate()}}
    end

    assert {:ok, %{"temporary_access_grant_id" => _grant_id}} =
             Organizations.grant_temporary_access(
               organization,
               requester,
               %{
                 "email" => "support@glossia.ai",
                 "duration_minutes" => 30,
                 "reason" => "Investigate the translation configuration reported by support."
               },
               client: client
             )
  end

  test "requires a Pomerium-authenticated Glossia employee to grant access" do
    organization = %Organization{glossia_organization_id: Ecto.UUID.generate()}

    assert {:error, :unauthorized} =
             Organizations.grant_temporary_access(
               organization,
               %{email: "operator@example.com", pomerium_id: "google/operator"},
               %{
                 "email" => "support@glossia.ai",
                 "duration_minutes" => 30,
                 "reason" => "Investigate the translation configuration reported by support."
               }
             )
  end

  test "requires a target within the Glossia email domain and a bounded duration" do
    organization = %Organization{glossia_organization_id: Ecto.UUID.generate()}
    requester = %{email: "operator@glossia.ai", pomerium_id: "google/operator"}

    assert {:error, changeset} =
             Organizations.grant_temporary_access(
               organization,
               requester,
               %{
                 "email" => "support@example.com",
                 "duration_minutes" => 120,
                 "reason" => "Investigate the translation configuration reported by support."
               }
             )

    assert {"must be a @glossia.ai email address", []} = changeset.errors[:email]

    assert {"is invalid", [validation: :inclusion, enum: [15, 30, 60, 240]]} =
             changeset.errors[:duration_minutes]
  end
end
