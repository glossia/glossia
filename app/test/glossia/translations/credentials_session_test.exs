defmodule Glossia.Translations.CredentialsSessionTest do
  @moduledoc """
  Tests the local-session credential shaping without touching the real keychain
  or `~/.codex/auth.json`: `claude_credential/1` takes a decoded OAuth map and
  `codex_session/1` takes an explicit auth-file path.
  """
  use ExUnit.Case, async: true

  alias Glossia.Translations.Credentials

  describe "claude_credential/1" do
    test "builds an OAuth credential from a valid, unexpired token" do
      future = System.system_time(:millisecond) + 60_000

      assert %{
               model: "anthropic:claude-haiku-4-5",
               auth: {:oauth, "tok-abc"},
               source: :claude_session
             } =
               Credentials.claude_credential(%{"accessToken" => "tok-abc", "expiresAt" => future})
    end

    test "treats a missing expiry as valid" do
      assert %{auth: {:oauth, "tok"}} = Credentials.claude_credential(%{"accessToken" => "tok"})
    end

    test "returns nil for an expired token" do
      past = System.system_time(:millisecond) - 1
      assert Credentials.claude_credential(%{"accessToken" => "tok", "expiresAt" => past}) == nil
    end

    test "returns nil for a missing or blank token" do
      assert Credentials.claude_credential(%{"expiresAt" => 1}) == nil
      assert Credentials.claude_credential(%{"accessToken" => "  "}) == nil
      assert Credentials.claude_credential(nil) == nil
    end
  end

  describe "codex_session/1" do
    @tag :tmp_dir
    test "builds an OAuth credential from a valid auth.json", %{tmp_dir: dir} do
      path = Path.join(dir, "auth.json")
      File.write!(path, Jason.encode!(%{"tokens" => %{"access_token" => "codex-tok"}}))

      assert %{model: "openai:gpt-5", auth: {:oauth, "codex-tok"}, source: :codex_session} =
               Credentials.codex_session(path)
    end

    test "returns nil when the file is missing" do
      assert Credentials.codex_session("/no/such/auth.json") == nil
    end

    @tag :tmp_dir
    test "returns nil for malformed or tokenless auth.json", %{tmp_dir: dir} do
      malformed = Path.join(dir, "bad.json")
      File.write!(malformed, "not json")
      assert Credentials.codex_session(malformed) == nil

      tokenless = Path.join(dir, "tokenless.json")
      File.write!(tokenless, Jason.encode!(%{"tokens" => %{}}))
      assert Credentials.codex_session(tokenless) == nil
    end
  end

  describe "claude_cli_session/2" do
    test "preserves the refreshable Claude session for the isolated command" do
      future = System.system_time(:millisecond) + 60_000

      oauth = %{
        "accessToken" => "access",
        "refreshToken" => "refresh",
        "expiresAt" => future
      }

      assert {:ok, credential} =
               Credentials.claude_cli_session(oauth, "anthropic:claude-sonnet-4-6")

      assert credential.harness == "claude"
      assert credential.command == "claude"
      assert credential.model == "claude-sonnet-4-6"
      assert credential.claude_auth == %{"claudeAiOauth" => oauth}
    end

    test "rejects an expired Claude session" do
      oauth = %{"accessToken" => "access", "expiresAt" => 0}

      assert {:error, :claude_session_not_available} =
               Credentials.claude_cli_session(oauth, "anthropic:claude-sonnet-4-6")
    end
  end

  describe "codex_opencode_session/2" do
    @tag :tmp_dir
    test "converts the Codex session into OpenCode authentication", %{tmp_dir: dir} do
      path = Path.join(dir, "auth.json")

      expires = System.system_time(:second) + 3_600

      payload =
        %{"exp" => expires}
        |> JSON.encode!()
        |> Base.url_encode64(padding: false)

      access = "header.#{payload}.signature"

      File.write!(
        path,
        JSON.encode!(%{
          "tokens" => %{
            "access_token" => access,
            "refresh_token" => "refresh-token",
            "account_id" => "account-id"
          }
        })
      )

      assert {:ok, credential} =
               Credentials.codex_opencode_session(path, "openai:gpt-5.4")

      assert credential.model == "openai/gpt-5.4"
      assert credential.opencode_config == %{"model" => "openai/gpt-5.4"}

      assert credential.opencode_auth == %{
               "openai" => %{
                 "type" => "oauth",
                 "access" => access,
                 "accountId" => "account-id",
                 "expires" => expires * 1_000
               }
             }
    end
  end
end
