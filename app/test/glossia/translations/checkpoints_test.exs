defmodule Glossia.Translations.CheckpointsTest do
  use Glossia.DataCase, async: true
  use Mimic
  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.{Checkpoints, Context, Engine, MarkdownUnits, Prompt}
  alias Glossia.TranslationStubs

  @tag :tmp_dir
  test "an interrupted Markdown repair reuses accepted units but not rejected responses", %{
    tmp_dir: dir
  } do
    source = Path.join(dir, "guide.md")
    File.write!(source, "Read the [guide](https://example.com).\n\nRun `mix test` now.\n")

    item = %{
      source_abs: source,
      output_abs: Path.join(dir, "es.md"),
      output_path: "es.md",
      locale: "es",
      language: "Spanish",
      source_language: "en",
      format: "markdown",
      frontmatter_mode: :preserve,
      preserve: [],
      prompt: nil,
      check_cmd: nil,
      check_cmds: %{},
      validation: nil,
      retries: 0,
      model: "translator",
      context_body: "",
      locale_override_body: "",
      server_context: Context.empty_bundle("es")
    }

    opts = [checkpoint_scope: Checkpoints.key({:markdown_resume, dir})]
    parent = self()

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      if payload["last_error"] do
        exit(:shutdown)
      else
        {:ok,
         %{
           text:
             TranslationStubs.respond(payload, fn
               "Read the <g1>guide</g1>." -> "Lee la <g1>guía</g1>."
               "Run <g1/> now." -> "Ejecuta ahora."
             end),
           model: "test/model",
           provider: "test"
         }}
      end
    end)

    validate = fn output, original ->
      Glossia.Translations.Validate.validate_output(dir, "markdown", output, original)
    end

    supervisor = start_supervised!(Task.Supervisor)

    interrupted =
      Task.Supervisor.async_nolink(supervisor, fn ->
        Engine.apply_item(item, %Account{id: "account"}, fn _ -> :ok end, validate, opts)
      end)

    assert {:exit, :shutdown} = Task.yield(interrupted, 5_000)

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      text =
        if payload["segment_kind"] == "markdown_unit" do
          send(parent, {:resumed_units, [payload["source_content"]]})
          "Ejecuta <g1/> ahora."
        else
          ~s({"u2":"Ejecuta "ahora"."})
        end

      {:ok,
       %{
         text: text,
         model: "test/model",
         provider: "test"
       }}
    end)

    resumed =
      Task.Supervisor.async_nolink(supervisor, fn ->
        # Stop after every unit is accepted but before the whole-segment
        # checkpoint is written, as supersession can do at any point.
        Engine.apply_item(
          item,
          %Account{id: "account"},
          fn
            {:segment_output, _} -> exit(:shutdown)
            _ -> :ok
          end,
          validate,
          opts
        )
      end)

    assert {:exit, :shutdown} = Task.yield(resumed, 5_000)
    assert_received {:resumed_units, ["Run <g1/> now."]}
    refute_received {:resumed_units, _}

    assert {:ok, result} =
             Engine.apply_item(item, %Account{id: "account"}, fn _ -> :ok end, validate, opts)

    assert result.text == "Lee la [guía](https://example.com).\n\nEjecuta `mix test` ahora.\n"
    refute_received {:resumed_units, _}

    # A fully checkpointed document still runs final validation on every resume.
    assert {:error, {:validation_failed, "external validation rejected output"}} =
             Engine.apply_item(
               item,
               %Account{id: "account"},
               fn _ -> :ok end,
               fn _, _ -> {:error, "external validation rejected output"} end,
               opts
             )

    refute_received {:resumed_units, _}

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      send(parent, {:repair_units, TranslationStubs.unit_texts(payload)})

      {:ok,
       %{
         text:
           TranslationStubs.respond(payload, fn
             "Read the <g1>guide</g1>." -> "Consulta la <g1>guía</g1>."
             "Run <g1/> now." -> "Ejecuta <g1/> ahora."
           end),
         model: "test/model",
         provider: "test"
       }}
    end)

    # A document-level repair must not silently replay the rejected attempt.
    validate_repair = fn output, original ->
      if String.starts_with?(output, "Lee"),
        do: {:error, "use Consulta instead"},
        else: validate.(output, original)
    end

    assert {:ok, repaired} =
             Engine.apply_item(
               %{item | retries: 1},
               %Account{id: "account"},
               fn _ -> :ok end,
               validate_repair,
               opts
             )

    assert repaired.text ==
             "Consulta la [guía](https://example.com).\n\nEjecuta `mix test` ahora.\n"

    assert_received {:repair_units, ["Read the <g1>guide</g1>.", "Run <g1/> now."]}
    refute_received {:repair_units, _}
  end

  @tag :tmp_dir
  test "corrected Markdown templates miss old checkpoints without purging unrelated documents", %{
    tmp_dir: dir
  } do
    source_text = "**Missing `source`.**\n"
    source = Path.join(dir, "glossary.md")
    File.write!(source, source_text)
    {:ok, fixed_plan} = MarkdownUnits.plan(source_text)
    [unit] = fixed_plan.units
    old_plan = %{fixed_plan | units: [%{unit | template: "<g1>.<g2/>Missing </g1>"}]}

    item = %{
      source_abs: source,
      output_abs: Path.join(dir, "es.md"),
      output_path: "es.md",
      locale: "es",
      language: "Spanish",
      source_language: "en",
      format: "markdown",
      frontmatter_mode: :preserve,
      preserve: [],
      prompt: nil,
      check_cmd: nil,
      check_cmds: %{},
      validation: nil,
      retries: 0,
      model: "translator",
      context_body: "",
      locale_override_body: "",
      server_context: Context.empty_bundle("es")
    }

    unrelated_source = Path.join(dir, "unrelated.md")
    File.write!(unrelated_source, "Hello, world.\n")
    unrelated_item = %{item | source_abs: unrelated_source}
    opts = [checkpoint_scope: Checkpoints.key({:templates, dir})]
    parent = self()

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      send(parent, {:translated_templates, TranslationStubs.unit_texts(payload)})

      {:ok,
       %{text: TranslationStubs.respond(payload, & &1), model: "test/model", provider: "test"}}
    end)

    stub(MarkdownUnits, :plan, fn
      ^source_text -> {:ok, old_plan}
      text -> Mimic.call_original(MarkdownUnits, :plan, [text])
    end)

    assert {:ok, _} =
             Engine.apply_item(
               item,
               %Account{id: "account"},
               fn _ -> :ok end,
               fn _, _ -> :ok end,
               opts
             )

    assert_receive {:translated_templates, ["<g1>.<g2/>Missing </g1>"]}

    assert {:ok, _} =
             Engine.apply_item(
               unrelated_item,
               %Account{id: "account"},
               fn _ -> :ok end,
               fn _, _ -> :ok end,
               opts
             )

    assert_receive {:translated_templates, ["Hello, world."]}

    stub(MarkdownUnits, :plan, fn text -> Mimic.call_original(MarkdownUnits, :plan, [text]) end)

    assert {:ok, _} =
             Engine.apply_item(
               item,
               %Account{id: "account"},
               fn _ -> :ok end,
               fn _, _ -> :ok end,
               opts
             )

    assert_receive {:translated_templates, ["<g1>Missing <g2/>.</g1>"]}

    assert {:ok, _} =
             Engine.apply_item(
               unrelated_item,
               %Account{id: "account"},
               fn _ -> :ok end,
               fn _, _ -> :ok end,
               opts
             )

    refute_receive {:translated_templates, _}
  end

  @tag :tmp_dir
  test "an interrupted catalog resumes validated batches in a new process", %{tmp_dir: dir} do
    source = Path.join(dir, "messages.pot")

    File.write!(
      source,
      Enum.map_join(1..12, "\n", fn n -> ~s(msgid "Message #{n}"\nmsgstr ""\n) end)
    )

    item = %{
      source_abs: source,
      output_abs: Path.join(dir, "es.po"),
      output_path: "es.po",
      locale: "es",
      language: "Spanish",
      source_language: "en",
      format: "po",
      frontmatter_mode: :preserve,
      preserve: [],
      prompt: nil,
      check_cmd: nil,
      check_cmds: %{},
      validation: nil,
      retries: 0,
      model: "translator",
      context_body: "",
      locale_override_body: "",
      server_context: Context.empty_bundle("es")
    }

    scope = Checkpoints.key({:test, dir})
    opts = [checkpoint_scope: scope]
    parent = self()

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      sources = JSON.decode!(payload["source_content"])
      # Exercise the real prompt builder as well as the engine contract.
      prompt =
        Prompt.build_system_prompt(%{
          format: "po",
          segment_kind: payload["segment_kind"],
          source_language: "en",
          language: "Spanish",
          locale: "es"
        })

      assert prompt =~ "Return ONLY a JSON array"
      send(parent, {:called, sources})

      if "Message 9" in sources do
        exit(:shutdown)
      else
        {:ok, %{text: JSON.encode!(sources), model: "test/model", provider: "test"}}
      end
    end)

    supervisor = start_supervised!(Task.Supervisor)

    interrupted =
      Task.Supervisor.async_nolink(supervisor, fn ->
        Engine.apply_item(
          item,
          %Account{id: "account"},
          fn _ -> :ok end,
          fn _, _ -> :ok end,
          opts
        )
      end)

    assert {:exit, :shutdown} = Task.yield(interrupted, 5_000)

    assert_received {:called, ["Message 1" | _]}
    assert_received {:called, ["Message 9" | _]}

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      sources = JSON.decode!(payload["source_content"])
      send(parent, {:resumed, sources})
      {:ok, %{text: JSON.encode!(sources), model: "test/model", provider: "test"}}
    end)

    task =
      Task.async(fn ->
        Engine.apply_item(
          item,
          %Account{id: "account"},
          fn _ -> :ok end,
          fn _, _ -> :ok end,
          opts
        )
      end)

    assert {:ok, result} = Task.await(task)
    assert result.text =~ ~s(msgstr "Message 12")
    assert_received {:resumed, ["Message 9" | _]}
    refute_received {:resumed, ["Message 1" | _]}

    # A changed effective input scope must not reuse the old response.
    assert {:ok, _} =
             Engine.apply_item(item, %Account{id: "account"}, fn _ -> :ok end, fn _, _ -> :ok end,
               checkpoint_scope: scope <> "changed"
             )

    assert_received {:resumed, ["Message 1" | _]}
  end

  @tag :tmp_dir
  test "malformed catalog arrays repair only the rejected batch and still pass final validation",
       %{tmp_dir: dir} do
    source = Path.join(dir, "dashboard.pot")

    File.write!(
      source,
      ~s(msgid ""\nmsgstr "Content-Type: text/plain; charset=UTF-8\\n"\n\nmsgid "Hello %{name}"\nmsgstr ""\n\nmsgid "Goodbye"\nmsgstr ""\n)
    )

    item = %{
      source_abs: source,
      output_abs: Path.join(dir, "es.po"),
      output_path: "es.po",
      locale: "es",
      language: "Spanish",
      source_language: "en",
      format: "po",
      frontmatter_mode: :preserve,
      preserve: [],
      prompt: nil,
      check_cmd: nil,
      check_cmds: %{},
      validation: nil,
      retries: 0,
      model: "translator",
      context_body: "",
      locale_override_body: "",
      server_context: Context.empty_bundle("es")
    }

    parent = self()

    stub(Translations, :translate_stream, fn _, payload, _, _ ->
      sources = JSON.decode!(payload["source_content"])
      send(parent, {:batch, sources})

      output =
        case sources do
          ["Hello %{name}", "Goodbye"] -> ~s(msgid "Hello"\nmsgstr "Hola")
          ["Hello %{name}"] -> JSON.encode!(["Hola %{name}"])
          ["Goodbye"] -> JSON.encode!(["Adiós"])
        end

      {:ok, %{text: output, model: "test/model", provider: "test"}}
    end)

    validate = fn output, original ->
      Glossia.Translations.Validate.validate_output(dir, "po", output, original)
    end

    assert {:ok, result} =
             Engine.apply_item(item, %Account{id: "account"}, fn _ -> :ok end, validate,
               checkpoint_scope: Checkpoints.key(dir)
             )

    assert result.text =~ "Language: es"
    assert result.text =~ "Hola %{name}"
    assert_received {:batch, ["Hello %{name}", "Goodbye"]}
    assert_received {:batch, ["Hello %{name}", "Goodbye"]}
    assert_received {:batch, ["Hello %{name}"]}
    assert_received {:batch, ["Goodbye"]}
    refute_received {:batch, _}
  end

  test "expired checkpoints are not read and are reclaimed" do
    key = Checkpoints.key(make_ref())
    result = %{text: "Hola", model: "test/model", provider: "test"}
    assert :ok = Checkpoints.write(key, result)
    assert Checkpoints.read(key) == result

    Repo.update_all(from(c in "translation_segment_checkpoints", where: c.key == ^key),
      set: [expires_at: DateTime.add(DateTime.utc_now(), -1, :day)]
    )

    assert Checkpoints.read(key) == nil
    Checkpoints.prune()
    refute Repo.exists?(from c in "translation_segment_checkpoints", where: c.key == ^key)
  end
end
