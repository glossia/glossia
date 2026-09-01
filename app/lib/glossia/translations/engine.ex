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
  @markdown_text_literal_recovery_max_calls 128
  @markdown_text_literal_recovery_batch_size 12
  @markdown_text_literal_recovery_batch_bytes 8_000
  @markdown_text_literal_fast_path_min_literals 12

  require Logger

  alias Glossia.Translations.ContentSegments
  alias Glossia.Translations.Context
  alias Glossia.Translations
  alias Glossia.Translations.Format
  alias Glossia.Translations.Frontmatter
  alias Glossia.Translations.JsonArray
  alias Glossia.Translations.Markdown
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
        translation = prepare_translation(work_item, source_text, preserve_kinds)

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
          source_text: source_text,
          on_event: on_event,
          validate: validate,
          attempt: 0,
          max_attempt: work_item.retries || 0,
          last_error: nil,
          translation_opts: opts
        })

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
            case state.validate.(final, state.source_text) do
              :ok ->
                state.on_event.({:translation_output, final})

                {:ok,
                 %{
                   text: final,
                   output_path: state.work_item.output_path,
                   output_abs: state.work_item.output_abs,
                   locale: state.work_item.locale,
                   model: translated.model,
                   provider: translated.provider
                 }}

              {:error, message} ->
                retry_validation(state, message)
            end

          {:error, message} ->
            retry_validation(state, message)
        end

      {:validation_error, message} ->
        retry_validation(state, message)

      {:preservation_error, message} ->
        {:error, {:validation_failed, message}}

      {:error, reason} ->
        {:error, {:llm_failed, reason}}
    end
  end

  defp translate_segments(state) do
    segment_count = length(state.segments)

    state.segments
    |> Enum.with_index(1)
    |> Enum.reduce_while(
      {:ok, %{segments: [], model: nil, provider: nil, markdown_text_literal_recovery_calls: 0}},
      fn
        {segment, segment_index}, {:ok, acc} ->
          case translate_segment(
                 state,
                 segment,
                 segment_index,
                 segment_count,
                 1,
                 state.last_error
               ) do
            {:ok, text, result} ->
              translated_segment = %{kind: segment.kind, text: text}

              {:cont,
               {:ok,
                %{
                  segments: acc.segments ++ [translated_segment],
                  model: result.model,
                  provider: result.provider,
                  markdown_text_literal_recovery_calls: acc.markdown_text_literal_recovery_calls
                }}}

            {:error, reason} ->
              {:halt, {:error, reason}}

            {:preservation_error, message} ->
              # Markdown's source tree already gives us a deterministic recovery
              # path. Try that before asking the model to reproduce the same
              # Markdown syntax in smaller blocks: models that normalize a link
              # or list tend to do so on every ordinary retry, which turns one
              # bad response into several slow, identical requests.
              case recover_markdown_text_nodes(
                     state,
                     segment,
                     segment_index,
                     segment_count,
                     message
                   ) do
                {:ok, recovered} ->
                  {:cont,
                   {:ok,
                    %{
                      segments: acc.segments ++ recovered.segments,
                      model: recovered.model,
                      provider: recovered.provider,
                      markdown_text_literal_recovery_calls:
                        acc.markdown_text_literal_recovery_calls
                    }}}

                {:error, reason} ->
                  {:halt, {:error, reason}}

                :error ->
                  case recover_markdown_segment(
                         state,
                         segment,
                         segment_index,
                         segment_count,
                         message
                       ) do
                    {:ok, recovered} ->
                      {:cont,
                       {:ok,
                        %{
                          segments: acc.segments ++ recovered.segments,
                          model: recovered.model,
                          provider: recovered.provider,
                          markdown_text_literal_recovery_calls:
                            acc.markdown_text_literal_recovery_calls
                        }}}

                    {:error, reason} ->
                      {:halt, {:error, reason}}

                    :error ->
                      case recover_markdown_text_literals(
                             state,
                             segment,
                             segment_index,
                             segment_count,
                             message,
                             @markdown_text_literal_recovery_max_calls -
                               acc.markdown_text_literal_recovery_calls
                           ) do
                        {:ok, recovered} ->
                          {:cont,
                           {:ok,
                            %{
                              segments: acc.segments ++ recovered.segments,
                              model: recovered.model,
                              provider: recovered.provider,
                              markdown_text_literal_recovery_calls:
                                acc.markdown_text_literal_recovery_calls +
                                  recovered.markdown_text_literal_recovery_calls
                            }}}

                        {:error, reason} ->
                          {:halt, {:error, reason}}

                        {:preservation_error, reason} ->
                          {:halt, {:preservation_error, reason}}

                        :error ->
                          {:halt, {:preservation_error, message}}
                      end
                  end
              end
          end
      end
    )
  end

  # A model occasionally combines or drops Markdown blocks even after the
  # segment-level correction prompt. Re-run only a multi-block failed segment
  # as individual source blocks, retaining both the document structure and all
  # earlier successful segment output.
  defp recover_markdown_segment(state, segment, index, count, message) do
    segments =
      [segment]
      |> isolate_markdown_blocks()
      |> Enum.map(&Map.put(&1, :markdown_block_recovery, true))

    if markdown_recovery_error?(state, segment, message) and length(segments) > 1 do
      recovered_count = count + length(segments) - 1

      segments
      |> Enum.with_index(index)
      |> Enum.reduce_while({:ok, %{segments: [], model: nil, provider: nil}}, fn
        {recovery_segment, recovery_index}, {:ok, acc} ->
          case translate_segment(
                 state,
                 recovery_segment,
                 recovery_index,
                 recovered_count,
                 1,
                 message
               ) do
            {:ok, text, result} ->
              {:cont,
               {:ok,
                %{
                  segments: acc.segments ++ [%{kind: recovery_segment.kind, text: text}],
                  model: result.model,
                  provider: result.provider
                }}}

            {:error, reason} ->
              {:halt, {:error, reason}}

            _ ->
              {:halt, :error}
          end
      end)
    else
      :error
    end
  end

  # A Markdown block can contain links, lists, or admonitions that a model
  # rearranges. Give the model marker-delimited text literals and rebuild the
  # original Markdown tree directly, making syntax preservation independent of
  # its rendered output.
  defp recover_markdown_text_nodes(state, segment, index, count, message) do
    with true <- markdown_recovery_error?(state, segment, message),
         true <- not String.contains?(segment.content, "@@GLOSSIA-TEXT-"),
         {:ok, marked_content} <- Markdown.mark_text_nodes(segment.content),
         true <- String.contains?(marked_content, "@@GLOSSIA-TEXT-"),
         recovery_segment <-
           Map.merge(segment, %{
             kind: "markdown_text_markers",
             content: marked_content,
             markdown_source: segment.content
           }) do
      case translate_segment(
             state,
             recovery_segment,
             index,
             count,
             1,
             markdown_marker_instruction(message)
           ) do
        {:ok, text, result} ->
          {:ok,
           %{
             segments: [%{kind: segment.kind, text: text}],
             model: result.model,
             provider: result.provider
           }}

        {:error, reason} ->
          {:error, reason}

        _ ->
          :error
      end
    else
      _ -> :error
    end
  end

  defp markdown_marker_instruction(message) do
    "#{message}. Each @@GLOSSIA-TEXT-<number>-START@@ and " <>
      "@@GLOSSIA-TEXT-<number>-END@@ marker is immutable: copy every marker " <>
      "exactly once and translate only the text between its matching markers."
  end

  # Marker-delimited recovery keeps the ordinary fast path compact, but a
  # smaller model can still lose markers in a dense document. At that point,
  # translate bounded batches of source-tree text literals and rebuild the
  # document ourselves. The model never receives Markdown syntax, so it cannot
  # change headings, links, lists, code spans, or block ordering.
  defp recover_markdown_text_literals(state, segment, index, count, message, remaining_calls) do
    if markdown_recovery_error?(state, segment, message) do
      translate_markdown_text_literals(state, segment, index, count, remaining_calls)
    else
      :error
    end
  end

  # Complex Markdown used to take the ordinary full-document path first, then
  # spend several corrections asking a model to restore headings, links, and
  # lists it had already changed. For a large source tree it is both quicker
  # and more reliable to translate the text nodes directly and rebuild the
  # Markdown ourselves. Small fragments keep the normal path, whose single
  # request is still cheaper than building a JSON array.
  defp translate_large_markdown_segment_as_literals(state, segment, index, count) do
    with %{format: "markdown"} <- state.work_item,
         true <- not String.contains?(segment.content, "{glossia_protected_"),
         true <- not String.contains?(segment.content, "@@GLOSSIA-TEXT-"),
         {:ok, source_literals} <- Markdown.text_literals(segment.content),
         true <- length(source_literals) >= @markdown_text_literal_fast_path_min_literals,
         true <- length(source_literals) <= @markdown_text_literal_recovery_max_calls do
      translate_markdown_text_literals(
        state,
        segment,
        index,
        count,
        @markdown_text_literal_recovery_max_calls
      )
    else
      _ -> :error
    end
  end

  defp translate_markdown_text_literals(state, segment, index, count, remaining_calls) do
    with true <- not String.contains?(segment.content, "@@GLOSSIA-TEXT-"),
         {:ok, source_literals} <- Markdown.text_literals(segment.content),
         true <- source_literals != [],
         true <- length(source_literals) <= remaining_calls do
      entries =
        source_literals
        |> Enum.with_index()
        |> Enum.map(fn {literal, literal_index} ->
          markdown_text_literal_entry(state, literal, literal_index)
        end)

      entries
      |> Enum.reject(&(&1.content == ""))
      |> batch_markdown_text_literals()
      |> Enum.reduce_while(
        {:ok,
         %{
           literals: blank_markdown_text_literals(entries),
           model: nil,
           provider: nil,
           markdown_text_literal_recovery_calls: 0
         }},
        fn batch, {:ok, acc} ->
          case translate_markdown_text_literal_batch(state, segment, batch, index, count, nil) do
            {:ok, translated_literals, result} ->
              literals =
                batch
                |> Enum.zip(translated_literals)
                |> Map.new(fn {%{index: literal_index}, literal} -> {literal_index, literal} end)
                |> then(&Map.merge(acc.literals, &1))

              {:cont,
               {:ok,
                %{
                  acc
                  | literals: literals,
                    model: result.model || acc.model,
                    provider: result.provider || acc.provider,
                    markdown_text_literal_recovery_calls:
                      acc.markdown_text_literal_recovery_calls + 1
                }}}

            {:error, reason} ->
              {:halt, {:error, reason}}

            {:preservation_error, reason} ->
              {:halt, {:preservation_error, reason}}

            _ ->
              {:halt, :error}
          end
        end
      )
      |> case do
        {:ok, %{literals: literals} = recovery} ->
          literals = Enum.map(entries, &Map.fetch!(literals, &1.index))

          with {:ok, text} <-
                 Markdown.rebuild_text_literals(segment.content, literals) do
            state.on_event.({:segment_output, text})

            {:ok,
             %{
               segments: [%{kind: segment.kind, text: text}],
               model: recovery.model,
               provider: recovery.provider,
               markdown_text_literal_recovery_calls: recovery.markdown_text_literal_recovery_calls
             }}
          else
            {:error, reason} -> {:preservation_error, reason}
          end

        other ->
          other
      end
    else
      _ -> :error
    end
  end

  defp markdown_text_literal_entry(state, literal, index) do
    {leading, content, trailing} = split_literal_whitespace(literal)

    protection =
      PreservedTokens.protect(
        content,
        state.preserve_kinds,
        scope: "markdown_text_literal_#{index}",
        mask_urls: true
      )

    %{
      index: index,
      leading: leading,
      content: protection.text,
      trailing: trailing,
      protection: protection
    }
  end

  defp blank_markdown_text_literals(entries) do
    entries
    |> Enum.filter(&(&1.content == ""))
    |> Map.new(fn entry -> {entry.index, entry.leading <> entry.trailing} end)
  end

  defp batch_markdown_text_literals([]), do: []

  defp batch_markdown_text_literals(entries) do
    entries
    |> Enum.reduce({[], [], 0}, fn entry, {batches, current, bytes} ->
      entry_bytes = byte_size(entry.content)

      if current != [] and
           (length(current) >= @markdown_text_literal_recovery_batch_size or
              bytes + entry_bytes > @markdown_text_literal_recovery_batch_bytes) do
        {[Enum.reverse(current) | batches], [entry], entry_bytes}
      else
        {batches, [entry | current], bytes + entry_bytes}
      end
    end)
    |> then(fn {batches, current, _bytes} -> Enum.reverse([Enum.reverse(current) | batches]) end)
  end

  defp translate_markdown_text_literal_batch(state, segment, entries, index, count, _message) do
    recovery_segment =
      Map.merge(segment, %{
        kind: "markdown_text_literals",
        content: entries |> Enum.map(& &1.content) |> JSON.encode!(),
        protections: Enum.map(entries, & &1.protection),
        markdown_text_literal_recovery: true,
        suppress_progress: true,
        suppress_stream_text: true
      })

    case translate_segment(state, recovery_segment, index, count, 1, nil) do
      {:ok, translated, result} ->
        with {:ok, translated_literals} <-
               decode_markdown_text_literal_batch(translated, length(entries)),
             {:ok, restored_literals} <-
               restore_markdown_text_literal_batch(entries, translated_literals) do
          {:ok, restored_literals, result}
        else
          {:error, reason} -> {:preservation_error, reason}
        end

      other ->
        other
    end
  end

  defp decode_markdown_text_literal_batch(text, expected_count) do
    case JsonArray.decode(text) do
      {:ok, literals} when is_list(literals) ->
        if length(literals) == expected_count and Enum.all?(literals, &is_binary/1) do
          {:ok, literals}
        else
          {:error,
           "Markdown text-literal recovery must return a JSON string array of matching length"}
        end

      {:ok, _value} ->
        {:error,
         "Markdown text-literal recovery must return a JSON string array of matching length"}

      {:error, _reason} ->
        {:error, "Markdown text-literal recovery returned invalid JSON"}
    end
  end

  defp restore_markdown_text_literal_batch(entries, translated_literals) do
    entries
    |> Enum.zip(translated_literals)
    |> Enum.reduce_while({:ok, []}, fn {%{protection: protection} = entry, translated},
                                       {:ok, literals} ->
      with true <- String.trim(translated) != "",
           {:ok, restored} <- PreservedTokens.restore(translated, protection) do
        literal = entry.leading <> String.trim(restored) <> entry.trailing
        {:cont, {:ok, [literal | literals]}}
      else
        false -> {:halt, {:error, "Markdown text-node recovery produced an empty translation"}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, literals} -> {:ok, Enum.reverse(literals)}
      error -> error
    end
  end

  defp split_literal_whitespace(literal) do
    trimmed = String.trim(literal)
    leading_size = byte_size(literal) - byte_size(String.trim_leading(literal))
    trailing_size = byte_size(literal) - byte_size(String.trim_trailing(literal))
    leading = binary_part(literal, 0, leading_size)
    trailing = binary_part(literal, byte_size(literal) - trailing_size, trailing_size)

    {leading, trimmed, trailing}
  end

  # A long segment carrying many protected markers occasionally comes back with
  # one of them dropped or rewritten. Re-running that one segment, naming the
  # markers it lost, recovers far more cheaply than retranslating the document.
  # If that focused recovery runs out, stop there rather than repeatedly
  # translating segments whose output has already passed preservation checks.
  defp translate_segment(
         state,
         %{kind: "content"} = segment,
         index,
         count,
         attempt,
         last_error
       ) do
    case translate_large_markdown_segment_as_literals(state, segment, index, count) do
      {:ok, %{segments: [%{text: text}], model: model, provider: provider}} ->
        {:ok, text, %{model: model, provider: provider}}

      _ ->
        translate_segment_with_model(state, segment, index, count, attempt, last_error)
    end
  end

  defp translate_segment(state, segment, index, count, attempt, last_error) do
    translate_segment_with_model(state, segment, index, count, attempt, last_error)
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
             {:ok, text} <- reconcile_markdown_segment(text, segment, state.work_item.format) do
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
            if markdown_structure_error?(state, message) and
                 not Map.get(segment, :markdown_block_recovery, false) do
              {:preservation_error, message}
            else
              emit_segment_event(state, segment, {:segment_retry, index, message})
              translate_segment(state, segment, index, count, attempt + 1, message)
            end

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

  defp assemble_segments(state, translated_segments) do
    {frontmatter_segments, body_segments} =
      Enum.split_with(translated_segments, &frontmatter_segment?/1)

    frontmatter =
      state.preserved_frontmatter ||
        case frontmatter_segments do
          [%{text: text} | _] -> String.trim(text)
          [] -> nil
        end

    body =
      body_segments
      |> Enum.map(&String.trim(&1.text))
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    frontmatter
    |> reassemble(body)
    |> String.trim_trailing()
  end

  defp translate_stream(account, payload, on_event, []) do
    Translations.translate_stream(account, payload, on_event)
  end

  defp translate_stream(account, payload, on_event, opts) do
    Translations.translate_stream(account, payload, on_event, opts)
  end

  defp retry_validation(state, message) do
    message = to_string(message)
    state.on_event.({:validation_error, message})

    state =
      if markdown_structure_error?(state, message) do
        %{state | segments: isolate_markdown_blocks(state.segments)}
      else
        state
      end

    run_attempt(%{state | attempt: state.attempt + 1, last_error: message})
  end

  # A model occasionally combines or drops Markdown blocks even after an
  # explicit repair prompt. Retrying only the affected document as individual
  # source blocks lets Markdown.reconcile/2 retain its source structure while
  # still taking the model's translation for each piece of prose. Successful
  # documents keep their normal, larger segments.
  defp markdown_structure_error?(%{work_item: %{format: "markdown"}}, message) do
    String.contains?(String.downcase(message), "markdown changed the document structure")
  end

  defp markdown_structure_error?(_state, _message), do: false

  # Markdown's parsed source tree owns both its structure and link
  # destinations. Rebuilding that tree therefore also repairs a model response
  # that dropped a visible URL or another preserved value, without asking the
  # model to reproduce it again. A segment carrying an internal marker still
  # uses this path for a Markdown-structure error, but not for a marker-copy
  # failure, where recovery must fail closed rather than move the marker.
  defp markdown_recovery_error?(%{work_item: %{format: "markdown"}} = state, segment, message) do
    markdown_structure_error?(state, message) or
      not String.contains?(segment.content, "{glossia_protected_")
  end

  defp markdown_recovery_error?(_state, _segment, _message), do: false

  defp isolate_markdown_blocks(segments) do
    Enum.flat_map(segments, fn
      %{kind: "frontmatter"} = segment ->
        [segment]

      %{content: content} = segment ->
        content
        |> ContentSegments.split(max_segment_bytes: 1)
        |> Enum.map(&%{segment | content: &1})
    end)
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
        {segments, protections} =
          planned_content_segments(split.body, work_item.format, preserve_kinds, "body")

        %{
          preserved_frontmatter: split.frontmatter,
          segments: segments,
          protections: protections
        }

      {:translate, true} ->
        translated_frontmatter_segments(split.frontmatter, preserve_kinds, split.body, work_item)

      _ ->
        {segments, protections} =
          planned_content_segments(source_text, work_item.format, preserve_kinds, "document")

        %{preserved_frontmatter: nil, segments: segments, protections: protections}
    end
  end

  defp prepare_translation(%{format: "po"} = work_item, source_text, _preserve_kinds) do
    {segments, protections} =
      planned_content_segments(source_text, work_item.format, [], "document")

    %{preserved_frontmatter: nil, segments: segments, protections: protections}
  end

  defp prepare_translation(work_item, source_text, preserve_kinds) do
    {segments, protections} =
      planned_content_segments(source_text, work_item.format, preserve_kinds, "document")

    %{preserved_frontmatter: nil, segments: segments, protections: protections}
  end

  # Markdown source structure is reassembled after translation. Link
  # destinations and code therefore never need opaque markers or a model round
  # trip. Placeholders remain opaque, including placeholders inside a link
  # destination. Other formats continue to use their existing format-neutral
  # plan.
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

  defp reconcile_markdown_segment(text, %{kind: "frontmatter"}, _format), do: {:ok, text}

  defp reconcile_markdown_segment(
         text,
         %{kind: "frontmatter_text_literals", frontmatter_plan: plan},
         "markdown"
       ),
       do: Frontmatter.rebuild_nimble_publisher_text_literals(plan, text)

  defp reconcile_markdown_segment(
         text,
         %{kind: "markdown_text_markers", markdown_source: source},
         "markdown"
       ) do
    Markdown.reconcile_marked_text_nodes(source, text)
  end

  defp reconcile_markdown_segment(text, %{kind: "markdown_text_literal"}, "markdown"),
    do: {:ok, text}

  defp reconcile_markdown_segment(text, %{kind: "markdown_text_literals"}, "markdown"),
    do: {:ok, text}

  defp reconcile_markdown_segment(text, segment, "markdown") do
    if Markdown.requires_reconciliation?(segment.content) do
      Markdown.reconcile(segment.content, text)
    else
      {:ok, text}
    end
  end

  defp reconcile_markdown_segment(text, _segment, _format), do: {:ok, text}

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

  defp translated_frontmatter_segments(frontmatter, preserve_kinds, body, work_item) do
    {body_segments, body_protections} =
      planned_content_segments(body, work_item.format, preserve_kinds, "body")

    case Frontmatter.nimble_publisher_text_literals(frontmatter) do
      {:ok, plan} ->
        protection =
          plan.values
          |> JSON.encode!()
          |> PreservedTokens.protect(preserve_kinds, scope: "frontmatter_literals")

        %{
          preserved_frontmatter: nil,
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
      segments_with_terminology_omissions: 0,
      terminology_matched: 0,
      terminology_included: 0,
      terminology_omitted: 0,
      terminology_definitions_omitted: 0,
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
      segment.terminology_omitted > 0 or segment.terminology_definitions_omitted > 0

    %{
      total
      | segments_with_terminology_omissions:
          total.segments_with_terminology_omissions + if(segment_has_omissions, do: 1, else: 0),
        terminology_matched: total.terminology_matched + segment.terminology_matched,
        terminology_included: total.terminology_included + segment.terminology_included,
        terminology_omitted: total.terminology_omitted + segment.terminology_omitted,
        terminology_definitions_omitted:
          total.terminology_definitions_omitted + segment.terminology_definitions_omitted,
        voice_truncated: total.voice_truncated or segment.voice_truncated
    }
  end

  defp context_budget_clipped?(budget) do
    budget.voice_truncated or budget.terminology_omitted > 0 or
      budget.terminology_definitions_omitted > 0
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

  defp default_validate(_text, _source), do: :ok
end
