defmodule Glossia.Translations.ContextTest do
  use ExUnit.Case, async: true

  alias Glossia.Accounts.{Account, Voice, VoiceOverride}
  alias Glossia.Translations.Context

  defp entry(id, term, translation, overrides \\ %{}) do
    Map.merge(
      %{
        id: id,
        term: term,
        translation: translation,
        definition: nil,
        case_sensitive: false
      },
      overrides
    )
  end

  describe "select_entries/3" do
    test "selects exact Unicode-aware matches and excludes unrelated terms" do
      entries = [
        entry("account", "Account", "Cuenta"),
        entry("plan", "plan", "plan"),
        entry("cafe", "café", "cafetería"),
        entry("unused", "workspace", "espacio de trabajo")
      ]

      selected = Context.select_entries(entries, "An account has a planet and a café.", [])

      assert Enum.map(selected, & &1.id) == ["account", "cafe"]
    end

    test "matches terminology in unspaced scripts and Latin terms beside them" do
      entries = [
        entry("japanese", "日本語", "Japanese"),
        entry("ai", "AI", "artificial intelligence")
      ]

      selected = Context.select_entries(entries, "これは日本語です。AI機能を開きます。", [])

      assert Enum.map(selected, & &1.id) == ["japanese", "ai"]
    end

    test "lets longer phrases claim nested matches before shorter terms" do
      entries = [
        entry("short", "Account", "Cuenta"),
        entry("long", "Account settings", "Configuración de la cuenta")
      ]

      assert Context.select_entries(entries, "Open Account settings.", [])
             |> Enum.map(& &1.id) == ["long"]

      assert Context.select_entries(entries, "Open Account settings for another account.", [])
             |> Enum.map(& &1.id) == ["long", "short"]
    end

    test "honors case sensitivity and ignores preserved content" do
      entries = [
        entry("project", "Project", "Proyecto", %{case_sensitive: true}),
        entry("token", "token", "ficha")
      ]

      selected =
        Context.select_entries(
          entries,
          "A project uses `Project token` at https://example.com/token.",
          []
        )

      assert selected == []
    end

    test "selects a case-sensitive term when the case matches" do
      entries = [entry("project", "Project", "Proyecto", %{case_sensitive: true})]

      assert [%{id: "project"}] = Context.select_entries(entries, "Open the Project.", [])
      assert Context.select_entries(entries, "Open the project.", []) == []
    end

    test "keeps Unicode case folding aligned with case-insensitive matching" do
      entries = [entry("sigma", "Σ", "sigma")]

      assert [%{id: "sigma"}] = Context.select_entries(entries, "Value: ς.", [])
    end

    test "does not raise when source text contains invalid encoding" do
      entries = [entry("account", "Account", "Cuenta")]

      assert [%{id: "account"}] =
               Context.select_entries(entries, <<"Account ", 0xFF, " settings">>, [])
    end

    test "honors an explicit none preservation policy consistently" do
      entries = [entry("account", "Account", "Cuenta")]

      assert [%{id: "account"}] =
               Context.select_entries(entries, "Use `Account` here.", ["none"])
    end
  end

  describe "prompt_body/3" do
    test "keeps voice context but narrows terminology to the current segment" do
      bundle = %{
        Context.empty_bundle("es-MX")
        | voice: %{
            locale: "es-MX",
            tone: "authoritative",
            formality: "formal",
            target_audience: "Enterprise customers",
            description: "A localization product",
            guidelines: "Use concise sentences.",
            cultural_notes: %{
              "MX" => "Use respectful and direct language.",
              "US" => "Use American English."
            }
          },
          terminology: [
            entry("account", "Account", "Cuenta", %{definition: "A customer organization."}),
            entry("project", "Project", "Proyecto")
          ]
      }

      prompt = Context.prompt_body(bundle, "Create an Account.", [])

      assert prompt =~ "Organization voice:"
      assert prompt =~ "Cultural guidance for MX"
      assert prompt =~ "Use respectful and direct language."
      refute prompt =~ "American English"
      assert prompt =~ ~s("Account" → "Cuenta")
      assert prompt =~ "A customer organization."
      refute prompt =~ ~s("Project" → "Proyecto")
    end

    test "uses the sole target country for a language-only locale" do
      bundle = %{
        Context.empty_bundle("es")
        | voice: %{
            locale: "es",
            tone: "formal",
            formality: nil,
            target_audience: nil,
            description: nil,
            guidelines: nil,
            target_countries: ["MX"],
            cultural_notes: %{"MX" => "Use Mexican Spanish."}
          }
      }

      assert Context.prompt_body(bundle, "Hello.", []) =~
               "Cultural guidance for MX:\nUse Mexican Spanish."
    end

    test "bounds terminology while prioritizing frequent matches" do
      entries =
        for index <- 1..60 do
          entry(
            "term-#{index}",
            "Term#{index}",
            "Término#{index}",
            %{definition: String.duplicate("Long definition. ", 100)}
          )
        end

      source =
        ["Term60", "Term60", "Term60" | Enum.map(1..59, &"Term#{&1}")]
        |> Enum.join(" ")

      bundle = %{Context.empty_bundle("es") | terminology: entries}
      result = Context.prompt(bundle, source, [])
      prompt = result.body

      assert length(:binary.matches(prompt, " → ")) == 50
      assert prompt =~ ~s("Term60" → "Término60")
      assert byte_size(prompt) <= 12_000
      assert result.budget.terminology_matched == 60
      assert result.budget.terminology_included == 50
      assert result.budget.terminology_omitted == 10
      assert result.budget.terminology_definitions_omitted > 0
    end

    test "bounds server-defined voice prose while preserving its structure" do
      oversized = String.duplicate("multibyte 文 ", 2_000)

      bundle = %{
        Context.empty_bundle("es-MX")
        | voice: %{
            locale: "es-MX",
            tone: oversized,
            formality: oversized,
            target_audience: oversized,
            description: oversized,
            guidelines: oversized,
            cultural_notes: %{"MX" => oversized}
          }
      }

      result = Context.prompt(bundle, "Hello.", [])
      prompt = result.body

      assert byte_size(prompt) <= Context.max_voice_prompt_bytes()
      assert prompt =~ "Organization voice:"
      assert prompt =~ "- Tone:"
      assert prompt =~ "- Formality:"
      assert prompt =~ "- Audience:"
      assert prompt =~ "Cultural guidance for MX:"
      assert prompt =~ "Voice guidelines:"
      assert prompt =~ "Product context:"
      assert prompt =~ "[truncated]"
      assert String.valid?(prompt)
      assert result.budget.voice_truncated
    end

    test "keeps every field at its accepted byte limit inside the voice envelope" do
      description = String.duplicate("d", Voice.description_limit())

      bundle = %{
        Context.empty_bundle("es-MX")
        | voice: %{
            locale: "es-MX",
            tone: String.duplicate("t", 80),
            formality: String.duplicate("f", 80),
            target_audience: String.duplicate("a", Voice.target_audience_limit()),
            description: description,
            guidelines: String.duplicate("g", Voice.guidelines_limit()),
            cultural_notes: %{"MX" => String.duplicate("c", Voice.cultural_note_limit())}
          }
      }

      result = Context.prompt(bundle, "Hello.", [])

      refute result.budget.voice_truncated
      assert byte_size(result.body) <= Context.max_voice_prompt_bytes()
      assert String.ends_with?(result.body, description)
    end

    test "uses the region before locale extension keys for cultural guidance" do
      bundle = %{
        Context.empty_bundle("en-US-u-ca-gregory")
        | voice: %{
            locale: "en-US-u-ca-gregory",
            tone: nil,
            formality: nil,
            target_audience: nil,
            description: nil,
            guidelines: nil,
            cultural_notes: %{
              "US" => "Use American English.",
              "CA" => "Use Canadian English."
            }
          }
      }

      prompt = Context.prompt_body(bundle, "Hello.", [])

      assert prompt =~ "Cultural guidance for US:"
      assert prompt =~ "Use American English."
      refute prompt =~ "Canadian English"
    end
  end

  test "lockfile provenance contains aggregate hashes, but no raw context or term fingerprints" do
    bundle = %{
      Context.empty_bundle("es")
      | snapshot: %{
          Context.empty_snapshot()
          | voice_version: 4,
            glossary_version: 9
        },
        voice: %{
          locale: "es",
          tone: "formal",
          formality: nil,
          target_audience: nil,
          description: nil,
          guidelines: "Private voice guidance",
          cultural_notes: %{}
        },
        terminology: [entry("entry-id", "Account", "Cuenta")]
    }

    provenance = Context.provenance(bundle)
    encoded = Jason.encode!(provenance)

    assert get_in(provenance, ["voice", "version"]) == 4
    assert get_in(provenance, ["terminology", "glossary_version"]) == 9
    refute Map.has_key?(provenance["terminology"], "term_keys")
    refute encoded =~ "Private voice guidance"
    refute encoded =~ "Cuenta"
  end

  test "voice changesets reject server prose that cannot fit the prompt policy" do
    voice_changeset =
      Voice.changeset(%Voice{}, %{
        version: 1,
        target_audience: String.duplicate("a", Voice.target_audience_limit() + 1),
        guidelines: String.duplicate("g", Voice.guidelines_limit() + 1),
        description: String.duplicate("d", Voice.description_limit() + 1),
        cultural_notes: %{
          "MX" => String.duplicate("c", Voice.cultural_note_limit() + 1)
        }
      })

    assert Keyword.has_key?(voice_changeset.errors, :target_audience)
    assert Keyword.has_key?(voice_changeset.errors, :guidelines)
    assert Keyword.has_key?(voice_changeset.errors, :description)
    assert Keyword.has_key?(voice_changeset.errors, :cultural_notes)

    multibyte_changeset =
      Voice.changeset(%Voice{}, %{
        version: 1,
        guidelines: String.duplicate("文", div(Voice.guidelines_limit(), 3) + 1)
      })

    assert Keyword.has_key?(multibyte_changeset.errors, :guidelines)

    override_changeset =
      VoiceOverride.changeset(%VoiceOverride{}, %{
        locale: "es-MX",
        target_audience: String.duplicate("a", Voice.target_audience_limit() + 1),
        guidelines: String.duplicate("g", Voice.guidelines_limit() + 1)
      })

    assert Keyword.has_key?(override_changeset.errors, :target_audience)
    assert Keyword.has_key?(override_changeset.errors, :guidelines)
  end

  test "maps a failed context node call to a relay error" do
    assert {:error, {:context_relay_failed, :nodedown}} =
             Context.resolve_locales_on(
               :missing_context_node@invalid,
               %Account{id: 1},
               Context.empty_snapshot(),
               ["es"]
             )
  end
end
