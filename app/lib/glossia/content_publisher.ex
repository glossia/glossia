defmodule Glossia.ContentPublisher do
  @moduledoc """
  Compiles markdown content into structs at build time.

  Content is authored in English under `priv/<section>/` and translated into
  `priv/i18n/<locale>/<section>/`, keeping the same relative path so every
  translation shares the `id` its English original builds. Passing `:i18n`
  makes the publisher compile one collection per locale, each one being the
  English collection with the available translations substituted in. An entry
  that has not been translated yet keeps its English version, so a locale is
  never a partial site.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {from, paths} = Glossia.ContentPublisher.__extract__(__MODULE__, opts)

      for path <- paths do
        @external_resource Path.relative_to_cwd(path)
      end

      @content_publisher_from from
      @content_publisher_paths paths

      def __mix_recompile__? do
        @content_publisher_from
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.sort()
        |> :erlang.md5() != :erlang.md5(@content_publisher_paths)
      end

      def __phoenix_recompile__?, do: __mix_recompile__?()
    end
  end

  def __extract__(module, opts) do
    as = Keyword.fetch!(opts, :as)
    from = Keyword.fetch!(opts, :from)
    i18n = Keyword.get(opts, :i18n)

    {entries, paths} = build_entries(from, opts)

    {by_locale, i18n_paths} = build_locales(entries, i18n, opts)

    Module.put_attribute(module, as, entries)
    Module.put_attribute(module, :"#{as}_by_locale", by_locale)

    froms = [from | Enum.map(i18n_paths, &elem(&1, 0))]
    all_paths = Enum.sort(paths ++ Enum.flat_map(i18n_paths, &elem(&1, 1)))

    {froms, all_paths}
  end

  defp build_locales(_entries, nil, _opts), do: {%{}, []}

  defp build_locales(entries, section, opts) do
    Glossia.I18n.translated_locales()
    |> Enum.map_reduce([], fn locale, acc ->
      from = Application.app_dir(:glossia, "priv/i18n/#{locale}/#{section}/**/*.md")
      {translated, paths} = build_entries(from, opts)

      {{locale, merge_translations(entries, translated)}, [{from, paths} | acc]}
    end)
    |> then(fn {by_locale, paths} -> {Map.new(by_locale), paths} end)
  end

  # Keeps the English collection's shape: same entries, same order, with every
  # translated entry swapping in for its English original.
  defp merge_translations(entries, translated) do
    by_id = Map.new(translated, &{&1.id, &1})
    Enum.map(entries, &Map.get(by_id, &1.id, &1))
  end

  defp build_entries(from, opts) do
    builder = Keyword.fetch!(opts, :build)
    paths = from |> Path.wildcard() |> Enum.sort()

    entries =
      Enum.map(paths, fn path ->
        {attrs, body} = parse_contents!(path, File.read!(path))
        builder.build(path, attrs, convert_body(path, body, attrs, opts))
      end)

    {entries, paths}
  end

  defp parse_contents!(path, contents) do
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] ->
        raise """
        could not find separator --- in #{inspect(path)}

        Each entry must have a map with attributes, followed by --- and a body.
        """

      [code, body] ->
        case Code.eval_string(code, []) do
          {%{} = attrs, _} ->
            {attrs, body}

          {other, _} ->
            raise "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"
        end
    end
  end

  defp convert_body(path, body, attrs, opts) do
    converter = Keyword.get(opts, :html_converter, Glossia.Markdown.Publisher)
    converter.convert(path, body, attrs, opts)
  end
end
