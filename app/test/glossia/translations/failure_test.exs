defmodule Glossia.Translations.FailureTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Failure

  test "keeps only allowlisted provider diagnostics" do
    reason =
      {:llm_failed,
       %{
         reason: "Credit limit exceeded",
         status: 402,
         response_body: %{"type" => "credit_limit", "message" => "Add credits"},
         request_body: %{"prompt" => "private source document"},
         headers: [
           {"authorization", "Bearer provider-secret"},
           {"x-request-id", "request_123"}
         ],
         stacktrace: ["private/internal/path.ex"]
       }}

    assert Failure.from(reason, "togetherai") == %{
             kind: "provider-credit",
             scope: "session",
             provider: "togetherai",
             status: 402,
             code: "credit_limit",
             request_id: "request_123",
             retry_after_ms: nil
           }

    rendered = inspect(Failure.from(reason, "togetherai"))

    refute rendered =~ "private source document"
    refute rendered =~ "provider-secret"
    refute rendered =~ "private/internal/path.ex"
  end

  test "classifies an exhausted local session quota as a credit failure" do
    reason =
      {:llm_failed,
       {:codex_cli_failed, 0,
        "You've hit your usage limit. Visit https://chatgpt.com/codex/settings/usage to purchase more credits."}}

    failure = Failure.from(reason, "openai")

    assert failure.kind == "provider-credit"
    assert failure.scope == "session"
    assert failure.provider == "openai"
  end

  test "classifies a provider error struct instead of crashing on it" do
    reason =
      {:llm_failed,
       %ReqLLM.Error.API.Request{
         reason: "Credit limit exceeded",
         status: 402,
         response_body: %{"type" => "credit_limit"},
         request_body: ["{\"", "messages", "\": private source document"]
       }}

    failure = Failure.from(reason, "anthropic")

    assert failure.kind == "provider-credit"
    assert failure.status == 402
    assert failure.code == "credit_limit"
    refute inspect(failure) =~ "private source document"
  end

  test "treats transport failures as retryable and credit failures as terminal" do
    transport =
      Failure.from(
        {:llm_failed, %ReqLLM.Error.API.Request{reason: "non-existing domain"}},
        "anthropic"
      )

    assert transport.kind == "provider-error"
    assert Failure.retryable?(transport)

    assert Failure.retryable?(Failure.from({:llm_failed, %{status: 429}}, "anthropic"))
    refute Failure.retryable?(Failure.from({:llm_failed, %{status: 402}}, "anthropic"))
    refute Failure.retryable?(Failure.from({:llm_failed, %{status: 401}}, "anthropic"))
    refute Failure.retryable?(Failure.from({:validation_failed, "invalid yaml"}))
  end

  # An unknown model or a malformed request fails identically every time.
  test "does not retry a client error the provider will reject again" do
    for status <- [400, 404, 422] do
      failure = Failure.from({:llm_failed, %{reason: "bad request", status: status}}, "anthropic")

      assert failure.kind == "provider-error"
      refute Failure.retryable?(failure)
    end

    assert Failure.retryable?(
             Failure.from({:llm_failed, %{reason: "request timed out", status: 408}}, "anthropic")
           )
  end

  test "does not call a rejected request a timeout" do
    failure =
      Failure.from(
        {:llm_failed,
         %{
           reason: "request timed out while the provider rejected the request",
           status: 400,
           response_body: %{"type" => "invalid_request_error"}
         }},
        "openai"
      )

    assert failure.kind == "provider-error"
    assert failure.status == 400
    assert failure.code == "invalid_request_error"
    refute Failure.retryable?(failure)
  end

  test "corrects a stale timeout event with a rejected-request status" do
    failure =
      Failure.normalize(%{
        kind: "provider-timeout",
        status: 400,
        code: "invalid_request_error"
      })

    assert failure.kind == "provider-error"
    assert failure.status == 400
    assert failure.code == "invalid_request_error"
  end

  # Providers word per-minute rate limits as an exceeded quota; that is a
  # retryable throttle, not an exhausted balance.
  test "reads a rate-limited quota message as a rate limit, not exhausted credit" do
    failure =
      Failure.from(
        {:llm_failed,
         %{reason: "Quota exceeded for quota metric requests per minute", status: 429}},
        "google"
      )

    assert failure.kind == "provider-rate-limit"
    assert Failure.retryable?(failure)
  end

  test "classifies a nested streaming error without retaining its raw text" do
    raw =
      """
      Stream failed: %ReqLLM.Error.API.Request{
        reason: "Credit limit exceeded",
        status: 402,
        response_body: %{"type" => "credit_limit"},
        request_body: %{"prompt" => "confidential prompt"},
        headers: [{"x-request-id", "request_nested"}]
      }
      """

    failure = Failure.from({:llm_failed, %{reason: raw}}, "togetherai")

    assert failure.kind == "provider-credit"
    assert failure.status == 402
    assert failure.code == "credit_limit"
    assert failure.request_id == "request_nested"
    refute inspect(failure) =~ "confidential prompt"
  end

  test "does not treat request payload fields as diagnostics" do
    reason =
      {:llm_failed,
       %{
         reason: "Provider request failed",
         request_body: %{
           "status" => 402,
           "code" => "private_document_code",
           "x-request-id" => "private_document_identifier"
         }
       }}

    failure = Failure.from(reason, "togetherai")

    assert failure.kind == "provider-error"
    assert failure.status == nil
    assert failure.code == nil
    assert failure.request_id == nil
  end

  test "does not expose validation command output" do
    failure =
      Failure.from(
        {:validation_failed,
         "validation failed: exit 1\nTOKEN=repository-secret\nfull translated document"},
        "openai"
      )

    assert failure.kind == "validation-command"
    assert failure.scope == "item"
    assert failure.validation_code == "validation-command-exit"
    assert failure.validation_message == "validation failed: exit"
    assert failure.validation_exit_status == 1
    assert failure |> JSON.encode!() |> JSON.decode!() |> Failure.normalize() == failure
    refute inspect(failure) =~ "repository-secret"
    refute inspect(failure) =~ "full translated document"
  end

  test "retains distinct safe Markdown recovery reasons through serialization" do
    for {message, code} <- [
          {"Markdown text-literal recovery must return a JSON string array of matching length",
           "markdown-literal-array-shape"},
          {"Markdown text-literal recovery returned invalid JSON",
           "markdown-literal-array-syntax"},
          {"Markdown text-node recovery produced an empty translation", "markdown-literal-empty"},
          {"Markdown text-node recovery changed or emptied a source literal",
           "markdown-literal-changed"},
          {"Markdown text-node recovery did not match the source text nodes",
           "markdown-literal-count"},
          {"Markdown recovery markers were missing, duplicated, or reordered",
           "markdown-recovery-markers"}
        ] do
      failure = Failure.from({:validation_failed, message <> ": private source content"})
      assert failure.validation_code == code
      assert failure.validation_message == message
      assert failure |> JSON.encode!() |> JSON.decode!() |> Failure.normalize() == failure
      refute inspect(failure) =~ "private source content"
    end
  end

  test "removes the dynamic marker index while identifying an empty recovery marker" do
    failure =
      Failure.from({:validation_failed, "Markdown recovery marker 12 had an empty translation"})

    assert failure.validation_code == "markdown-recovery-empty"
    assert failure.validation_message == "Markdown recovery marker had an empty translation"
  end

  test "retains diagnostics when rebuilding a failed item from durable progress" do
    event = %{
      type: "item_failed",
      index: 0,
      model_calls: 14,
      reason:
        Failure.from({:validation_failed, "Markdown text-literal recovery returned invalid JSON"})
    }

    decoded =
      event |> JSON.encode!() |> JSON.decode!() |> Glossia.TranslationSessions.Progress.decode()

    state =
      Glossia.TranslationSessions.Progress.fold([
        %{type: "item_started", index: 0, output_path: "fr/commands.md", locale: "fr"},
        decoded
      ])

    assert state.items[0].reason.validation_code == "markdown-literal-array-syntax"
    assert state.items[0].turns == 14
  end

  test "does not trust diagnostic messages or unknown codes from progress events" do
    for code <- ["markdown-literal-array-shape", "private-code", nil] do
      failure =
        Failure.normalize(%{
          "kind" => "validation",
          "validation_code" => code,
          "validation_message" => "repository-secret"
        })

      refute inspect(failure) =~ "repository-secret"
      refute inspect(failure) =~ "private-code"
    end

    failure = Failure.from({:validation_failed, "unknown error: repository-secret"})
    assert failure.validation_code == "unclassified"
    refute inspect(failure) =~ "repository-secret"

    for status <- ["repository-secret", 999, -1, %{}] do
      failure =
        Failure.normalize(%{
          kind: "validation-command",
          validation_code: "validation-command-exit",
          validation_exit_status: status
        })

      refute Map.has_key?(failure, :validation_exit_status)
    end
  end

  test "classifies a changed protected marker as preserved content" do
    failure =
      Failure.from(
        {:validation_failed,
         "protected token marker occurred 0 times; preserve it exactly once for a private value"},
        "openai"
      )

    assert failure.kind == "validation-preserved-content"
    assert failure.scope == "item"
    refute inspect(failure) =~ "private value"
  end

  test "honours the provider's own Retry-After over any chosen backoff" do
    failure =
      Failure.from(
        {:llm_failed,
         ReqLLM.Error.API.Request.exception(
           reason: "HTTP 429: Request failed",
           status: 429,
           response_body: %{"error" => %{"type" => "rate_limit"}},
           headers: [{"retry-after", "12"}]
         )},
        "togetherai"
      )

    assert failure.kind == "provider-rate-limit"
    assert failure.retry_after_ms == 12_000
    assert Failure.retryable?(failure)
  end

  test "leaves the delay to the caller when the provider names none" do
    failure =
      Failure.from(
        {:llm_failed,
         ReqLLM.Error.API.Request.exception(
           reason: "HTTP 429: Request failed",
           status: 429,
           response_body: %{"error" => %{"type" => "rate_limit"}}
         )},
        "togetherai"
      )

    assert failure.retry_after_ms == nil
  end

  test "refuses to park a run on an absurd or unparsable Retry-After" do
    for value <- ["999999", "abc", "-5", "Wed, 21 Oct 2026 07:28:00 GMT", ""] do
      failure =
        Failure.from(
          {:llm_failed,
           ReqLLM.Error.API.Request.exception(
             reason: "HTTP 429",
             status: 429,
             response_body: %{},
             headers: [{"retry-after", value}]
           )},
          "togetherai"
        )

      assert failure.retry_after_ms in [nil, :timer.minutes(5)]
    end
  end

  test "keeps Retry-After in milliseconds across a progress round trip" do
    # `from/2` states milliseconds, so a value coming back over progress
    # messaging must be validated rather than rescaled as seconds again.
    failure =
      Failure.normalize(%{
        kind: "provider-rate-limit",
        status: 429,
        retry_after_ms: 12_000
      })

    assert failure.retry_after_ms == 12_000
  end

  test "treats exhausted credit and rejected credentials as run stopping" do
    for kind <- ["provider-credit", "provider-credentials"] do
      assert Failure.run_stopping?(Failure.normalize(%{kind: kind, status: 402}))
    end
  end

  test "lets transient provider failures leave the rest of the run alone" do
    for {kind, status} <- [
          {"provider-rate-limit", 429},
          {"provider-timeout", 408},
          {"provider-error", 500}
        ] do
      refute Failure.run_stopping?(Failure.normalize(%{kind: kind, status: status}))
    end
  end

  test "keeps an item failure out of the run stopping set" do
    refute Failure.run_stopping?(Failure.from({:validation_failed, "invalid yaml"}))
  end

  test "describes exhausted credit with the provider, status, and the fix" do
    description =
      Failure.describe(
        Failure.normalize(%{kind: "provider-credit", provider: "togetherai", status: 402})
      )

    assert description ==
             "The model provider rejected the translation because the account has no " <>
               "credit left (togetherai, HTTP 402). Add credits for the model provider and retry."
  end

  test "describes rejected credentials without inventing a provider it was not given" do
    description = Failure.describe(Failure.normalize(%{kind: "provider-credentials"}))

    assert description ==
             "The model provider rejected the configured credentials. " <>
               "Check the account's model credentials and retry."
  end

  test "revalidates values received through progress messaging" do
    failure =
      Failure.normalize(%{
        kind: "provider-credit",
        scope: "item",
        provider: "TOGETHERAI",
        status: 402,
        code: "credit_limit",
        request_id: "request_123",
        raw: "must not survive"
      })

    assert failure.scope == "session"
    assert failure.provider == "togetherai"
    refute Map.has_key?(failure, :raw)
  end
end
