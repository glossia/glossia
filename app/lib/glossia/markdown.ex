defmodule Glossia.Markdown do
  @moduledoc false

  @default_options [
    extension: [
      table: true,
      strikethrough: true,
      autolink: true,
      tasklist: true
    ],
    syntax_highlight: false
  ]

  def to_html(markdown, opts \\ [])
  def to_html(nil, _opts), do: {:ok, ""}
  def to_html("", _opts), do: {:ok, ""}

  def to_html(markdown, opts) when is_binary(markdown) do
    markdown
    |> MDEx.to_html(mdex_options(opts))
    |> normalize_result()
  end

  def to_html!(markdown, opts \\ []) do
    case to_html(markdown, opts) do
      {:ok, html} -> html
      {:error, reason} -> raise ArgumentError, "invalid markdown: #{inspect(reason)}"
    end
  end

  defp mdex_options(opts) do
    @default_options
    |> merge_mdex_options(
      Keyword.take(opts, [:extension, :parse, :render, :sanitize, :syntax_highlight])
    )
    |> Keyword.update(:render, render_options(opts), &Keyword.merge(&1, render_options(opts)))
  end

  defp merge_mdex_options(defaults, opts) do
    Enum.reduce(opts, defaults, fn
      {key, value}, acc when key in [:extension, :parse, :render, :sanitize] and is_list(value) ->
        Keyword.update(acc, key, value, &Keyword.merge(&1, value))

      {key, value}, acc ->
        Keyword.put(acc, key, value)
    end)
  end

  defp render_options(opts) do
    if Keyword.get(opts, :breaks, false), do: [hardbreaks: true], else: []
  end

  defp normalize_result({:ok, html}), do: {:ok, html}
  defp normalize_result({:error, reason}), do: {:error, reason}
end

defmodule Glossia.Markdown.Publisher do
  @moduledoc false

  def convert(path, body, _attrs, opts) do
    case path |> Path.extname() |> String.downcase() do
      ext when ext in [".md", ".markdown", ".livemd"] ->
        opts
        |> Keyword.get(:markdown_options, [])
        |> then(&Glossia.Markdown.to_html!(body, &1))

      _ ->
        body
    end
  end
end
