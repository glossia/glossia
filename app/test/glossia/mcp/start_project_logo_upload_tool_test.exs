defmodule Glossia.MCP.StartProjectLogoUploadToolTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.MCP.StartProjectLogoUploadTool
  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-logo-start@test.com", "mcp-logo-start")

    {:ok, project} =
      Projects.create_project(
        user.account,
        %{handle: "site-#{System.unique_integer([:positive])}", name: "Site"}
      )

    %{user: user, account: user.account, project: project}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  defp params(account, project, overrides \\ %{}) do
    Map.merge(
      %{
        "handle" => account.handle,
        "project_handle" => project.handle,
        "content_type" => "image/png"
      },
      overrides
    )
  end

  describe "execute/2" do
    test "returns a presigned PUT URL for a staging key outside the public avatars prefix", %{
      user: user,
      account: account,
      project: project
    } do
      expected_prefix = "pending-avatars/#{account.id}/projects/#{project.id}/"

      expect(Glossia.Storage, :presigned_url, fn key, opts ->
        assert String.starts_with?(key, expected_prefix)
        assert String.ends_with?(key, ".png")
        refute String.starts_with?(key, "avatars/")
        assert opts[:method] == :put
        assert opts[:expires_in] == 300
        {:ok, "https://s3.example/#{key}?sig=abc"}
      end)

      assert {:reply, response, _} =
               StartProjectLogoUploadTool.execute(params(account, project), frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert String.starts_with?(result["key"], expected_prefix)
      assert String.ends_with?(result["key"], ".png")
      assert result["method"] == "PUT"
      assert result["content_type"] == "image/png"
      assert result["max_size_bytes"] == 5_000_000
      assert result["expires_in"] == 300
      assert String.starts_with?(result["upload_url"], "https://s3.example/")
    end

    test "generates a fresh staging key on each call", %{
      user: user,
      account: account,
      project: project
    } do
      stub(Glossia.Storage, :presigned_url, fn key, _opts -> {:ok, "https://s3.example/#{key}"} end)

      assert {:reply, r1, _} =
               StartProjectLogoUploadTool.execute(params(account, project), frame_for(user))

      assert {:reply, r2, _} =
               StartProjectLogoUploadTool.execute(params(account, project), frame_for(user))

      [c1] = r1.content
      [c2] = r2.content
      refute JSON.decode!(c1["text"])["key"] == JSON.decode!(c2["text"])["key"]
    end

    test "rejects an unsupported content type", %{
      user: user,
      account: account,
      project: project
    } do
      params = params(account, project, %{"content_type" => "application/pdf"})
      assert {:error, _error, _} = StartProjectLogoUploadTool.execute(params, frame_for(user))
    end

    test "returns error for nonexistent project", %{user: user, account: account, project: p} do
      params = params(account, p, %{"project_handle" => "does-not-exist"})
      assert {:error, _error, _} = StartProjectLogoUploadTool.execute(params, frame_for(user))
    end

    test "returns error for a project in another account", %{user: user} do
      other = TestHelpers.create_user("mcp-logo-other@test.com", "mcp-logo-other")

      {:ok, other_project} =
        Projects.create_project(
          other.account,
          %{handle: "other-#{System.unique_integer([:positive])}", name: "Other"}
        )

      params = %{
        "handle" => other.account.handle,
        "project_handle" => other_project.handle,
        "content_type" => "image/png"
      }

      assert {:error, _error, _} = StartProjectLogoUploadTool.execute(params, frame_for(user))
    end

    test "returns error when not authenticated", %{account: account, project: project} do
      assert {:error, _error, _} =
               StartProjectLogoUploadTool.execute(params(account, project), Frame.new(%{}))
    end

    test "returns error with insufficient scope", %{
      user: user,
      account: account,
      project: project
    } do
      frame = frame_for(user, ["project:read"])
      assert {:error, _error, _} = StartProjectLogoUploadTool.execute(params(account, project), frame)
    end
  end
end
