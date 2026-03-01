defmodule Glossia.ChangeSummaryTest do
  use ExUnit.Case, async: true

  alias Glossia.ChangeSummary

  # ---------------------------------------------------------------------------
  # describe_voice_changes/4
  # ---------------------------------------------------------------------------

  describe "describe_voice_changes/4" do
    test "returns initial message when original voice is nil" do
      assert ChangeSummary.describe_voice_changes(nil, %{}, [], []) ==
               "Created initial voice configuration."
    end

    test "describes changed base fields" do
      original = %{tone: "formal", formality: "neutral", target_audience: "", guidelines: ""}

      params = %{
        "tone" => "casual",
        "formality" => "neutral",
        "target_audience" => "developers",
        "guidelines" => ""
      }

      result = ChangeSummary.describe_voice_changes(original, params, [], [])

      assert result =~ "Changed tone from 'formal' to 'casual'."
      assert result =~ "Set target audience to 'developers'."
      refute result =~ "formality"
      refute result =~ "guidelines"
    end

    test "returns no changes when nothing changed" do
      original = %{tone: "formal", formality: "neutral", target_audience: "", guidelines: ""}

      params = %{
        "tone" => "formal",
        "formality" => "neutral",
        "target_audience" => "",
        "guidelines" => ""
      }

      assert ChangeSummary.describe_voice_changes(original, params, [], []) ==
               "No changes detected."
    end

    test "describes added locale override" do
      original = %{tone: "formal", formality: "neutral", target_audience: "", guidelines: ""}

      params = %{
        "tone" => "formal",
        "formality" => "neutral",
        "target_audience" => "",
        "guidelines" => ""
      }

      overrides = [
        %{locale: "es", tone: "casual", formality: nil, target_audience: nil, guidelines: nil}
      ]

      result = ChangeSummary.describe_voice_changes(original, params, [], overrides)
      assert result =~ "Added locale override for es."
    end

    test "describes removed locale override" do
      original = %{tone: "formal", formality: "neutral", target_audience: "", guidelines: ""}

      params = %{
        "tone" => "formal",
        "formality" => "neutral",
        "target_audience" => "",
        "guidelines" => ""
      }

      orig_overrides = [
        %{locale: "es", tone: "casual", formality: nil, target_audience: nil, guidelines: nil}
      ]

      result = ChangeSummary.describe_voice_changes(original, params, orig_overrides, [])
      assert result =~ "Removed locale override for es."
    end
  end

  # ---------------------------------------------------------------------------
  # describe_glossary_changes/2
  # ---------------------------------------------------------------------------

  describe "describe_glossary_changes/2" do
    test "describes added terms" do
      original = []

      current = [
        %{
          term: "API",
          definition: "Application Programming Interface",
          case_sensitive: true,
          translations: []
        }
      ]

      result = ChangeSummary.describe_glossary_changes(original, current)
      assert result =~ "Added term 'API'."
    end

    test "describes removed terms" do
      original = [%{term: "API", definition: nil, case_sensitive: false, translations: []}]
      current = []

      result = ChangeSummary.describe_glossary_changes(original, current)
      assert result =~ "Removed term 'API'."
    end

    test "describes updated definition" do
      original = [%{term: "API", definition: "old", case_sensitive: false, translations: []}]
      current = [%{term: "API", definition: "new", case_sensitive: false, translations: []}]

      result = ChangeSummary.describe_glossary_changes(original, current)
      assert result =~ "Updated definition for 'API'."
    end

    test "describes added translation" do
      original = [%{term: "API", definition: nil, case_sensitive: false, translations: []}]

      current = [
        %{
          term: "API",
          definition: nil,
          case_sensitive: false,
          translations: [%{locale: "es", translation: "API"}]
        }
      ]

      result = ChangeSummary.describe_glossary_changes(original, current)
      assert result =~ "Added es translation for 'API'."
    end

    test "returns no changes when nothing changed" do
      entries = [%{term: "API", definition: nil, case_sensitive: false, translations: []}]

      assert ChangeSummary.describe_glossary_changes(entries, entries) == "No changes detected."
    end
  end

  # ---------------------------------------------------------------------------
  # generate/3
  # ---------------------------------------------------------------------------

  describe "generate/3" do
    test "returns summary from LLM response" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{
            "id" => "test",
            "choices" => [
              %{"message" => %{"content" => "Switched tone to casual"}, "finish_reason" => "stop"}
            ],
            "usage" => %{"total_tokens" => 50},
            "base_resp" => %{"status_code" => 0}
          })
        )
      end)

      assert {:ok, "Switched tone to casual"} =
               ChangeSummary.generate(
                 "Changed tone from 'formal' to 'casual'.",
                 "voice configuration",
                 api_key: "test-key",
                 req_options: [plug: {Req.Test, Glossia.Minimax}]
               )
    end

    test "returns error when API key not configured" do
      assert {:error, :not_configured} =
               ChangeSummary.generate("some diff", "glossary", api_key: nil)
    end

    test "trims whitespace from summary" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{
            "id" => "test",
            "choices" => [
              %{"message" => %{"content" => "  Added API term  \n"}, "finish_reason" => "stop"}
            ],
            "usage" => %{"total_tokens" => 30},
            "base_resp" => %{"status_code" => 0}
          })
        )
      end)

      assert {:ok, "Added API term"} =
               ChangeSummary.generate(
                 "Added term 'API'.",
                 "glossary",
                 api_key: "test-key",
                 req_options: [plug: {Req.Test, Glossia.Minimax}]
               )
    end
  end
end
