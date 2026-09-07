defmodule Glossia.Models.ModelIdentifierTest do
  use ExUnit.Case, async: true

  alias Glossia.Models.ModelIdentifier

  test "keeps canonical models.dev identifiers unchanged" do
    identifier = "togetherai/moonshotai/Kimi-K2.7-Code"

    assert ModelIdentifier.normalize(identifier) == identifier
    assert ModelIdentifier.provider(identifier) == "togetherai"
    assert ModelIdentifier.provider_model(identifier) == "moonshotai/Kimi-K2.7-Code"
  end

  test "normalizes legacy colon identifiers" do
    assert ModelIdentifier.normalize("togetherai:moonshotai/Kimi-K2.7-Code") ==
             "togetherai/moonshotai/Kimi-K2.7-Code"
  end

  test "converts only at the ReqLLM boundary" do
    assert ModelIdentifier.to_req_llm("togetherai/moonshotai/Kimi-K2.7-Code") ==
             "togetherai:moonshotai/Kimi-K2.7-Code"
  end

  test "does not reinterpret a colon inside a canonical provider model" do
    assert ModelIdentifier.normalize("custom/model:variant") == "custom/model:variant"
  end
end
