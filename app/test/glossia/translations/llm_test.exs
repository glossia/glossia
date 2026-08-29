defmodule Glossia.Translations.LLMTest do
  @moduledoc """
  Tests the LLM dispatch: api-key and OAuth credentials both route through
  ReqLLM, command-line sessions through their executable. The provider calls are
  stubbed, so these are deterministic and async.
  """
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Translations.LLM

  @system "You are a professional localization engine."
  @user "Translate 'Hello' to Spanish."

  # A model the catalog knows states its own output ceiling; one it does not
  # know has no limits at all, which is what makes an explicit budget necessary.
  defp catalogued(spec), do: %{spec: spec, limits: %{output: 8_192}}

  # What ReqLLM actually returns for a model its catalog does not know.
  defp uncatalogued(spec), do: %{spec: spec, limits: nil}

  defp stub_model(model), do: Mimic.stub(ReqLLM, :model, fn _spec -> {:ok, model} end)

  defp expect_model(spec_assertion, model) do
    Mimic.expect(ReqLLM, :model, fn spec ->
      spec_assertion.(spec)
      {:ok, model}
    end)
  end

  describe "run/3 with an api-key credential" do
    test "passes the resolved model, api key, base url, and messages" do
      expect_model(
        fn spec -> assert spec == "anthropic:claude" end,
        catalogued("anthropic:claude")
      )

      Mimic.expect(ReqLLM, :generate_text, fn model, messages, opts ->
        assert model == catalogued("anthropic:claude")
        assert opts[:api_key] == "sk-test"
        assert opts[:base_url] == "https://proxy.test/v1"
        assert opts[:reasoning_effort] == :none
        assert opts[:receive_timeout] == :timer.minutes(5)
        assert [%{role: "system", content: @system}, %{role: "user", content: @user}] = messages
        {:ok, :response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola" end)

      cred = %{
        model: "anthropic/claude",
        auth: {:api_key, "sk-test", "https://proxy.test/v1"},
        source: :account_model
      }

      assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
    end

    test "omits base_url when nil and surfaces provider errors" do
      stub_model(catalogued("anthropic:claude"))

      Mimic.expect(ReqLLM, :generate_text, fn _model, _messages, opts ->
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

      Mimic.expect(ReqLLM, :model, length(provider_models), fn spec ->
        assert spec in Enum.map(provider_models, &"openai:#{&1}")
        {:ok, uncatalogued(spec)}
      end)

      Mimic.expect(ReqLLM, :generate_text, length(provider_models), fn _model, _messages, opts ->
        assert opts[:base_url] == "https://api.together.ai/v1"
        # Together answers `reasoning_effort: "none"` with a 400.
        refute Keyword.has_key?(opts, :reasoning_effort)
        {:ok, :response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola" end)

      Enum.each(provider_models, fn provider_model ->
        cred = %{
          model: "togetherai/#{provider_model}",
          auth: {:api_key, "together-key", nil},
          source: :account_model
        }

        assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
      end)
    end

    test "routes a Together AI model through a custom gateway base URL" do
      expect_model(
        fn spec -> assert spec == "openai:Qwen/Qwen3.5-9B" end,
        uncatalogued("openai:Qwen/Qwen3.5-9B")
      )

      Mimic.expect(ReqLLM, :generate_text, fn _model, _messages, opts ->
        assert opts[:base_url] == "http://glossia-bifrost.glossia.svc.cluster.local:8080/v1"
        {:ok, :response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola" end)

      cred = %{
        model: "togetherai/Qwen/Qwen3.5-9B",
        auth:
          {:api_key, "sk-glossia-org", "http://glossia-bifrost.glossia.svc.cluster.local:8080/v1"},
        source: :account_model
      }

      assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
    end

    # A reasoning model spends its budget thinking before it writes anything, so
    # without a stated budget the whole response comes back empty.
    test "budgets output for a model the catalog does not know" do
      stub_model(uncatalogued("openai:Qwen/Qwen3.5-9B"))

      Mimic.expect(ReqLLM, :generate_text, fn _model, _messages, opts ->
        assert opts[:max_tokens] == 16_384
        {:ok, :response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola" end)

      cred = %{
        model: "togetherai/Qwen/Qwen3.5-9B",
        auth: {:api_key, "sk", nil},
        source: :account_model
      }

      assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
    end

    test "leaves the budget to the catalog when the model states its own limit" do
      stub_model(catalogued("anthropic:claude"))

      Mimic.expect(ReqLLM, :generate_text, fn _model, _messages, opts ->
        refute Keyword.has_key?(opts, :max_tokens)
        {:ok, :response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola" end)

      cred = %{model: "anthropic/claude", auth: {:api_key, "sk", nil}, source: :account_model}

      assert {:ok, "Hola"} = LLM.run(cred, @system, @user)
    end

    # A response cut off at the ceiling is not a translation, and a reasoning
    # model that runs out mid-thought returns no content at all.
    test "reports a truncated response as an output limit rather than empty text" do
      stub_model(uncatalogued("openai:Qwen/Qwen3.5-9B"))
      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts -> {:ok, :response} end)
      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :length end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "" end)

      cred = %{
        model: "togetherai/Qwen/Qwen3.5-9B",
        auth: {:api_key, "sk", nil},
        source: :account_model
      }

      assert {:error, {:output_limit_reached, 0}} = LLM.run(cred, @system, @user)
    end
  end

  describe "run/3 with an OAuth credential" do
    test "sends auth_mode/access_token and system+user messages" do
      expect_model(
        fn spec -> assert spec == "anthropic:claude-haiku-4-5" end,
        catalogued("anthropic:claude-haiku-4-5")
      )

      Mimic.expect(ReqLLM, :generate_text, fn model, messages, opts ->
        assert model == catalogued("anthropic:claude-haiku-4-5")
        refute Keyword.has_key?(opts, :reasoning_effort)
        assert opts[:auth_mode] == :oauth
        assert opts[:access_token] == "oauth-tok"
        assert opts[:receive_timeout] == :timer.minutes(5)
        assert [%{role: "system", content: @system}, %{role: "user", content: @user}] = messages
        {:ok, :fake_response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :fake_response -> :stop end)
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

    # A failed turn means the agent message that preceded it is partial, so it
    # must not be published as a translation.
    test "fails a turn that reports a failure after emitting an agent message" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s({"type":"item.completed","item":{"type":"agent_message","text":"partial"}}\n) <>
           ~s({"type":"turn.failed","error":{"message":"Provider disconnected"}}\n), 0}
      end)

      assert {:error, {:codex_cli_failed, 0, "Provider disconnected"}} =
               LLM.run(%{source: :codex_session}, @system, @user)
    end

    test "keeps a completed turn that recovered from a mid-turn error event" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s({"type":"error","message":"tool call failed, retrying"}\n) <>
           ~s({"type":"item.completed","item":{"type":"agent_message","text":"Hola"}}\n), 0}
      end)

      assert {:ok, "Hola"} = LLM.run(%{source: :codex_session}, @system, @user)
    end

    test "falls back to an empty-response error when nothing is reported" do
      Mimic.expect(MuonTrap, :cmd, fn "sh", _args, _opts ->
        {~s({"type":"thread.started","thread_id":"t"}\n), 0}
      end)

      assert {:error, :empty_codex_response} = LLM.run(%{source: :codex_session}, @system, @user)
    end
  end

  describe "stream/4" do
    test "OAuth publishes the complete model response" do
      stub_model(catalogued("anthropic:x"))
      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts -> {:ok, :response} end)
      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola, mundo" end)

      {:ok, collector} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn e -> Elixir.Agent.update(collector, &[e | &1]) end

      cred = %{model: "anthropic/x", auth: {:oauth, "tok"}, source: :claude_session}
      assert {:ok, "Hola, mundo"} = LLM.stream(cred, @system, @user, on_event)

      assert Elixir.Agent.get(collector, &Enum.reverse/1) ==
               [:turn_start, {:text, "Hola, mundo"}, :turn_end, :done]
    end

    test "api-key publishes a complete response through the gateway" do
      stub_model(uncatalogued("openai:Qwen/Qwen3.5-9B"))

      Mimic.expect(ReqLLM, :generate_text, fn _model, _messages, opts ->
        assert opts[:max_tokens] == 16_384
        assert opts[:receive_timeout] == :timer.minutes(5)
        {:ok, :response}
      end)

      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "Hola" end)

      {:ok, collector} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn e -> Elixir.Agent.update(collector, &[e | &1]) end

      cred = %{
        model: "togetherai/Qwen/Qwen3.5-9B",
        auth: {:api_key, "sk", nil},
        source: :account_model
      }

      assert {:ok, "Hola"} = LLM.stream(cred, @system, @user, on_event)

      assert Elixir.Agent.get(collector, &Enum.reverse/1) ==
               [:turn_start, {:text, "Hola"}, :turn_end, :done]
    end

    test "a generation error fails the call and is announced once" do
      stub_model(catalogued("anthropic:x"))

      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts ->
        {:error, :rate_limited}
      end)

      {:ok, collector} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn e -> Elixir.Agent.update(collector, &[e | &1]) end

      cred = %{model: "anthropic/x", auth: {:api_key, "sk", nil}, source: :account_model}
      assert {:error, :rate_limited} = LLM.stream(cred, @system, @user, on_event)

      assert Elixir.Agent.get(collector, &Enum.reverse/1) ==
               [:turn_start, {:error, :rate_limited}]
    end

    test "a response truncated at the output limit fails the call" do
      stub_model(uncatalogued("openai:Qwen/Qwen3.5-9B"))
      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts -> {:ok, :response} end)
      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :length end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> "" end)

      cred = %{
        model: "togetherai/Qwen/Qwen3.5-9B",
        auth: {:api_key, "sk", nil},
        source: :account_model
      }

      assert {:error, {:output_limit_reached, 0}} =
               LLM.stream(cred, @system, @user, fn _ -> :ok end)
    end
  end
end
