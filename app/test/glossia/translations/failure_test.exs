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
             request_id: "request_123"
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
    refute inspect(failure) =~ "repository-secret"
    refute inspect(failure) =~ "full translated document"
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
