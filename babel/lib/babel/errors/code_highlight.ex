defmodule Babel.Errors.CodeHighlight do
  @moduledoc """
  Renders a Sentry stack-trace frame's source-context block as HTML.

  Babel does not (yet) pull in a syntax-highlighting dependency, so
  this module always emits the plain-HTML rendering that Hive used as
  its fallback: every source line is wrapped in `<div class="l-line">`
  with `data-line` set to the absolute file line number, and the
  failing `context_line` gets an inline background. The CSS in
  `assets/css/routes/errors.css` styles that consistently.

  Returns `nil` when the frame carries no source context at all so
  callers can skip the whole `<pre>` block.
  """

  def highlight_frame(frame, _platform) when is_map(frame) do
    pre = list(frame["pre_context"])
    ctx = frame["context_line"]
    post = list(frame["post_context"])

    if ctx == nil and pre == [] and post == [] do
      nil
    else
      source = build_source(pre, ctx, post)
      base_line = frame["lineno"] || max(length(pre) + 1, 1)
      start_line = base_line - length(pre)
      current_line = length(pre) + 1

      plain_html(source, start_line, current_line)
    end
  end

  def highlight_frame(_, _), do: nil

  defp build_source(pre, ctx, post) do
    Enum.map_join(pre ++ [ctx || ""] ++ post, "\n", &normalize_line/1)
  end

  defp normalize_line(nil), do: ""
  defp normalize_line(line) when is_binary(line), do: line
  defp normalize_line(other), do: to_string(other)

  defp plain_html(source, start_line, current_line) do
    lines = String.split(source, "\n")

    line_htmls =
      lines
      |> Enum.with_index(1)
      |> Enum.map_join("", fn {line, idx} ->
        highlight? = idx == current_line
        line_number = start_line + idx - 1
        escaped = line |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
        style = if highlight?, do: ~s( style="background-color: #e9ebf2;"), else: ""

        ~s(<div class="l-line"#{style} data-line="#{line_number}">#{escaped}</div>)
      end)

    ~s(<pre class="lumis"><code translate="no" tabindex="0">#{line_htmls}</code></pre>)
  end

  defp list(l) when is_list(l), do: l
  defp list(_), do: []
end
