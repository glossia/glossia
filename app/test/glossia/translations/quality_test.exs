defmodule Glossia.Translations.QualityTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.Engine
  alias Glossia.Translations.Quality
  alias Glossia.Translations.Failure

  defp item(source) do
    %{
      source_abs: source,
      output_abs: "/repo/es/guide.txt",
      output_path: "es/guide.txt",
      locale: "es",
      language: "Spanish",
      source_language: "en",
      format: "text",
      frontmatter_mode: :preserve,
      preserve: [],
      prompt: "Preserve cancellation conditions.",
      retries: 1,
      model: "translator",
      context_body: "",
      locale_override_body: "",
      server_context: Context.empty_bundle("es"),
      decision_model: %{
        handle: "quality",
        model: "typesafe/jev-latest",
        base_url: nil,
        decision_min_score: 7.0
      }
    }
  end

  defp response(dimensions, overrides \\ %{}) do
    answers =
      Map.new(
        Enum.flat_map(dimensions, fn {key, _, _, _} ->
          [
            {key <> "_score", %{"type" => "score", "score" => 8.0, "confidence" => 0.9}},
            {key <> "_weakness", %{"type" => "choice", "choice" => "none", "confidence" => 0.9}},
            {key <> "_severity", %{"type" => "choice", "choice" => "none", "confidence" => 0.9}}
          ]
        end)
      )

    %{"model" => "jev-1.13.0", "answers" => Map.merge(answers, overrides)}
  end

  test "all dimensions pass independently; scores normalize without rounding" do
    dimensions = Quality.dimensions(item(nil))
    assert {:ok, %{passed: true}} = Quality.parse(response(dimensions), dimensions, 7.0)

    below =
      response(dimensions, %{
        "meaning_score" => %{"type" => "score", "score" => 5.999, "confidence" => 0.9}
      })

    assert {:ok, %{passed: false} = report} = Quality.parse(below, dimensions, 7.0)
    assert Quality.feedback(report) =~ "Meaning preservation"
    assert Quality.feedback(report) =~ "required 7.0/10"
  end

  test "major and critical errors fail even with high scores" do
    dimensions = Quality.dimensions(item(nil))

    for severity <- ["major", "critical"] do
      data =
        response(dimensions, %{
          "meaning_severity" => %{"type" => "choice", "choice" => severity, "confidence" => 0.9}
        })

      assert {:ok, %{passed: false}} = Quality.parse(data, dimensions, 7.0)
    end
  end

  test "missing answers, invalid scores, and unknown weakness choices fail closed" do
    dimensions = Quality.dimensions(item(nil))

    assert {:error, :invalid_decision_response} =
             Quality.parse(%{"answers" => %{}}, dimensions, 7.0)

    for invalid <- [
          %{"meaning_score" => %{"type" => "score", "score" => 10.0, "confidence" => 0.9}},
          %{
            "meaning_weakness" => %{
              "type" => "choice",
              "choice" => "made_up",
              "confidence" => 0.9
            }
          },
          %{"meaning_severity" => %{"type" => "choice", "choice" => "none", "confidence" => -1}}
        ] do
      assert {:error, :invalid_decision_response} =
               Quality.parse(response(dimensions, invalid), dimensions, 7.0)
    end
  end

  test "voice requires supplied guidance and every question contains its dimension instructions" do
    assert length(Quality.dimensions(%{item(nil) | prompt: nil})) == 7
    assert length(Quality.dimensions(item(nil))) == 8
    configured = %{item(nil) | context_body: "Use a conversational tone."}
    dimensions = Quality.dimensions(configured)
    assert length(dimensions) == 8
    questions = Quality.questions(dimensions)
    assert map_size(questions) == 24
    assert questions["meaning_score"].instructions =~ "Preserve claims"
    assert questions["voice_weakness"].instructions =~ "Voice and register"
  end

  test "oversized input fails before requesting an assessment" do
    assert %{kind: "decision-input-too-large"} =
             Failure.from({:decision_evaluation_failed, :decision_input_too_large})

    assert {:error, {:decision_evaluation_failed, :decision_input_too_large}} =
             Quality.preflight(item(nil), String.duplicate("x", 30_000))

    assert {:error, :decision_input_too_large} =
             Quality.assess(item(nil), %Account{id: 1}, String.duplicate("x", 30_000), "Hola",
               decision_evaluator: fn _, _, _, _, _ -> flunk("oversized input was sent") end
             )
  end

  @tag :tmp_dir
  test "configured evaluator rejects then accepts a revision with correction feedback", %{
    tmp_dir: dir
  } do
    source = Path.join(dir, "guide.txt")
    File.write!(source, "You may cancel before the job starts.")
    item = item(source)
    dimensions = Quality.dimensions(item)

    Mimic.expect(Translations, :translate_stream, fn _account, payload, _events, _opts ->
      assert payload["last_error"] == nil
      {:ok, %{text: "Puedes cancelar después de iniciar.", model: "writer", provider: "test"}}
    end)

    Mimic.expect(Translations, :translate_stream, fn _account, payload, _events, _opts ->
      assert payload["last_error"] =~ "Restore the source meaning"
      {:ok, %{text: "Puedes cancelar antes de iniciar.", model: "writer", provider: "test"}}
    end)

    evaluator = fn _account, configuration, state, questions, _opts ->
      assert configuration.handle == "quality"
      assert state.source == "You may cancel before the job starts."
      assert state.locale == "es"
      assert state.document_instructions == item.prompt
      assert questions["meaning_score"].type == "score"

      if state.translation =~ "después" do
        {:ok,
         response(dimensions, %{
           "meaning_score" => %{"type" => "score", "score" => 3.0, "confidence" => 0.9},
           "meaning_weakness" => %{
             "type" => "choice",
             "choice" => "changed_meaning",
             "confidence" => 0.9
           },
           "meaning_severity" => %{"type" => "choice", "choice" => "major", "confidence" => 0.9}
         })}
      else
        {:ok, response(dimensions)}
      end
    end

    owner = self()

    assert {:ok, %{text: "Puedes cancelar antes de iniciar.", quality: %{passed: true}}} =
             Engine.apply_item(item, %Account{id: 1}, &send(owner, &1), fn _, _ -> :ok end,
               decision_evaluator: evaluator
             )

    assert_received {:quality_assessed, %{passed: false}}
    assert_received {:quality_assessed, %{passed: true}}
    refute_received {:translation_output, "Puedes cancelar después de iniciar."}
  end

  @tag :tmp_dir
  test "quality failures exhaust the existing retry budget", %{tmp_dir: dir} do
    source = Path.join(dir, "guide.txt")
    File.write!(source, "Hello")
    item = %{item(source) | retries: 0}

    Mimic.expect(Translations, :translate_stream, fn _, _, _, _ ->
      {:ok, %{text: "Hola", model: "writer", provider: "test"}}
    end)

    evaluator = fn _, _, _, _, _ ->
      {:ok,
       response(Quality.dimensions(item), %{
         "meaning_score" => %{"type" => "score", "score" => 2.0, "confidence" => 0.9}
       })}
    end

    assert {:error, {:validation_failed, message}} =
             Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end, fn _, _ -> :ok end,
               decision_evaluator: evaluator
             )

    assert message =~ "Translation quality failed"
  end

  @tag :tmp_dir
  test "provider failures do not consume revision attempts or accept unchecked output", %{
    tmp_dir: dir
  } do
    source = Path.join(dir, "guide.txt")
    File.write!(source, "Hello")

    Mimic.expect(Translations, :translate_stream, fn _, _, _, _ ->
      {:ok, %{text: "Hola", model: "writer", provider: "test"}}
    end)

    assert {:error, {:decision_evaluation_failed, :decision_provider_unavailable}} =
             Engine.apply_item(item(source), %Account{id: 1}, fn _ -> :ok end, fn _, _ -> :ok end,
               decision_evaluator: fn _, _, _, _, _ ->
                 {:error, :decision_provider_unavailable}
               end
             )
  end

  test "unconfigured evaluation makes no provider call" do
    assert {:ok, nil} =
             Quality.assess(
               Map.delete(item(nil), :decision_model),
               %Account{id: 1},
               "Hello",
               "Hola",
               decision_evaluator: fn _, _, _, _, _ -> flunk("unexpected evaluator call") end
             )
  end
end
