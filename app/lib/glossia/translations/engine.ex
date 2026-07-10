defmodule Glossia.Translations.Engine do
  @moduledoc """
  Turns a planned work item into translated output content.

  Ported from the CLI (`cli/src/translate/engine.rs`). For a work item it reads
  the source, splits frontmatter when the format is markdown and the mode is
  `:preserve`, streams the translation (retrying with the previous validation
  error on failure, up to `retries + 1` attempts), strips a structured code fence
  from the model output, and reattaches the preserved frontmatter.

  The actual model call goes through `Glossia.Translations.translate_stream/3`, so
  every attempt's turns are forwarded to `on_event` for live progress. Validation
  is pluggable via the `validate` function (defaults to always-ok until the
  `validate/` port lands).
  """

  alias Glossia.Translations
  alias Glossia.Translations.Format
  alias Glossia.Translations.Frontmatter

  @doc """
  Translates `work_item` for `account`, forwarding turn events to `on_event`.

  Returns `{:ok, %{text, output_path, output_abs, locale, model, provider}}` or
  `{:error, reason}`. `validate` receives the assembled output and returns `:ok`
  or `{:error, message}` to trigger a self-correcting retry.
  """
  def apply_item(work_item, account, on_event, validate \\ &default_validate/2)
      when is_function(on_event, 1) and is_function(validate, 2) do
    case File.read(work_item.source_abs) do
      {:ok, source_text} ->
        {frontmatter, content} = prepare(work_item, source_text)

        run_attempt(%{
          account: account,
          work_item: work_item,
          content: content,
          frontmatter: frontmatter,
          source_text: source_text,
          on_event: on_event,
          validate: validate,
          attempt: 0,
          max_attempt: work_item.retries || 0,
          last_error: nil
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
    payload =
      payload(state.work_item, state.content, not is_nil(state.frontmatter), state.last_error)

    case Translations.translate_stream(state.account, payload, state.on_event) do
      {:ok, result} ->
        final =
          result.text
          |> String.trim_trailing()
          |> then(&strip_structured_code_fence(state.work_item.format, &1))
          |> then(&reassemble(state.frontmatter, &1))

        case state.validate.(final, state.source_text) do
          :ok ->
            {:ok,
             %{
               text: final,
               output_path: state.work_item.output_path,
               output_abs: state.work_item.output_abs,
               locale: state.work_item.locale,
               model: result.model,
               provider: result.provider
             }}

          {:error, message} ->
            run_attempt(%{state | attempt: state.attempt + 1, last_error: to_string(message)})
        end

      {:error, reason} ->
        {:error, {:llm_failed, reason}}
    end
  end

  @doc false
  def prepare(%{format: "markdown", frontmatter_mode: :preserve}, source_text) do
    case Frontmatter.split_markdown_frontmatter(source_text) do
      %{ok: true, frontmatter: frontmatter, body: body} -> {frontmatter, body}
      _ -> {nil, source_text}
    end
  end

  def prepare(_work_item, source_text), do: {nil, source_text}

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

  defp payload(work_item, content, frontmatter_preserved, last_error) do
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
      "last_error" => last_error
    }
  end

  defp default_validate(_text, _source), do: :ok
end
