defmodule Glossia.TranslationsTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.LLMModels
  alias Glossia.Translations
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("translations-ctx@test.com", "translations-ctx")
    %{user: user, account: user.account}
  end

  defp payload(overrides) do
    Map.merge(
      %{
        "model" => "translator",
        "format" => "markdown",
        "source_language" => "English",
        "language" => "Spanish",
        "locale" => "es",
        "source_content" => "Hello, world."
      },
      overrides
    )
  end

  describe "translate/2 validation" do
    test "rejects an unsupported format before touching the model", %{account: account} do
      assert {:error, {:invalid_format, "xml"}} =
               Translations.translate(account, payload(%{"format" => "xml"}))
    end

    test "requires the translation locale metadata", %{account: account} do
      assert {:error, {:missing_field, "source_language"}} =
               Translations.translate(account, payload(%{"source_language" => ""}))

      assert {:error, {:missing_field, "language"}} =
               Translations.translate(account, payload(%{"language" => nil}))

      assert {:error, {:missing_field, "locale"}} =
               Translations.translate(account, payload(%{"locale" => "  "}))
    end

    test "requires source content", %{account: account} do
      assert {:error, {:missing_field, "source_content"}} =
               Translations.translate(account, payload(%{"source_content" => nil}))
    end

    test "errors when no credential resolves (no account model, config, or session)", %{
      account: account
    } do
      # In the test env local sessions are disabled and no inference config is set,
      # so an account with no models yields no credential.
      assert {:error, {:model_not_found, _}} =
               Translations.translate(account, payload(%{"model" => "translator"}))
    end
  end

  describe "translate_stream/4 retries" do
    defp stub_response(text) do
      Mimic.stub(ReqLLM.Response, :finish_reason, fn :response -> :stop end)
      Mimic.stub(ReqLLM.Response, :text, fn :response -> text end)
    end

    setup %{user: user, account: account} do
      {:ok, _model} =
        LLMModels.create_model(account, user, %{
          "handle" => "translator",
          "model" => "anthropic/claude-sonnet-4-20250514",
          "api_key" => "sk-account-key"
        })

      :ok
    end

    test "retries a transient provider failure and succeeds", %{account: account} do
      {:ok, attempts} = Elixir.Agent.start_link(fn -> 0 end)

      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts ->
        case Elixir.Agent.get_and_update(attempts, &{&1 + 1, &1 + 1}) do
          1 -> {:error, %ReqLLM.Error.API.Request{reason: "non-existing domain"}}
          _ -> {:ok, :response}
        end
      end)

      stub_response("Hola")

      {:ok, events} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn event -> Elixir.Agent.update(events, &[event | &1]) end

      assert {:ok, %{text: "Hola"}} =
               Translations.translate_stream(account, payload(%{}), on_event, retry_backoff_ms: 0)

      assert Elixir.Agent.get(attempts, & &1) == 2
      assert {:provider_retry, 2, 8} in Elixir.Agent.get(events, & &1)

      # A streamed error fails the call by contract, so an attempt that is
      # about to be retried must not publish one to subscribers.
      refute Enum.any?(Elixir.Agent.get(events, & &1), &match?({:error, _reason}, &1))
    end

    test "emits the streamed error once the retries are exhausted", %{account: account} do
      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts ->
        {:error, %{reason: "connection closed"}}
      end)

      {:ok, events} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn event -> Elixir.Agent.update(events, &[event | &1]) end

      assert {:error, {:llm_failed, _}} =
               Translations.translate_stream(account, payload(%{}), on_event, retry_backoff_ms: 0)

      assert Enum.any?(Elixir.Agent.get(events, & &1), &match?({:error, _reason}, &1))
    end

    test "keeps retrying through a gateway restart", %{account: account} do
      {:ok, attempts} = Elixir.Agent.start_link(fn -> 0 end)

      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts ->
        case Elixir.Agent.get_and_update(attempts, &{&1 + 1, &1 + 1}) do
          attempt when attempt < 8 -> {:error, %{reason: "connection refused"}}
          8 -> {:ok, :response}
        end
      end)

      stub_response("Hola")

      {:ok, events} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn event -> Elixir.Agent.update(events, &[event | &1]) end

      assert {:ok, %{text: "Hola"}} =
               Translations.translate_stream(account, payload(%{}), on_event, retry_backoff_ms: 0)

      assert Elixir.Agent.get(attempts, & &1) == 8
      assert {:provider_retry, 8, 8} in Elixir.Agent.get(events, & &1)
      refute Enum.any?(Elixir.Agent.get(events, & &1), &match?({:error, _reason}, &1))
    end

    test "does not retry an exhausted credit failure", %{account: account} do
      {:ok, attempts} = Elixir.Agent.start_link(fn -> 0 end)

      Mimic.stub(ReqLLM, :generate_text, fn _model, _messages, _opts ->
        Elixir.Agent.update(attempts, &(&1 + 1))
        {:error, %{reason: "Credit limit exceeded", status: 402}}
      end)

      assert {:error, {:llm_failed, _}} =
               Translations.translate_stream(account, payload(%{}), fn _event -> :ok end,
                 retry_backoff_ms: 0
               )

      assert Elixir.Agent.get(attempts, & &1) == 1
    end
  end
end
