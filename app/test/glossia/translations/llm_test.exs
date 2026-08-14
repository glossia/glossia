defmodule Glossia.Translations.LLMTest do
  @moduledoc """
  Tests the LLM dispatch: api-key credentials route through Condukt, OAuth
  credentials through ReqLLM. The provider calls are stubbed, so these are
  deterministic and async.
  """
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Translations.Agent
  alias Glossia.Translations.LLM

  @system "You are a professional localization engine."
  @user "Translate 'Hello' to Spanish."

  describe "run/3 with an api-key credential (Condukt)" do
    test "passes model, system prompt, api key, and base url and returns the text" do
      Mimic.expect(Condukt, :run, fn prompt, opts ->
        assert prompt == @user
        assert opts[:model] == "anthropic:claude"
        assert opts[:system_prompt] == @system
        assert opts[:api_key] == "sk-test"
        assert opts[:base_url] == "https://proxy.test/v1"
        assert opts[:thinking_level] == :off
        {:ok, "Hola"}
      end)

      cred = %{
        model: "anthropic/claude",
        auth: {:api_key, "sk-test", "https://proxy.test/v1"},
        source: :account_model
      }

      assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
    end

    test "omits base_url when nil and surfaces Condukt errors" do
      Mimic.expect(Condukt, :run, fn _prompt, opts ->
        refute Keyword.has_key?(opts, :base_url)
        {:error, :boom}
      end)

      cred = %{
        model: "anthropic/claude",
        auth: {:api_key, "sk-test", nil},
        source: :account_model
      }

      assert {:error, :boom} = LLM.run(cred, @system, @user)
    end

    test "routes Together text models through its compatible endpoint" do
      provider_models = [
        "Qwen/Qwen3.5-9B",
        "moonshotai/Kimi-K2.7-Code",
        "openai/gpt-oss-120b"
      ]

      Mimic.expect(Condukt, :run, length(provider_models), fn _prompt, opts ->
        assert opts[:model] in Enum.map(provider_models, &%{provider: :openai, id: &1})

        assert opts[:base_url] == "https://api.together.ai/v1"
        assert Keyword.has_key?(opts, :thinking_level)
        assert opts[:thinking_level] == nil
        {:ok, "Hola"}
      end)

      Enum.each(provider_models, fn provider_model ->
        cred = %{
          model: "togetherai/#{provider_model}",
          auth: {:api_key, "together-key", nil},
          source: :account_model
        }

        assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
      end)
    end
  end

  describe "run/3 with an OAuth credential (ReqLLM)" do
    test "sends auth_mode/access_token and system+user messages" do
      Mimic.expect(ReqLLM, :generate_text, fn model, messages, opts ->
        assert model == "anthropic:claude-haiku-4-5"
        assert opts[:auth_mode] == :oauth
        assert opts[:access_token] == "oauth-tok"
        assert [%{role: "system", content: @system}, %{role: "user", content: @user}] = messages
        {:ok, :fake_response}
      end)

      Mimic.stub(ReqLLM.Response, :text, fn :fake_response -> "Hola, mundo." end)

      cred = %{
        model: "anthropic/claude-haiku-4-5",
        auth: {:oauth, "oauth-tok"},
        source: :claude_session
      }

      assert {:ok, "Hola, mundo."} = LLM.run(cred, @system, @user)
    end
  end

  describe "run/3 with a Pi session" do
    test "runs the configured provider model without tools or session state" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", args, opts ->
        assert ["-c", ~s(exec "$@" </dev/null), "sh", "pi", "-p", "--no-tools" | _] =
                 args

        assert Enum.at(args, Enum.find_index(args, &(&1 == "--provider")) + 1) == "openrouter"

        assert Enum.at(args, Enum.find_index(args, &(&1 == "--model")) + 1) ==
                 "anthropic/claude-sonnet-4.6"

        assert List.last(args) == @user
        assert opts[:timeout] == 1_800_000
        {"Hola\n", 0}
      end)

      cred = %{
        model: "openrouter/anthropic/claude-sonnet-4.6",
        auth: :pi_session,
        source: :pi_session
      }

      assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
    end
  end

  describe "run/3 with a Codex session" do
    test "returns the agent message from the event stream" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s({"type":"thread.started","thread_id":"t"}\n) <>
           ~s({"type":"item.completed","item":{"type":"agent_message","text":"Hola"}}\n), 0}
      end)

      assert {:ok, "Hola"} = LLM.run(%{source: :codex_session}, @system, @user)
    end

    # The CLI reports usage limits and provider outages as an event while still
    # exiting 0, and its raw output is mostly unrelated tool chatter.
    test "surfaces the reported error instead of an empty response" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s({"type":"thread.started","thread_id":"t"}\n) <>
           ~s({"type":"error","message":"You've hit your usage limit."}\n) <>
           ~s({"type":"turn.failed","error":{"message":"You've hit your usage limit."}}\n), 0}
      end)

      assert {:error, {:codex_cli_failed, 0, "You've hit your usage limit."}} =
               LLM.run(%{source: :codex_session}, @system, @user)
    end

    test "prefers the reported error over raw output when the CLI exits non-zero" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s(2026-08-12 ERROR unrelated tool chatter\n) <>
           ~s({"type":"thread.started","thread_id":"t"}\n) <>
           ~s({"type":"turn.failed","error":{"message":"Provider is unavailable."}}\n), 1}
      end)

      assert {:error, {:codex_cli_failed, 1, "Provider is unavailable."}} =
               LLM.run(%{source: :codex_session}, @system, @user)
    end

    test "falls back to an empty-response error when nothing is reported" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s({"type":"thread.started","thread_id":"t"}\n), 0}
      end)

      assert {:error, :empty_codex_response} = LLM.run(%{source: :codex_session}, @system, @user)
    end
  end

  describe "stream/4" do
    test "OAuth wraps the result in synthetic turn events" do
      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts -> {:ok, :resp} end)
      Mimic.stub(ReqLLM.Response, :text, fn :resp -> "Hola" end)

      {:ok, collector} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn e -> Elixir.Agent.update(collector, &[e | &1]) end

      cred = %{model: "anthropic/x", auth: {:oauth, "tok"}, source: :claude_session}
      assert {:ok, "Hola"} = LLM.stream(cred, @system, @user, on_event)

      assert Elixir.Agent.get(collector, &Enum.reverse/1) ==
               [:turn_start, {:text, "Hola"}, :turn_end, :done]
    end

    test "api-key streams Condukt turn events and accumulates text" do
      Mimic.stub(Agent, :start_link, fn _opts -> Elixir.Agent.start_link(fn -> nil end) end)

      Mimic.stub(Condukt, :stream, fn _pid, prompt ->
        assert prompt == @user
        [:turn_start, {:text, "Hola"}, {:text, ", mundo"}, :turn_end]
      end)

      {:ok, collector} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn e -> Elixir.Agent.update(collector, &[e | &1]) end

      cred = %{model: "anthropic/x", auth: {:api_key, "sk", nil}, source: :account_model}
      assert {:ok, "Hola, mundo"} = LLM.stream(cred, @system, @user, on_event)

      events = Elixir.Agent.get(collector, &Enum.reverse/1)
      assert :turn_start in events
      assert {:text, "Hola"} in events
    end

    test "a streamed error fails the call" do
      Mimic.stub(Agent, :start_link, fn _opts -> Elixir.Agent.start_link(fn -> nil end) end)
      Mimic.stub(Condukt, :stream, fn _pid, _prompt -> [:turn_start, {:error, :rate_limited}] end)

      cred = %{model: "anthropic/x", auth: {:api_key, "sk", nil}, source: :account_model}
      assert {:error, :rate_limited} = LLM.stream(cred, @system, @user, fn _ -> :ok end)
    end
  end
end
