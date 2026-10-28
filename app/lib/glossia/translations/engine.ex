defmodule Glossia.Translations.Engine do
  @moduledoc """
  Turns a planned work item into translated output content.

  For a work item it reads the source, extracts frontmatter when present, and
  translates prose in bounded, format-neutral content segments. A format only
  supplies its segmentation policy, such as protected code-fence delimiters or
  an atomic structured document. Validation runs against the reassembled output
  and retries carry the previous error back to each segment.

  The actual model call goes through `Glossia.Translations.translate_stream/3`, so
  every attempt's turns are forwarded to `on_event` for live progress. Validation
  is pluggable via the `validate` function (defaults to always-ok until the
  `validate/` port lands).
  """

  @segment_attempts 2
  # A Markdown unit batch resends only the units that failed, so it can afford
  # one more round than a whole segment.
  @markdown_unit_attempts 3
  @markdown_unit_batch_size 40
  @markdown_unit_batch_bytes 6_000
  @markdown_unit_previous_bytes 4_000

  require Logger

  alias Glossia.Translations.Checkpoints
  alias Glossia.Translations.ContentSegments
  alias Glossia.Translations.Context
  alias Glossia.Translations
  alias Glossia.Translations.Format
  alias Glossia.Translations.Failure
  alias Glossia.Translations.Frontmatter
  alias Glossia.Translations.JsonArray
  alias Glossia.Translations.MarkdownUnits
  alias Glossia.Translations.NativeCatalog
  alias Glossia.Translations.Po
  alias Glossia.Translations.Quality
  alias Glossia.Translations.PreservedTokens

  @doc """
  Translates `work_item` for `account`, forwarding turn events to `on_event`.

  Returns `{:ok, %{text, output_path, output_abs, locale, model, provider}}` or
  `{:error, reason}`. `validate` receives the assembled output and returns `:ok`
  or `{:error, message}` to trigger a self-correcting retry.
  """
  def apply_item(
        work_item,
        account,
        on_event,
        validate \\ &default_validate/2,
        opts \\ []
      )
      when is_function(on_event, 1) and is_function(validate, 2) and is_list(opts) do
    case Map.fetch(work_item, :server_context) do
      {:ok, server_context} ->
        apply_item_with_context(work_item, account, on_event, validate, opts, server_context)

      :error ->
        {:error, :server_context_missing}
    end
  end

  defp apply_item_with_context(work_item, account, on_event, validate, opts, server_context) do
    case File.read(work_item.source_abs) do
      {:ok, source_text} ->
        preserve_kinds = PreservedTokens.resolve(work_item.preserve || [])

        with :ok <- Quality.preflight(work_item, source_text),
             translation when is_map(translation) <-
               prepare_translation(work_item, source_text, preserve_kinds) do
          {segments, context_budget} =
            attach_server_context(
              translation.segments,
              server_context,
              work_item.preserve || []
            )

          if context_budget_clipped?(context_budget) do
            on_event.({:context_budget, context_budget})
          end

          run_attempt(%{
            account: account,
            work_item: work_item,
            segments: segments,
            preserve_kinds: segment_preserve_kinds(work_item.format, preserve_kinds),
            protections: translation.protections,
            preserved_frontmatter: translation.preserved_frontmatter,
            markdown_plan: Map.get(translation, :markdown_plan),
            native_plan: Map.get(translation, :native_plan),
            source_text: source_text,
            on_event: on_event,
            validate: validate,
            attempt: 0,
            max_attempt: work_item.retries || 0,
            last_error: nil,
            translation_opts: opts
          })
        end

      {:error, reason} ->
        {:error, {:source_unreadable, reason}}
    end
  end

  defp run_attempt(%{attempt: attempt, max_attempt: max_attempt, last_error: last_error})
       when attempt > max_attempt do
    {:error, {:validation_failed, last_error || "translation failed"}}
  end

  defp run_attempt(state) do
    state.on_event.({:attempt_start, state.attempt + 1})

    case translate_segments(state) do
      {:ok, translated} ->
        masked_final = assemble_segments(state, translated.segments)

        case restore_protections(masked_final, state.protections) do
          {:ok, final} ->
            final = normalize_output(final, state.work_item)

            case state.validate.(final, state.source_text) do
              :ok ->
                assess_quality(state, final, translated)

              {:error, message} ->
                retry_validation(state, message, "output_validation")
            end

          {:error, message} ->
            retry_validation(state, message, "restore_protections")
        end

      {:validation_error, message} ->
        retry_validation(state, message, "segment_translation")

      {:preservation_error, message} ->
        log_validation_failure(state, message, "segment_recovery", false)
        {:error, {:validation_failed, message}}

      {:error, reason} ->
        {:error, {:llm_failed, reason}}
    end
  end

  defp assess_quality(state, final, translated) do
    case Quality.assess(
           state.work_item,
           state.account,
           state.source_text,
           final,
           state.translation_opts
         ) do
      {:ok, report} ->
        if report, do: state.on_event.({:quality_assessed, report})

        cond do
          report && Map.get(report, :human_input, "none") != "none" ->
            linguistic_input(
              state,
              final,
              report.human_input,
              Quality.question(report.human_input)
            )

          is_nil(report) or report.passed ->
            state.on_event.({:translation_output, final})

            {:ok,
             %{
               text: final,
               output_path: state.work_item.output_path,
               output_abs: state.work_item.output_abs,
               locale: state.work_item.locale,
               model: translated.model,
               provider: translated.provider,
               quality: report
             }}

          Map.get(state.work_item, :human_review, false) and state.attempt >= state.max_attempt ->
            linguistic_input(
              state,
              final,
              "quality_exhausted",
              "How should this translation be corrected? Automatic corrections exhausted their budget.\n\n" <>
                Quality.feedback(report)
            )

          true ->
            retry_validation(state, Quality.feedback(report), "translation_quality")
        end

      {:error, reason} ->
        {:error, {:decision_evaluation_failed, reason}}
    end
  end

  defp linguistic_input(state, final, reason, question) do
    {:error,
     {:linguistic_input_needed,
      %{
        reason: reason,
        question: question,
        source: state.source_text,
        translation: final
      }}}
  end

  defp translate_segments(state) do
    segment_count = length(state.segments)

    state.segments
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, %{segments: [], model: nil, provider: nil}}, fn
      {segment, segment_index}, {:ok, acc} ->
        segment = with_previous_unit_translations(state, segment, acc.segments)

        case translate_segment(state, segment, segment_index, segment_count, 1, state.last_error) do
          {:ok, text, result} ->
            {:cont,
             {:ok,
              %{
                segments: acc.segments ++ [%{kind: segment.kind, text: text}],
                model: result.model,
                provider: result.provider
              }}}

          {:error, reason} ->
            {:halt, {:error, reason}}

          {:preservation_error, message} ->
            {:halt, {:preservation_error, message}}
        end
    end)
  end

  # A long segment carrying many protected markers occasionally comes back with
  # one of them dropped or rewritten. Re-running that one segment, naming the
  # markers it lost, recovers far more cheaply than retranslating the document.
  # If that focused recovery runs out, stop there rather than repeatedly
  # translating segments whose output has already passed preservation checks.
  defp translate_segment(state, segment, index, count, attempt, last_error) do
    if segment.kind == "po_text_literals" and not Map.has_key?(segment, :po_source) do
      do_translate_segment(state, segment, index, count, attempt, last_error)
    else
      checkpoint(state, segment, {index, count, attempt, last_error}, fn ->
        do_translate_segment(state, segment, index, count, attempt, last_error)
      end)
    end
  end

  defp do_translate_segment(
         state,
         %{kind: "po_text_literals", po_source: _} = segment,
         index,
         count,
         _attempt,
         _error
       ) do
    translate_po_segment(state, segment, index, count)
  end

  defp do_translate_segment(
         state,
         %{kind: "markdown_units"} = segment,
         index,
         count,
         _attempt,
         _last_error
       ) do
    translate_markdown_units(state, segment, index, count)
  end

  defp do_translate_segment(state, segment, index, count, attempt, last_error) do
    translate_segment_with_model(state, segment, index, count, attempt, last_error)
  end

  defp checkpoint(state, segment, identity, translate, emit \\ true) do
    scope = Keyword.get(state.translation_opts, :checkpoint_scope)
    storage = if scope, do: state.translation_opts
    key = Checkpoints.key({1, scope, segment, identity, state.attempt, state.last_error})

    case Checkpoints.fetch(storage, key) do
      %{text: text, model: model, provider: provider} ->
        if emit do
          {index, count, _attempt, _last_error} = identity
          emit_segment_event(state, segment, {:segment_start, index, count, segment.kind})
          emit_segment_event(state, segment, {:segment_output, text})
        end

        {:ok, text, %{model: model, provider: provider}}

      nil ->
        case translate.() do
          {:ok, text, result} = success ->
            Checkpoints.put(storage, key, Map.put(result, :text, text))
            success

          other ->
            other
        end
    end
  end

  defp translate_po_segment(state, segment, index, count) do
    emit_segment_event(state, segment, {:segment_start, index, count, segment.kind})
    units = Map.get(segment, :po_stale_units, segment.po_units)

    {entries, headers, _offset} =
      Enum.reduce(units, {[], %{}, 0}, fn unit, {entries, headers, offset} ->
        if unit.header? do
          header = Po.localized_header(hd(unit.sources), state.work_item.locale)
          {entries, Map.put(headers, offset, header), offset + 1}
        else
          indexed = unit.sources |> Enum.with_index(offset)
          {entries ++ indexed, headers, offset + length(unit.sources)}
        end
      end)

    batches =
      Enum.chunk_while(
        entries,
        {[], 0},
        fn {text, _} = entry, {batch, bytes} ->
          if batch != [] and (length(batch) == 8 or bytes + byte_size(text) > 8_000) do
            {:cont, Enum.reverse(batch), {[entry], byte_size(text)}}
          else
            {:cont, {[entry | batch], bytes + byte_size(text)}}
          end
        end,
        fn
          {[], _} -> {:cont, []}
          {batch, _} -> {:cont, Enum.reverse(batch), {[], 0}}
        end
      )

    initial =
      {:ok, headers,
       %{model: state.work_item.model, provider: Map.get(state.work_item, :translation_provider)}}

    result =
      Enum.reduce_while(batches, initial, fn batch, {:ok, strings, _result} ->
        case translate_po_batch(state, segment, batch, index, count) do
          {:ok, translated, result} -> {:cont, {:ok, Map.merge(strings, translated), result}}
          error -> {:halt, error}
        end
      end)

    with {:ok, strings, result} <- result,
         decoded <- strings |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&elem(&1, 1)),
         {:ok, translations} <- assemble_po_translations(decoded, segment),
         {:ok, rebuilt} <- Po.rebuild_text_literals(segment.po_source, translations) do
      emit_segment_event(state, segment, {:segment_output, rebuilt})
      {:ok, rebuilt, result}
    else
      {:error, message} when is_binary(message) -> {:preservation_error, message}
      other -> other
    end
  end

  defp translate_po_batch(state, segment, entries, index, count, attempt \\ 1, last_error \\ nil) do
    sources = Enum.map(entries, &elem(&1, 0))

    batch =
      segment
      |> Map.delete(:po_source)
      |> Map.put(:content, JSON.encode!(sources))
      |> Map.put(:suppress_progress, true)
      |> Map.put(:suppress_stream_text, true)

    response =
      checkpoint(
        state,
        batch,
        {:catalog_batch, entries},
        fn ->
          with {:ok, text, result} <-
                 translate_segment_with_model(state, batch, index, count, 1, last_error),
               {:ok, decoded} <- decode_po_batch(text, sources) do
            {:ok, JSON.encode!(decoded), result}
          end
        end,
        false
      )

    case response do
      {:ok, text, result} ->
        translations =
          Enum.zip(entries, JSON.decode!(text))
          |> Map.new(fn {{_source, offset}, translation} -> {offset, translation} end)

        {:ok, translations, result}

      {:error, message} when is_binary(message) and attempt < @segment_attempts ->
        translate_po_batch(state, segment, entries, index, count, attempt + 1, message)

      {:error, message} when is_binary(message) and length(entries) > 1 ->
        {left, right} = Enum.split(entries, div(length(entries), 2))

        with {:ok, left, _} <- translate_po_batch(state, segment, left, index, count),
             {:ok, right, result} <- translate_po_batch(state, segment, right, index, count) do
          {:ok, Map.merge(left, right), result}
        end

      {:error, message} when is_binary(message) ->
        failure = Failure.from({:validation_failed, message})

        Logger.warning(
          "Translation catalog batch failed: #{JSON.encode!(%{event: "translation.catalog_batch_failed", translation_session_id: Map.get(state.work_item, :translation_session_id), output_path: state.work_item.output_path, literal_offset: entries |> hd() |> elem(1), literal_count: length(entries), validation_code: failure.validation_code})}"
        )

        {:preservation_error, message}

      other ->
        other
    end
  end

  defp decode_po_batch(text, sources) do
    with {:ok, decoded} <- JsonArray.decode(text) do
      cond do
        not Enum.all?(decoded, &is_binary/1) ->
          {:error, "po text-literal response must be a JSON array of strings"}

        length(decoded) != length(sources) ->
          {:error, "po text-literal response length did not match source count"}

        Enum.zip(sources, decoded)
        |> Enum.any?(fn {source, output} ->
          String.trim(source) != "" and String.trim(output) == ""
        end) ->
          {:error, "po text-literal response contained an empty translation"}

        Enum.zip(sources, decoded)
        |> Enum.any?(fn {source, output} ->
          Glossia.Translations.Validate.Po.validate_literal(source, output) != :ok
        end) ->
          {:error, "po text-literal response changed a placeholder"}

        true ->
          {:ok, decoded}
      end
    else
      _ -> {:error, "po text-literal response was not a valid JSON array"}
    end
  end

  defp translate_segment_with_model(state, segment, index, count, attempt, last_error) do
    emit_segment_event(state, segment, {:segment_start, index, count, segment.kind})

    payload =
      payload(
        state.work_item,
        segment.content,
        segment.server_context_body,
        not is_nil(state.preserved_frontmatter),
        last_error,
        segment.kind,
        index,
        count
      )

    case translate_stream(
           state.account,
           payload,
           segment_on_event(state, segment),
           state.translation_opts
         ) do
      {:ok, result} ->
        text =
          state.work_item.format
          |> strip_structured_code_fence(result.text)

        with :ok <- reject_empty_output(state, segment, text, index, count, attempt),
             {:ok, text} <- reconcile_segment(text, segment, state.work_item.format) do
          case unpreserved(state, segment, text) do
            unpreserved when unpreserved != [] and attempt < @segment_attempts ->
              # Deliberately no `segment_output`: progress folds that event into
              # the item's completed text, so announcing output we are about to
              # discard would leave the rejected and corrected text concatenated.
              message = preservation_error_message(unpreserved)
              emit_segment_event(state, segment, {:segment_retry, index, message})
              translate_segment(state, segment, index, count, attempt + 1, message)

            [] ->
              emit_segment_event(state, segment, {:segment_output, text})
              {:ok, text, result}

            unpreserved ->
              {:preservation_error, preservation_error_message(unpreserved)}
          end
        else
          {:error, message} when attempt < @segment_attempts ->
            emit_segment_event(state, segment, {:segment_retry, index, message})
            translate_segment(state, segment, index, count, attempt + 1, message)

          {:error, message} ->
            {:preservation_error, message}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp emit_segment_event(state, segment, event) do
    unless Map.get(segment, :suppress_progress, false), do: state.on_event.(event)
  end

  defp segment_on_event(state, %{suppress_stream_text: true}) do
    fn
      {:text, _chunk} -> :ok
      {:thinking, _chunk} -> :ok
      event -> state.on_event.(event)
    end
  end

  defp segment_on_event(state, _segment), do: state.on_event

  # Native values are checked individually before JSON encoding. Scanning the
  # encoded array instead makes escapes such as \n appear to be part of a URL.
  defp unpreserved(_state, %{kind: "native_text_literals"}, _text), do: []

  # Masked content is checked against the extraction plan's markers. Content
  # left visible to the model, such as a plain web address, is checked against
  # the segment source instead, so a model that localizes or drops an address is
  # corrected by one focused retry rather than by a whole extra document attempt
  # driven from the final validation step.
  defp unpreserved(state, segment, text) do
    unpreserved_markers(
      state.protections ++ Map.get(segment, :protections, []),
      segment.content,
      text
    ) ++
      PreservedTokens.unpreserved_values(segment.content, text, state.preserve_kinds)
  end

  defp reject_empty_output(state, %{content: source} = segment, output, index, count, attempt) do
    if String.trim(source) != "" and String.trim(output) == "" do
      message = empty_output_message(segment.kind)
      log_empty_output(state, segment, output, index, count, attempt, message)
      {:error, message}
    else
      :ok
    end
  end

  defp empty_output_message(kind) when kind in ["frontmatter", "frontmatter_text_literals"] do
    "translated output was empty for non-empty frontmatter; return the complete frontmatter block with its syntax and delimiters intact"
  end

  defp empty_output_message(_kind), do: "translated output was empty for non-empty source content"

  # A model's response can be empty without producing a provider error, which
  # otherwise left the server logs with only the final, session-level failure.
  # Keep enough operational context to investigate the failed request while
  # deliberately excluding source text, model output, credentials, and provider
  # response payloads.
  defp log_empty_output(state, segment, output, index, count, attempt, message) do
    work_item = state.work_item

    details = %{
      "event" => "translation.empty_output",
      "translation_session_id" => Map.get(work_item, :translation_session_id),
      "source_path" => Map.get(work_item, :source_path),
      "output_path" => Map.get(work_item, :output_path),
      "locale" => Map.get(work_item, :locale),
      "format" => Map.get(work_item, :format),
      "frontmatter_mode" => to_string(Map.get(work_item, :frontmatter_mode)),
      "model" => Map.get(work_item, :model),
      "provider" => Map.get(work_item, :translation_provider),
      "segment_kind" => segment.kind,
      "segment_index" => index,
      "segment_count" => count,
      "segment_attempt" => attempt,
      "segment_attempt_limit" => @segment_attempts,
      "source_bytes" => byte_size(segment.content),
      "output_bytes" => byte_size(output),
      "validation_message" => message
    }

    Logger.warning("Translation model returned empty output: #{JSON.encode!(details)}")
  end

  defp unpreserved_markers(protections, segment_content, text) do
    Enum.flat_map(
      protections,
      &PreservedTokens.unpreserved_markers(&1, segment_content, text)
    )
  end

  # `Glossia.Translations.Validate` exempts PO output from preserved-value
  # checks, where the catalog structure rather than the prose carries the
  # protected values. The per-segment check follows the same policy.
  defp segment_preserve_kinds("po", _kinds), do: []
  defp segment_preserve_kinds(_format, kinds), do: kinds

  defp preservation_error_message(values) do
    "these protected token markers and web addresses must be copied byte-for-byte exactly once: " <>
      Enum.join(values, ", ")
  end

  defp assemble_segments(%{native_plan: plan}, translated_segments) when not is_nil(plan) do
    values = Enum.flat_map(translated_segments, &JSON.decode!(&1.text))
    NativeCatalog.splice(plan, values)
  end

  defp assemble_segments(state, translated_segments) do
    {frontmatter_segments, body_segments} =
      Enum.split_with(translated_segments, &frontmatter_segment?/1)

    frontmatter =
      state.preserved_frontmatter ||
        case frontmatter_segments do
          [%{text: text} | _] -> String.trim(text)
          [] -> nil
        end

    case state.markdown_plan do
      nil ->
        body =
          body_segments
          |> Enum.map(&String.trim(&1.text))
          |> Enum.reject(&(&1 == ""))
          |> Enum.join("\n\n")

        frontmatter
        |> reassemble(body)
        |> String.trim_trailing()

      plan ->
        # The body is the source with its prose replaced, byte for byte
        # everywhere else, including blank lines and the final newline.
        rendered =
          body_segments
          |> Enum.flat_map(&(&1.text |> JSON.decode!() |> Map.fetch!("rendered")))
          |> Map.new()

        output = reassemble(frontmatter, MarkdownUnits.splice(plan, rendered))

        if String.ends_with?(state.source_text, "\n") and not String.ends_with?(output, "\n"),
          do: output <> "\n",
          else: output
    end
  end

  defp translate_stream(account, payload, on_event, []) do
    Translations.translate_stream(account, payload, on_event)
  end

  defp translate_stream(account, payload, on_event, opts) do
    Translations.translate_stream(account, payload, on_event, opts)
  end

  defp retry_validation(state, message, stage) do
    message = to_string(message)
    log_validation_failure(state, message, stage, state.attempt < state.max_attempt)
    state.on_event.({:validation_error, message})
    run_attempt(%{state | attempt: state.attempt + 1, last_error: message})
  end

  defp log_validation_failure(state, message, stage, retrying) do
    failure = Failure.from({:validation_failed, message})
    item = state.work_item

    details = %{
      "event" => "translation.validation_failed",
      "translation_session_id" => Map.get(item, :translation_session_id),
      "source_path" => Map.get(item, :source_path),
      "output_path" => item.output_path,
      "locale" => item.locale,
      "format" => item.format,
      "validation_stage" => stage,
      "validation_code" => failure.validation_code,
      "validation_message" => failure.validation_message,
      "validation_exit_status" => Map.get(failure, :validation_exit_status),
      "document_attempt" => state.attempt + 1,
      "document_attempt_limit" => state.max_attempt + 1,
      "retrying" => retrying
    }

    Logger.warning("Translation validation failed: #{JSON.encode!(details)}")
  end

  defp restore_protections(text, protections) do
    Enum.reduce_while(protections, {:ok, text}, fn protection, {:ok, current} ->
      case PreservedTokens.restore(current, protection) do
        {:ok, restored} -> {:cont, {:ok, restored}}
        {:error, _message} = error -> {:halt, error}
      end
    end)
  end

  @doc false
  def prepare(%{format: "markdown", frontmatter_mode: :preserve}, source_text) do
    case Frontmatter.split_markdown_frontmatter(source_text) do
      %{ok: true, frontmatter: frontmatter, body: body} -> {frontmatter, body}
      _ -> {nil, source_text}
    end
  end

  def prepare(_work_item, source_text), do: {nil, source_text}

  defp prepare_translation(%{format: "markdown"} = work_item, source_text, preserve_kinds) do
    split = Frontmatter.split_markdown_frontmatter(source_text)

    case {work_item.frontmatter_mode, split.ok} do
      {:preserve, true} ->
        split.body
        |> markdown_body_segments(preserve_kinds, "body")
        |> Map.put(:preserved_frontmatter, split.frontmatter)

      {:translate, true} ->
        translated_frontmatter_segments(split.frontmatter, preserve_kinds, split.body)

      _ ->
        source_text
        |> markdown_body_segments(preserve_kinds, "document")
        |> Map.put(:preserved_frontmatter, nil)
    end
  end

  # `.po` catalogs use a strict Gettext syntax the model regularly gets wrong
  # when asked to output raw catalog text (`catalog-syntax`,
  # `catalog-source-entries`, orphan-msgstr, plural-forms mismatch, etc.).
  # Instead, extract the translatable strings from the source catalog, hand
  # the model only the string set as a JSON array, and rebuild the catalog
  # from the parsed source tree in `reconcile_segment/3`.
  #
  # A `po_diff` on the work item means the planner detected some msgids as
  # already translated in the current output. Only the stale msgids' sources
  # are sent to the model; the rest are carried through as preserved msgstrs
  # from the existing output PO.
  defp prepare_translation(%{format: "po"} = work_item, source_text, _preserve_kinds) do
    {:ok, units} = Po.translation_units(source_text)

    case Map.get(work_item, :po_diff) do
      %{stale_keys: stale_keys, preserved: preserved} when stale_keys != [] ->
        prepare_po_partial_segment(source_text, units, stale_keys, preserved)

      _ ->
        prepare_po_full_segment(source_text, units)
    end
  end

  defp prepare_translation(work_item, source_text, preserve_kinds) do
    case NativeCatalog.plan(work_item.source_abs, source_text) do
      nil ->
        {segments, protections} =
          planned_content_segments(source_text, work_item.format, preserve_kinds, "document")

        %{preserved_frontmatter: nil, segments: segments, protections: protections}

      {:error, _reason} = error ->
        error

      plan ->
        segments =
          plan.values
          |> Enum.map(&elem(&1, 2))
          |> Enum.chunk_every(8)
          |> Enum.map(fn values ->
            %{
              kind: "native_text_literals",
              content: JSON.encode!(values),
              native_values: values,
              preserve_kinds: preserve_kinds
            }
          end)

        %{preserved_frontmatter: nil, segments: segments, protections: [], native_plan: plan}
    end
  end

  defp prepare_po_full_segment(source_text, units) do
    literals = Enum.flat_map(units, & &1.sources)

    segment = %{
      kind: "po_text_literals",
      content: JSON.encode!(literals),
      po_source: source_text,
      po_units: units,
      po_preserved: %{}
    }

    %{preserved_frontmatter: nil, segments: [segment], protections: []}
  end

  defp prepare_po_partial_segment(source_text, units, stale_keys, preserved) do
    units_by_key = Map.new(units, &{&1.key, &1})

    # Preserve stale_keys' order for a deterministic segment payload; a stale
    # key that no longer appears in the current source (e.g., the msgid was
    # deleted between runs) is dropped rather than sent to the model.
    stale_units =
      stale_keys
      |> Enum.map(&Map.get(units_by_key, &1))
      |> Enum.reject(&is_nil/1)

    literals = Enum.flat_map(stale_units, & &1.sources)

    segment = %{
      kind: "po_text_literals",
      content: JSON.encode!(literals),
      po_source: source_text,
      po_units: units,
      po_stale_units: stale_units,
      po_preserved: preserved
    }

    %{preserved_frontmatter: nil, segments: [segment], protections: []}
  end

  # Markdown source structure is reassembled after translation. Link
  # destinations and code therefore never need opaque markers or a model round
  # trip. Placeholders remain opaque, including placeholders inside a link
  # destination. Other formats continue to use their existing format-neutral
  # plan.
  # ── Markdown units ────────────────────────────────────────────────────────
  #
  # Markdown is translated as units of prose spliced back into the source
  # bytes (see `Glossia.Translations.MarkdownUnits`). A document the parser
  # cannot read keeps the older segment path.
  defp markdown_body_segments(body, preserve_kinds, scope) do
    case MarkdownUnits.plan(body) do
      {:ok, plan} ->
        %{
          segments: markdown_unit_segments(plan, preserve_kinds),
          protections: [],
          markdown_plan: plan
        }

      {:error, _reason} ->
        {segments, protections} =
          planned_content_segments(body, "markdown", preserve_kinds, scope)

        %{segments: segments, protections: protections, markdown_plan: nil}
    end
  end

  defp markdown_unit_segments(plan, preserve_kinds) do
    plan.units
    |> Enum.map(fn unit ->
      protection =
        PreservedTokens.protect(unit.template, preserve_kinds,
          scope: "markdown_unit_#{unit.id}",
          mask_urls: true
        )

      Map.merge(unit, %{protection: protection, text: protection.text})
    end)
    |> batch_markdown_units()
    |> Enum.map(fn units ->
      %{
        kind: "markdown_units",
        content: markdown_units_content(units),
        units: units,
        source_context: MarkdownUnits.context(plan, units),
        suppress_stream_text: true
      }
    end)
  end

  defp batch_markdown_units(units) do
    units
    |> Enum.chunk_while(
      {[], 0},
      fn unit, {current, bytes} ->
        size = byte_size(unit.text)

        if current != [] and
             (length(current) >= @markdown_unit_batch_size or
                bytes + size > @markdown_unit_batch_bytes) do
          {:cont, Enum.reverse(current), {[unit], size}}
        else
          {:cont, {[unit | current], bytes + size}}
        end
      end,
      fn
        {[], _bytes} -> {:cont, {[], 0}}
        {current, _bytes} -> {:cont, Enum.reverse(current), {[], 0}}
      end
    )
  end

  defp markdown_units_content(units),
    do: units |> Enum.map(&%{"id" => &1.id, "text" => &1.text}) |> JSON.encode!()

  # Batches are translated in order. Each one carries the most recent
  # translations of the batches before it, so terminology and tone stay
  # consistent across a long document.
  defp with_previous_unit_translations(
         %{markdown_plan: %{units: plan_units}},
         %{kind: "markdown_units"} = segment,
         translated_segments
       ) do
    sources = Map.new(plan_units, &{&1.id, &1.template})

    previous =
      translated_segments
      |> Enum.filter(&(&1.kind == "markdown_units"))
      |> Enum.flat_map(fn %{text: text} ->
        text |> JSON.decode!() |> Map.fetch!("translated") |> Enum.sort_by(&unit_order/1)
      end)
      |> Enum.map(fn {id, translated} -> "#{Map.fetch!(sources, id)}\n=> #{translated}" end)
      |> Enum.reverse()
      |> Enum.reduce_while({[], 0}, fn entry, {kept, bytes} ->
        size = byte_size(entry)

        if bytes + size > @markdown_unit_previous_bytes,
          do: {:halt, {kept, bytes}},
          else: {:cont, {[entry | kept], bytes + size}}
      end)
      |> elem(0)

    Map.put(segment, :previous_translations, previous)
  end

  defp with_previous_unit_translations(_state, segment, _translated_segments), do: segment

  defp unit_order({"u" <> number, _value}), do: String.to_integer(number)

  defp translate_markdown_units(state, segment, index, count) do
    emit_segment_event(state, segment, {:segment_start, index, count, segment.kind})

    # A batch can accept most units before a retry or supersession stops it.
    # Recover those units independently of the pending subset and retry feedback.
    {pending, accepted, result} =
      Enum.reduce(segment.units, {[], %{}, nil}, fn unit, {pending, accepted, result} ->
        {storage, key} = markdown_unit_checkpoint(state, segment, unit)

        with %{text: text} = cached <- Checkpoints.fetch(storage, key),
             {:ok, rendered, translated} <- accept_markdown_unit(state.markdown_plan, unit, text) do
          {pending, Map.put(accepted, unit.id, %{rendered: rendered, translated: translated}),
           cached}
        else
          _ -> {[unit | pending], accepted, result}
        end
      end)

    outcome =
      if pending == [] do
        {:ok, accepted, result}
      else
        translate_markdown_unit_rounds(
          state,
          segment,
          index,
          count,
          Enum.reverse(pending),
          accepted,
          nil,
          1
        )
      end

    case outcome do
      {:ok, accepted, result} ->
        rendered = Map.new(accepted, fn {id, %{rendered: bytes}} -> {id, bytes} end)

        case MarkdownUnits.check(state.markdown_plan, rendered) do
          :ok ->
            translated = Map.new(accepted, fn {id, %{translated: text}} -> {id, text} end)
            preview = segment.units |> Enum.map(&Map.fetch!(rendered, &1.id)) |> Enum.join("\n\n")
            emit_segment_event(state, segment, {:segment_output, preview})

            {:ok, JSON.encode!(%{"rendered" => rendered, "translated" => translated}), result}

          {:error, message} ->
            {:preservation_error, message}
        end

      other ->
        other
    end
  end

  # One round asks the model for every pending unit. Units that come back
  # valid are kept; only the ones that failed are sent again, with the reason,
  # so a single bad unit never costs a retranslation of the whole batch.
  defp translate_markdown_unit_rounds(
         state,
         segment,
         index,
         count,
         pending,
         accepted,
         last_error,
         round
       ) do
    content =
      if segment.kind == "markdown_unit",
        do: hd(pending).text,
        else: markdown_units_content(pending)

    request = %{segment | content: content}

    payload =
      state.work_item
      |> payload(
        request.content,
        segment.server_context_body,
        not is_nil(state.preserved_frontmatter),
        last_error,
        segment.kind,
        index,
        count
      )
      |> Map.put("source_context", markdown_units_context(segment))

    case translate_stream(
           state.account,
           payload,
           segment_on_event(state, segment),
           state.translation_opts
         ) do
      {:ok, result} ->
        decoded =
          if segment.kind == "markdown_unit",
            do: %{hd(pending).id => result.text},
            else: decode_markdown_units(result.text)

        {accepted, failures} =
          accept_markdown_units(decoded, state, segment, pending, accepted, result)

        cond do
          failures == [] ->
            {:ok, accepted, result}

          round < @markdown_unit_attempts ->
            message = markdown_unit_failure_message(failures)
            emit_segment_event(state, segment, {:segment_retry, index, message})
            failed = MapSet.new(failures, &elem(&1, 0))
            pending = Enum.filter(pending, &MapSet.member?(failed, &1.id))

            translate_markdown_unit_rounds(
              state,
              segment,
              index,
              count,
              pending,
              accepted,
              message,
              round + 1
            )

          true ->
            failed = MapSet.new(failures, &elem(&1, 0))
            pending = Enum.filter(pending, &MapSet.member?(failed, &1.id))
            message = markdown_unit_failure_message(failures)

            if length(pending) > 1 do
              # A model can repeatedly omit units in a large response. As with
              # catalogs, shrink only the rejected group, down to single units.
              # Reset feedback so it cannot request ids outside the new group.
              {left, right} = Enum.split(pending, div(length(pending), 2))
              emit_segment_event(state, segment, {:segment_retry, index, message})

              with {:ok, accepted, _result} <-
                     translate_markdown_unit_rounds(
                       state,
                       segment,
                       index,
                       count,
                       left,
                       accepted,
                       nil,
                       1
                     ),
                   {:ok, accepted, result} <-
                     translate_markdown_unit_rounds(
                       state,
                       segment,
                       index,
                       count,
                       right,
                       accepted,
                       nil,
                       1
                     ) do
                {:ok, accepted, result}
              else
                {:preservation_error, _} -> {:preservation_error, message}
                error -> error
              end
            else
              if decoded == :invalid_json or match?([{_, "missing from the response"}], failures) do
                # One unit needs neither a JSON envelope nor an id. Recover
                # malformed JSON and omitted ids while still validating the
                # complete text and tags exactly as in the batched path.
                translate_markdown_unit_rounds(
                  state,
                  %{segment | kind: "markdown_unit"},
                  index,
                  count,
                  pending,
                  accepted,
                  nil,
                  1
                )
              else
                {:preservation_error, message}
              end
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp markdown_units_context(segment) do
    previous =
      case Map.get(segment, :previous_translations, []) do
        [] ->
          ""

        entries ->
          "\n\nAlready translated earlier in this document:\n\n" <> Enum.join(entries, "\n\n")
      end

    segment.source_context <> previous
  end

  defp decode_markdown_units(text) do
    if String.trim(text) == "", do: :empty, else: decode_markdown_units_object(text)
  end

  defp decode_markdown_units_object(text) do
    text
    |> String.trim()
    |> strip_fence()
    |> then(fn text ->
      case {:binary.match(text, "{"), :binary.matches(text, "}")} do
        {{start, _}, [_ | _] = closings} ->
          {stop, _} = List.last(closings)
          binary_part(text, start, stop - start + 1)

        _ ->
          text
      end
    end)
    |> JSON.decode()
    |> case do
      {:ok, %{} = map} -> map
      _ -> :invalid_json
    end
  end

  defp markdown_unit_checkpoint(state, segment, unit) do
    scope = Keyword.get(state.translation_opts, :checkpoint_scope)
    storage = if scope, do: state.translation_opts
    segment = %{segment | kind: "markdown_units"}

    key =
      Checkpoints.key({:markdown_unit, 1, scope, segment, unit, state.attempt, state.last_error})

    {storage, key}
  end

  defp accept_markdown_units(:empty, _state, _segment, pending, accepted, _result) do
    message = empty_output_message("markdown_units")
    {accepted, Enum.map(pending, &{&1.id, message})}
  end

  defp accept_markdown_units(:invalid_json, _state, _segment, pending, accepted, _result) do
    message =
      "Markdown unit response must be a valid JSON object mapping the requested ids to translated strings; escape double quotes and backslashes inside strings"

    {accepted, Enum.map(pending, &{&1.id, message})}
  end

  defp accept_markdown_units(translations, state, segment, pending, accepted, result) do
    Enum.reduce(pending, {accepted, []}, fn unit, {accepted, failures} ->
      text = Map.get(translations, unit.id)

      case accept_markdown_unit(state.markdown_plan, unit, text) do
        {:ok, rendered, translated} ->
          {storage, key} = markdown_unit_checkpoint(state, segment, unit)
          Checkpoints.put(storage, key, Map.put(result, :text, text))
          {Map.put(accepted, unit.id, %{rendered: rendered, translated: translated}), failures}

        {:error, message} ->
          {accepted, failures ++ [{unit.id, message}]}
      end
    end)
  end

  defp accept_markdown_unit(_plan, _unit, nil), do: {:error, "missing from the response"}

  defp accept_markdown_unit(plan, unit, translated) when is_binary(translated) do
    with false <- String.trim(translated) == "",
         {:ok, restored} <- PreservedTokens.restore(translated, unit.protection),
         {:ok, rendered} <- MarkdownUnits.render(unit, restored) do
      # A translation that happens to contain Markdown punctuation can change
      # the document's structure. Escaping that unit's prose fixes it without
      # touching any syntax restored from the source.
      with {:error, _message} <- MarkdownUnits.check(plan, %{unit.id => rendered}),
           {:ok, escaped} <- MarkdownUnits.render(unit, restored, escape: true),
           :ok <- MarkdownUnits.check(plan, %{unit.id => escaped}) do
        {:ok, escaped, restored}
      else
        :ok -> {:ok, rendered, restored}
        {:error, message} -> {:error, message}
      end
    else
      true -> {:error, "the translation is empty"}
      {:error, message} -> {:error, message}
    end
  end

  defp accept_markdown_unit(_plan, _unit, _translated), do: {:error, "must be a string"}

  # Grouped by reason, reason first, so the failure is classified by what went
  # wrong and the model's retry feedback still names every affected unit.
  defp markdown_unit_failure_message(failures) do
    failures
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
    |> Enum.sort_by(fn {_message, [first | _]} -> unit_order({first, nil}) end)
    |> Enum.map_join("; ", fn {message, ids} -> "#{message} (#{Enum.join(ids, ", ")})" end)
  end

  defp planned_content_segments(content, "markdown", preserve_kinds, scope) do
    protection =
      PreservedTokens.protect(content, Enum.filter(preserve_kinds, &(&1 == "placeholders")),
        scope: scope
      )

    {content_segments(protection.text, "markdown"), [protection]}
  end

  defp planned_content_segments(content, format, preserve_kinds, scope) do
    protection = PreservedTokens.protect(content, preserve_kinds, scope: scope)
    {content_segments(protection.text, format), [protection]}
  end

  defp reconcile_segment(text, %{kind: "frontmatter"}, _format), do: {:ok, text}

  defp reconcile_segment(
         text,
         %{kind: "frontmatter_text_literals", frontmatter_plan: plan},
         "markdown"
       ),
       do: Frontmatter.rebuild_nimble_publisher_text_literals(plan, text)

  defp reconcile_segment(
         text,
         %{kind: "native_text_literals", native_values: values, preserve_kinds: kinds},
         _format
       ),
       do: NativeCatalog.decode_values(text, values, kinds)

  # Model returns a JSON array of translated strings — one per source literal
  # in the shipped payload. In the full-file case the array covers every unit
  # in order. In the partial case the array only covers stale msgids; the
  # unchanged units' msgstrs are merged in from the previous output before
  # rebuilding the canonical `.po` from the source tree.
  defp reconcile_segment(
         text,
         %{kind: "po_text_literals", po_source: source} = segment,
         "po"
       ) do
    with {:ok, decoded} <- JsonArray.decode(text),
         true <- Enum.all?(decoded, &is_binary/1),
         {:ok, translations} <- assemble_po_translations(decoded, segment),
         {:ok, rebuilt} <- Po.rebuild_text_literals(source, translations) do
      {:ok, rebuilt}
    else
      false ->
        {:error, "po text-literal response must be a JSON array of strings"}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      _ ->
        {:error, "po text-literal response was not a valid JSON array"}
    end
  end

  defp reconcile_segment(text, _segment, _format), do: {:ok, text}

  # Rebuild the flat, in-source-order translation list from either the
  # stale-only model response plus preserved msgstrs, or from the whole-file
  # model response directly.
  defp assemble_po_translations(decoded, %{
         po_units: units,
         po_stale_units: stale_units,
         po_preserved: preserved
       }) do
    with {:ok, translated_by_key} <- distribute_po_translations(stale_units, decoded) do
      merged = Map.merge(preserved, translated_by_key)
      units_translations_in_order(units, merged)
    end
  end

  defp assemble_po_translations(decoded, _segment), do: {:ok, decoded}

  defp distribute_po_translations(stale_units, decoded) do
    expected = Enum.reduce(stale_units, 0, fn unit, acc -> acc + length(unit.sources) end)

    if length(decoded) != expected do
      {:error,
       "po text-literal response length #{length(decoded)} did not match stale-msgid literal count #{expected}"}
    else
      {by_key, []} =
        Enum.map_reduce(stale_units, decoded, fn unit, remaining ->
          {take, rest} = Enum.split(remaining, length(unit.sources))
          {{unit.key, take}, rest}
        end)

      {:ok, Map.new(by_key)}
    end
  end

  defp units_translations_in_order(units, translations_by_key) do
    Enum.reduce_while(units, {:ok, []}, fn unit, {:ok, acc} ->
      case Map.fetch(translations_by_key, unit.key) do
        {:ok, translations} when is_list(translations) ->
          # Preservation aligns the target-shape output back to source shape
          # before it lands here, so a length skew at this point is a
          # programming error, not a data one. Return a preservation-scoped
          # error rather than raising: `{:preservation_error, _}` fails only
          # the current file and stays inside the existing telemetry path,
          # while a `raise` would take down the translation Job.
          if length(translations) == length(unit.sources) do
            {:cont, {:ok, acc ++ translations}}
          else
            {:halt,
             {:error,
              "po text-literal response length #{length(translations)} did not match source shape #{length(unit.sources)} for msgid #{unit.key}"}}
          end

        _ ->
          {:halt,
           {:error, "po text-literal response was missing translations for msgid #{unit.key}"}}
      end
    end)
  end

  defp content_segments(content, format) do
    case Format.segmentation(format) do
      :atomic ->
        [%{kind: "content", content: content}]

      {:segmented, opts} ->
        case ContentSegments.split(content, opts) do
          [] -> [%{kind: "content", content: ""}]
          segments -> Enum.map(segments, &%{kind: "content", content: &1})
        end
    end
  end

  defp translated_frontmatter_segments(frontmatter, preserve_kinds, body) do
    %{segments: body_segments, protections: body_protections, markdown_plan: markdown_plan} =
      markdown_body_segments(body, preserve_kinds, "body")

    case Frontmatter.nimble_publisher_text_literals(frontmatter) do
      {:ok, plan} ->
        protection =
          plan.values
          |> JSON.encode!()
          |> PreservedTokens.protect(preserve_kinds, scope: "frontmatter_literals")

        %{
          preserved_frontmatter: nil,
          markdown_plan: markdown_plan,
          segments:
            [
              %{
                kind: "frontmatter_text_literals",
                content: protection.text,
                frontmatter_plan: plan
              }
            ] ++ body_segments,
          protections: [protection | body_protections]
        }

      :error ->
        protection = PreservedTokens.protect(frontmatter, preserve_kinds, scope: "frontmatter")

        %{
          preserved_frontmatter: nil,
          markdown_plan: markdown_plan,
          segments: [%{kind: "frontmatter", content: protection.text}] ++ body_segments,
          protections: [protection | body_protections]
        }
    end
  end

  defp frontmatter_segment?(%{kind: kind})
       when kind in ["frontmatter", "frontmatter_text_literals"],
       do: true

  defp frontmatter_segment?(_segment), do: false

  defp attach_server_context(segments, server_context, preserve) do
    initial_budget = %{
      segments: length(segments),
      segments_with_glossary_omissions: 0,
      glossary_matched: 0,
      glossary_included: 0,
      glossary_omitted: 0,
      glossary_definitions_omitted: 0,
      voice_truncated: false
    }

    Enum.map_reduce(segments, initial_budget, fn segment, budget ->
      prompt = Context.prompt(server_context, segment.content, preserve)
      segment = Map.put(segment, :server_context_body, prompt.body)
      {segment, merge_context_budget(budget, prompt.budget)}
    end)
  end

  defp merge_context_budget(total, segment) do
    segment_has_omissions =
      segment.glossary_omitted > 0 or segment.glossary_definitions_omitted > 0

    %{
      total
      | segments_with_glossary_omissions:
          total.segments_with_glossary_omissions + if(segment_has_omissions, do: 1, else: 0),
        glossary_matched: total.glossary_matched + segment.glossary_matched,
        glossary_included: total.glossary_included + segment.glossary_included,
        glossary_omitted: total.glossary_omitted + segment.glossary_omitted,
        glossary_definitions_omitted:
          total.glossary_definitions_omitted + segment.glossary_definitions_omitted,
        voice_truncated: total.voice_truncated or segment.voice_truncated
    }
  end

  defp context_budget_clipped?(budget) do
    budget.voice_truncated or budget.glossary_omitted > 0 or
      budget.glossary_definitions_omitted > 0
  end

  @doc false
  def reassemble(nil, stripped), do: stripped

  def reassemble(frontmatter, stripped) do
    if String.trim(stripped) == "" do
      "#{frontmatter}\n"
    else
      "#{frontmatter}\n#{stripped}"
    end
  end

  @doc """
  Removes a leading/trailing ```` ``` ```` fence from structured-format output.

  Only applies to structured formats (json/yaml/po); prose output is returned
  unchanged, as is any text not fully fenced.
  """
  def strip_structured_code_fence(format, text) do
    if Format.structured?(format) do
      strip_fence(text)
    else
      text
    end
  end

  defp strip_fence(text) do
    trimmed = String.trim(text)

    if String.starts_with?(trimmed, "```") and String.ends_with?(trimmed, "```") do
      [_opening | rest] =
        trimmed |> String.split("\n") |> Enum.map(&String.trim_trailing(&1, "\r"))

      if List.last(rest) == "```" do
        rest |> Enum.drop(-1) |> Enum.join("\n")
      else
        text
      end
    else
      text
    end
  end

  defp payload(
         work_item,
         content,
         server_context_body,
         frontmatter_preserved,
         last_error,
         segment_kind,
         segment_index,
         segment_count
       ) do
    %{
      "model" => work_item.model,
      "project_id" => Map.get(work_item, :project_id),
      "source_path" => Map.get(work_item, :source_path),
      "format" => work_item.format,
      "source_language" => work_item.source_language,
      "language" => work_item.language,
      "locale" => work_item.locale,
      "source_content" => content,
      "context_body" => work_item.context_body,
      "locale_override_body" => work_item.locale_override_body,
      "server_context_body" => server_context_body,
      "custom_prompt" => work_item.prompt,
      "frontmatter_preserved" => frontmatter_preserved,
      "last_error" => last_error,
      "segment_kind" => segment_kind,
      "segment_index" => segment_index,
      "segment_count" => segment_count
    }
  end

  # A catalog's plural arity follows from the target language, not from the
  # translation, so the engine settles it rather than retrying a model that
  # cannot reliably collapse an English template's two forms into one.
  defp normalize_output(text, %{format: "po"} = work_item),
    do: Po.normalize_plural_forms(text, Map.get(work_item, :locale))

  defp normalize_output(text, _work_item), do: text

  defp default_validate(_text, _source), do: :ok
end
