defmodule Glossia.MCP.CompleteProjectLogoUploadToolTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.MCP.CompleteProjectLogoUploadTool
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-logo-complete@test.com", "mcp-logo-complete")

    {:ok, project} =
      Projects.create_project(
        user.account,
        %{handle: "site-#{System.unique_integer([:positive])}", name: "Site"}
      )

    staging_key = "pending-avatars/#{user.account.id}/projects/#{project.id}/abcd1234.png"
    canonical_key = "avatars/#{user.account.handle}/projects/#{project.handle}.png"

    %{
      user: user,
      account: user.account,
      project: project,
      staging_key: staging_key,
      canonical_key: canonical_key
    }
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  defp params(account, project, key, overrides \\ %{}) do
    Map.merge(
      %{
        "handle" => account.handle,
        "project_handle" => project.handle,
        "key" => key
      },
      overrides
    )
  end

  defp valid_headers(content_type \\ "image/png", size \\ "12345") do
    [{"Content-Type", content_type}, {"Content-Length", size}]
  end

  defp stub_delete_ok do
    stub(Glossia.Storage, :delete, fn _key -> {:ok, %{status_code: 204}} end)
  end

  describe "execute/2" do
    test "persists the canonical avatar and returns the project", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key,
      canonical_key: canonical_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key -> {:ok, valid_headers()} end)

      expect(Glossia.Storage, :copy, fn ^staging_key, ^canonical_key ->
        {:ok, %{status_code: 200}}
      end)

      stub_delete_ok()

      assert {:reply, response, _} =
               TestHelpers.expect_event(
                 "project.updated",
                 fn ->
                   CompleteProjectLogoUploadTool.execute(
                     params(account, project, staging_key),
                     frame_for(user)
                   )
                 end,
                 %{
                   {:opt, :resource_type} => "project",
                   :account_id => account.id,
                   :user_id => user.id
                 }
               )

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert result["avatar_url"] == canonical_key

      assert String.ends_with?(
               result["public_url"],
               "/avatars/#{account.handle}/projects/#{project.handle}"
             )

      assert String.starts_with?(result["public_url"], GlossiaWeb.Endpoint.url())

      assert Repo.reload!(project).avatar_url == canonical_key
    end

    test "deletes competing avatar extensions after switching format", %{
      user: user,
      account: account,
      project: project
    } do
      staging_key =
        "pending-avatars/#{account.id}/projects/#{project.id}/token123.webp"

      canonical_key = "avatars/#{account.handle}/projects/#{project.handle}.webp"

      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, valid_headers("image/webp", "1000")}
      end)

      expect(Glossia.Storage, :copy, fn ^staging_key, ^canonical_key ->
        {:ok, %{status_code: 200}}
      end)

      me = self()

      stub(Glossia.Storage, :delete, fn key ->
        send(me, {:deleted, key})
        {:ok, %{}}
      end)

      assert {:reply, _, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )

      assert_receive {:deleted, ^staging_key}

      # Any of the competing canonical extensions must be deleted, and not the kept one.
      kept = "avatars/#{account.handle}/projects/#{project.handle}.webp"
      refute_receive {:deleted, ^kept}, 100

      other = "avatars/#{account.handle}/projects/#{project.handle}.png"
      assert_receive {:deleted, ^other}
    end

    test "rejects a staging key that does not belong to the project", %{
      user: user,
      account: account,
      project: project
    } do
      other_key = "pending-avatars/9999/projects/9999/abc.png"

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, other_key),
                 frame_for(user)
               )
    end

    test "rejects a canonical avatar key (must be a staging key)", %{
      user: user,
      account: account,
      project: project
    } do
      canonical_key = "avatars/#{account.handle}/projects/#{project.handle}.png"

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, canonical_key),
                 frame_for(user)
               )
    end

    test "rejects a path-traversal attempt", %{
      user: user,
      account: account,
      project: project
    } do
      malicious =
        "pending-avatars/#{account.id}/projects/#{project.id}/../../../evil.png"

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, malicious),
                 frame_for(user)
               )
    end

    test "rejects a key from another project in the same account", %{
      user: user,
      account: account,
      project: project
    } do
      {:ok, other_project} =
        Projects.create_project(account, %{
          handle: "sibling-#{System.unique_integer([:positive])}",
          name: "Sibling"
        })

      other_key =
        "pending-avatars/#{account.id}/projects/#{other_project.id}/token.png"

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, other_key),
                 frame_for(user)
               )
    end

    test "returns error when the staging object is missing", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key -> {:error, :not_found} end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "fails closed when Content-Length is missing", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, [{"Content-Type", "image/png"}]}
      end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "rejects a malformed Content-Length", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, [{"Content-Type", "image/png"}, {"Content-Length", "123junk"}]}
      end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "rejects an oversized upload", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, [{"Content-Type", "image/png"}, {"Content-Length", "6000000"}]}
      end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "fails closed when Content-Type is missing", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, [{"Content-Length", "1000"}]}
      end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "rejects a non-image content type from S3", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, [{"Content-Type", "application/pdf"}, {"Content-Length", "1000"}]}
      end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "rejects when stored content type disagrees with the key extension", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      # staging_key ends in .png but stored is image/jpeg
      expect(Glossia.Storage, :head, fn ^staging_key ->
        {:ok, valid_headers("image/jpeg")}
      end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )
    end

    test "returns error when the S3 copy fails", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      expect(Glossia.Storage, :head, fn ^staging_key -> {:ok, valid_headers()} end)
      expect(Glossia.Storage, :copy, fn _, _ -> {:error, :s3_down} end)

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame_for(user)
               )

      assert is_nil(Repo.reload!(project).avatar_url)
    end

    test "returns error when not authenticated", %{
      account: account,
      project: project,
      staging_key: staging_key
    } do
      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 Frame.new(%{})
               )
    end

    test "returns error with insufficient scope", %{
      user: user,
      account: account,
      project: project,
      staging_key: staging_key
    } do
      frame = frame_for(user, ["project:read"])

      assert {:error, _error, _} =
               CompleteProjectLogoUploadTool.execute(
                 params(account, project, staging_key),
                 frame
               )
    end
  end
end
