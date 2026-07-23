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

  alias Glossia.Translations.ContentSegments
  alias Glossia.Translations
  alias Glossia.Translations.Format
  alias Glossia.Translations.Frontmatter

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
    case File.read(work_item.source_abs) do
      {:ok, source_text} ->
        translation = prepare_translation(work_item, source_text)

        run_attempt(%{
          account: account,
          work_item: work_item,
          segments: translation.segments,
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
    case translate_segments(state) do
      {:ok, translated} ->
        final = assemble_segments(state, translated.segments)

        case state.validate.(final, state.source_text) do
          :ok ->
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
            run_attempt(%{state | attempt: state.attempt + 1, last_error: to_string(message)})
        end

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
        payload =
          payload(
            state.work_item,
            segment.content,
            not is_nil(state.preserved_frontmatter),
            state.last_error,
            segment.kind,
            segment_index,
            segment_count
          )

        case translate_stream(state.account, payload, state.on_event, state.translation_opts) do
          {:ok, result} ->
            translated_segment = %{
              kind: segment.kind,
              text: strip_structured_code_fence(state.work_item.format, result.text)
            }

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

  @doc false
  def prepare(%{format: "markdown", frontmatter_mode: :preserve}, source_text) do
    case Frontmatter.split_markdown_frontmatter(source_text) do
      %{ok: true, frontmatter: frontmatter, body: body} -> {frontmatter, body}
      _ -> {nil, source_text}
    end
  end

  def prepare(_work_item, source_text), do: {nil, source_text}

  defp prepare_translation(%{format: "markdown"} = work_item, source_text) do
    split = Frontmatter.split_markdown_frontmatter(source_text)

    case {work_item.frontmatter_mode, split.ok} do
      {:preserve, true} ->
        %{
          preserved_frontmatter: split.frontmatter,
          segments: content_segments(split.body, work_item.format)
        }

      {:translate, true} ->
        %{
          preserved_frontmatter: nil,
          segments:
            [%{kind: "frontmatter", content: split.frontmatter}] ++
              content_segments(split.body, work_item.format)
        }

      _ ->
        %{preserved_frontmatter: nil, segments: content_segments(source_text, work_item.format)}
    end
  end

  defp prepare_translation(work_item, source_text) do
    %{preserved_frontmatter: nil, segments: content_segments(source_text, work_item.format)}
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
