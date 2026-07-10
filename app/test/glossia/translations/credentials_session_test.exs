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
end
