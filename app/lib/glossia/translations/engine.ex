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

  alias Glossia.Translations.ContentSegments
  alias Glossia.Translations.Context
  alias Glossia.Translations
  alias Glossia.Translations.Format
  alias Glossia.Translations.Frontmatter
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

      {:error, reason} ->
        {:error, {:llm_failed, reason}}
    end
  end

  defp translate_segments(state) do
    segment_count = length(state.segments)

    state.segments
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, %{segments: [], model: nil, provider: nil}}, fn
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
                provider: result.provider
              }}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
    end)
  end

  # A long segment carrying many protected markers occasionally comes back with
  # one of them dropped or rewritten. Re-running that one segment, naming the
  # markers it lost, recovers far more cheaply than failing the document and
  # retranslating every segment of it. When the retries run out the output is
  # kept as is, so restoration still reports it as a document-level failure.
  defp translate_segment(state, segment, index, count, attempt, last_error) do
    state.on_event.({:segment_start, index, count, segment.kind})

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

    case translate_stream(state.account, payload, state.on_event, state.translation_opts) do
      {:ok, result} ->
        text = strip_structured_code_fence(state.work_item.format, result.text)

        case unpreserved_markers(state.protections, segment.content, text) do
          markers when markers != [] and attempt < @segment_attempts ->
            # Deliberately no `segment_output`: progress folds that event into
            # the item's completed text, so announcing output we are about to
            # discard would leave the rejected and corrected text concatenated.
            message = marker_error_message(markers)
            state.on_event.({:segment_retry, index, message})
            translate_segment(state, segment, index, count, attempt + 1, message)

          _markers ->
            state.on_event.({:segment_output, text})
            {:ok, text, result}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp unpreserved_markers(protections, segment_content, text) do
    Enum.flat_map(
      protections,
      &PreservedTokens.unpreserved_markers(&1, segment_content, text)
    )
  end

  defp marker_error_message(markers) do
    "these protected token markers must be copied byte-for-byte exactly once: " <>
      Enum.join(markers, ", ")
  end

  defp assemble_segments(state, translated_segments) do
    {frontmatter_segments, body_segments} =
      Enum.split_with(translated_segments, &(&1.kind == "frontmatter"))

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
    run_attempt(%{state | attempt: state.attempt + 1, last_error: message})
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
        frontmatter_protection =
          PreservedTokens.protect(split.frontmatter, preserve_kinds, scope: "frontmatter")

        {body_segments, body_protections} =
          planned_content_segments(split.body, work_item.format, preserve_kinds, "body")

        %{
          preserved_frontmatter: nil,
          segments:
            [%{kind: "frontmatter", content: frontmatter_protection.text}] ++ body_segments,
          protections: [frontmatter_protection | body_protections]
        }

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

  defp planned_content_segments(content, format, preserve_kinds, scope) do
    protection = PreservedTokens.protect(content, preserve_kinds, scope: scope)
    {content_segments(protection.text, format), [protection]}
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
