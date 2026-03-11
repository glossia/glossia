defmodule GlossiaAgent.TranslateEngine do
  @moduledoc """
  Core translation logic with a bounded validation loop.
  Ported from agent/translate_engine.ts / cli/internal/glossia/agent.go

  v1 simplifications:
   - No coordinator brief (uses default_brief instead of an LLM-generated brief).
   - No revisit mode.
  """

  alias GlossiaAgent.Format
  alias GlossiaAgent.LLM.Client, as: LLM
  alias GlossiaAgent.Checks.Validator
  alias GlossiaAgent.Config.LLMConfig.AgentConfig

  @max_validation_attempts 2

  @type request :: %{
          source: String.t(),
          target_lang: String.t(),
          format: Format.t(),
          context: String.t(),
          translator: AgentConfig.t()
        }

  @type result :: %{text: String.t(), usage: LLM.usage()}

  @doc """
  Translate a single file with validation/correction attempts.

  Raises when all correction attempts are exhausted.
  """
  @spec translate_file(request()) :: result()
  def translate_file(req) do
    brief = default_brief(req)
    attempts = @max_validation_attempts

    do_translate(req, brief, req.source, nil, 0, attempts, empty_usage())
  end

  defp do_translate(_req, _brief, _content, last_err, attempt, max_attempts, _usage)
       when attempt > max_attempts do
    if last_err do
      raise last_err
    else
      raise "translation failed"
    end
  end

  defp do_translate(req, brief, content, last_err, attempt, max_attempts, usage) do
    case translate_once(req, brief, content, last_err) do
      {:ok, result} ->
        usage = add_usage(usage, result.usage)
        translated = strip_structured_code_fence(req.format, String.trim_trailing(result.text))

        check_err = Validator.validate(req.format, translated, req.source)

        if check_err == nil do
          %{text: translated, usage: usage}
        else
          do_translate(
            req,
            brief,
            content,
            check_err,
            attempt + 1,
            max_attempts,
            usage
          )
        end

      {:error, err} ->
        do_translate(req, brief, content, err, attempt + 1, max_attempts, usage)
    end
  end

  defp translate_once(req, brief, source_content, last_err) do
    model = String.trim(req.translator.model)

    if model == "" do
      {:error, "translator model is required"}
    else
      parts =
        [
          "Translate to #{req.target_lang}.",
          "",
          "Context:\n#{req.context}",
          "",
          "Source:\n#{source_content}"
        ] ++
          if last_err do
            [
              "\nPrevious output failed validation: #{last_err}\nReturn a corrected full translation."
            ]
          else
            []
          end

      user_message = Enum.join(parts, "\n")

      messages = [
        %{role: "system", content: "You are a translation engine. Follow this brief:\n" <> brief},
        %{role: "user", content: user_message}
      ]

      LLM.safe_chat(req.translator, model, messages)
    end
  end

  defp default_brief(req) do
    lines =
      [
        "Translate the content faithfully and naturally.",
        "Keep code blocks, inline code, URLs, and placeholders unchanged.",
        "Keep formatting, lists, and headings intact.",
        "Return only the translated content."
      ] ++
        if Format.structured?(req.format) do
          ["Return valid #{req.format} only. Do not wrap in markdown fences."]
        else
          []
        end

    Enum.join(lines, "\n")
  end

  defp strip_structured_code_fence(format, text) do
    if Format.structured?(format) do
      trimmed = String.trim(text)

      if String.starts_with?(trimmed, "```") do
        lines = String.split(trimmed, "\n")

        if length(lines) >= 2 && String.trim(List.last(lines)) == "```" do
          lines
          |> Enum.slice(1..(length(lines) - 2)//1)
          |> Enum.join("\n")
        else
          text
        end
      else
        text
      end
    else
      text
    end
  end

  defp empty_usage do
    %{prompt_tokens: 0, completion_tokens: 0, total_tokens: 0}
  end

  defp add_usage(a, b) do
    %{
      prompt_tokens: (a.prompt_tokens || 0) + (b.prompt_tokens || 0),
      completion_tokens: (a.completion_tokens || 0) + (b.completion_tokens || 0),
      total_tokens: (a.total_tokens || 0) + (b.total_tokens || 0)
    }
  end
end
