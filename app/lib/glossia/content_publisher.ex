defmodule Glossia.ContentPublisher do
  @moduledoc false

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
        |> Path.wildcard()
        |> Enum.sort()
        |> :erlang.md5() != :erlang.md5(@content_publisher_paths)
      end

      def __phoenix_recompile__?, do: __mix_recompile__?()
    end
  end

  def __extract__(module, opts) do
    builder = Keyword.fetch!(opts, :build)
    from = Keyword.fetch!(opts, :from)
    as = Keyword.fetch!(opts, :as)

    paths = from |> Path.wildcard() |> Enum.sort()

    entries =
      Enum.map(paths, fn path ->
        {attrs, body} = parse_contents!(path, File.read!(path))
        builder.build(path, attrs, convert_body(path, body, attrs, opts))
      end)

    Module.put_attribute(module, as, entries)
    {from, paths}
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
