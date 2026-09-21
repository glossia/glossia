defmodule Babel.MCP.ErrorsToolsTest do
  use Babel.DataCase, async: true

  alias Babel.Accounts.Account
  alias Babel.Errors
  alias Babel.Errors.Issue
  alias Babel.MCP.GetErrorEventTool
  alias Babel.MCP.GetErrorIssueTool
  alias Babel.MCP.GetOrganizationErrorDsnTool
  alias Babel.MCP.IgnoreErrorIssueTool
  alias Babel.MCP.ListErrorEventsTool
  alias Babel.MCP.ListErrorIssuesTool
  alias Babel.MCP.ResolveErrorIssueTool
  alias Babel.MCP.RotateOrganizationErrorDsnTool
  alias Babel.MCP.UnresolveErrorIssueTool
  alias Babel.Organizations.Organization
  alias Hermes.MCP.Error
  alias Hermes.Server.Frame

  describe "read tools" do
    setup do
      account = insert_account!()
      organization = insert_organization!()
      issue = insert_issue!(organization.id, "fatal-boot")

      frame = Frame.new(current_account: account, scopes: ["operations:read"])

      %{account: account, organization: organization, issue: issue, frame: frame}
    end

    test "ListErrorIssuesTool returns the seeded issue with pagination metadata", %{
      organization: organization,
      issue: issue,
      frame: frame
    } do
      assert {:reply, response, ^frame} =
               ListErrorIssuesTool.execute(%{organization_id: organization.id}, frame)

      assert %{issues: [returned], pagination: %{total_count: 1}} = response.structured_content
      assert returned.id == issue.id
      assert returned.title == issue.title
    end

    test "GetErrorIssueTool fetches by id", %{
      organization: organization,
      issue: issue,
      frame: frame
    } do
      assert {:reply, response, ^frame} =
               GetErrorIssueTool.execute(
                 %{organization_id: organization.id, issue_id: issue.id},
                 frame
               )

      assert response.structured_content.issue.id == issue.id
    end

    test "GetErrorIssueTool returns not-found for a foreign issue", %{
      issue: issue,
      frame: frame
    } do
      other = insert_organization!()

      assert {:error, %Error{} = error, ^frame} =
               GetErrorIssueTool.execute(
                 %{organization_id: other.id, issue_id: issue.id},
                 frame
               )

      assert error.message =~ "not found"
    end

    test "ListErrorEventsTool returns events after ingest", %{
      organization: organization,
      issue: issue,
      frame: frame
    } do
      insert_event!(organization.id, issue.id, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

      assert {:reply, response, ^frame} =
               ListErrorEventsTool.execute(
                 %{organization_id: organization.id, issue_id: issue.id},
                 frame
               )

      assert [event] = response.structured_content.events
      assert String.length(event.event_id) > 0
    end

    test "GetErrorEventTool fetches by canonical or hex id", %{
      organization: organization,
      issue: issue,
      frame: frame
    } do
      insert_event!(organization.id, issue.id, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")

      assert {:reply, response, ^frame} =
               GetErrorEventTool.execute(
                 %{
                   organization_id: organization.id,
                   issue_id: issue.id,
                   event_id: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
                 },
                 frame
               )

      assert response.structured_content.event.event_id ==
               "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
    end

    test "GetOrganizationErrorDsnTool lazily provisions a key", %{
      organization: organization,
      frame: frame
    } do
      assert {:reply, response, ^frame} =
               GetOrganizationErrorDsnTool.execute(%{organization_id: organization.id}, frame)

      assert %{key: key} = response.structured_content
      assert is_binary(key.dsn)
      assert String.contains?(key.dsn, key.public_key)
    end
  end

  describe "write tools" do
    setup do
      account = insert_account!()
      organization = insert_organization!()
      issue = insert_issue!(organization.id, "resolve-me")

      read_frame = Frame.new(current_account: account, scopes: ["operations:read"])

      write_frame =
        Frame.new(current_account: account, scopes: ["operations:read", "operations:write"])

      %{
        account: account,
        organization: organization,
        issue: issue,
        read_frame: read_frame,
        write_frame: write_frame
      }
    end

    test "ResolveErrorIssueTool flips status to :resolved", %{
      organization: organization,
      issue: issue,
      write_frame: frame
    } do
      assert {:reply, response, ^frame} =
               ResolveErrorIssueTool.execute(
                 %{organization_id: organization.id, issue_id: issue.id},
                 frame
               )

      assert response.structured_content.issue.status == "resolved"
      assert {:ok, %Issue{status: :resolved}} = Errors.get_issue(organization.id, issue.id)
    end

    test "UnresolveErrorIssueTool reopens a resolved issue", %{
      organization: organization,
      issue: issue,
      write_frame: frame
    } do
      {:ok, _} = Errors.resolve_issue(issue)

      assert {:reply, response, ^frame} =
               UnresolveErrorIssueTool.execute(
                 %{organization_id: organization.id, issue_id: issue.id},
                 frame
               )

      assert response.structured_content.issue.status == "unresolved"
    end

    test "IgnoreErrorIssueTool marks it :ignored", %{
      organization: organization,
      issue: issue,
      write_frame: frame
    } do
      assert {:reply, response, ^frame} =
               IgnoreErrorIssueTool.execute(
                 %{organization_id: organization.id, issue_id: issue.id},
                 frame
               )

      assert response.structured_content.issue.status == "ignored"
    end

    test "ResolveErrorIssueTool requires the write scope", %{
      organization: organization,
      issue: issue,
      read_frame: frame
    } do
      assert {:error, %Error{} = error, ^frame} =
               ResolveErrorIssueTool.execute(
                 %{organization_id: organization.id, issue_id: issue.id},
                 frame
               )

      assert error.message =~ "Insufficient scope"
    end

    test "RotateOrganizationErrorDsnTool mints a fresh key", %{
      organization: organization,
      write_frame: frame
    } do
      {:ok, original} = Errors.create_key(organization.id, %{"name" => "initial"})

      assert {:reply, response, ^frame} =
               RotateOrganizationErrorDsnTool.execute(
                 %{organization_id: organization.id},
                 frame
               )

      rotated = response.structured_content.key
      refute rotated.public_key == original.public_key
    end
  end

  defp insert_account! do
    suffix = System.unique_integer([:positive])

    %Account{}
    |> Account.registration_changeset(%{
      email: "operator-#{suffix}@glossia.ai",
      name: "Operations operator",
      pomerium_id: "google/operator-#{suffix}",
      last_seen_at: DateTime.utc_now(:second)
    })
    |> Repo.insert!()
  end

  defp insert_organization! do
    suffix = System.unique_integer([:positive])

    %Organization{}
    |> Organization.changeset(%{
      name: "Acme Corp #{suffix}",
      website_url: "https://acme-#{suffix}.example",
      state: "researching"
    })
    |> Repo.insert!()
  end

  defp insert_issue!(organization_id, fingerprint_seed) do
    fingerprint = fingerprint(fingerprint_seed)
    now = DateTime.utc_now()

    %Issue{}
    |> Issue.changeset(%{
      organization_id: organization_id,
      fingerprint: fingerprint,
      title: "RuntimeError: something exploded (#{fingerprint_seed})",
      culprit: "MyApp.something/1",
      first_seen: now,
      last_seen: now,
      event_count: 1
    })
    |> Repo.insert!()
  end

  defp insert_event!(organization_id, issue_id, hex_id) do
    canonical = to_canonical_uuid(hex_id)
    now = DateTime.utc_now()
    seconds = DateTime.truncate(now, :second)

    Repo.insert_all("errors_events", [
      %{
        event_id: Ecto.UUID.dump!(canonical),
        organization_id: organization_id,
        issue_id: Ecto.UUID.dump!(issue_id),
        fingerprint: fingerprint(hex_id),
        timestamp: now,
        received_at: now,
        level: "error",
        platform: "elixir",
        inserted_at: seconds
      }
    ])
  end

  defp fingerprint(seed) do
    :crypto.hash(:sha256, seed) |> Base.encode16(case: :lower)
  end

  defp to_canonical_uuid(
         <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
           e::binary-size(12)>>
       ) do
    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end
end
