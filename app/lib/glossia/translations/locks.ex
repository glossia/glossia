defmodule Glossia.Translations.Locks do
  @moduledoc """
  Per-locale translation lockfiles under `.glossia/<source>/<locale>.lock`, used to
  skip re-translating unchanged files across runs.

  Adapted from the CLI (`cli/src/locks.rs`). Because these lockfiles are now
  server-private (the CLI no longer translates), the hash is a straightforward
  SHA-256 over the source content, provider, model, and resolved context — rather
  than the CLI's snapshot Merkle tree — while keeping the PO reference-line
  normalization so line-number churn does not force re-translation.
  """

  alias Glossia.Translations.Context
  alias Glossia.Translations.Format
  alias Glossia.Translations.PreservedTokens
  alias Glossia.Translations.Prompt

  @doc "Path to the lockfile for a source/locale under the repo root."
  def lock_path(root, source_path, locale) do
    Path.join([root, ".glossia", source_path, "#{locale}.lock"])
  end

  @doc "Reads and decodes the lockfile, or `nil` if absent/unreadable."
  def read_lock(root, source_path, locale) do
    path = lock_path(root, source_path, locale)

    with true <- File.exists?(path),
         {:ok, raw} <- File.read(path),
         {:ok, lock} <- Jason.decode(raw) do
      lock
    else
      _ -> nil
    end
  end

  @doc "Writes the lockfile (pretty JSON)."
  def write_lock(root, source_path, locale, lock) do
    path = lock_path(root, source_path, locale)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Jason.encode!(lock) <> "\n")
    :ok
  end

  @doc "Whether the output is stale given the current input hash and output."
  def stale?(nil, _hash, _output_path, _output_hash), do: true

  def stale?(lock, hash, output_path, output_hash) do
    lock["hash"] != hash or lock["output_path"] != output_path or
      lock["output_hash"] != output_hash
  end

  @doc "Builds a lockfile map for a completed translation."
  def build_lock(provider, model, source_path, output_path, output_text, hash) do
    build_lock(provider, model, source_path, output_path, output_text, hash, nil, nil)
  end

  def build_lock(provider, model, source_path, output_path, output_text, hash, hash_tree) do
    build_lock(provider, model, source_path, output_path, output_text, hash, hash_tree, nil)
  end

  def build_lock(
        provider,
        model,
        source_path,
        output_path,
        output_text,
        hash,
        hash_tree,
        context_provenance
      ) do
    %{
      "hash" => hash,
      "provider" => provider,
      "model" => model,
      "source_path" => normalize_slashes(source_path),
      "output_path" => normalize_slashes(output_path),
      "output_hash" => hash_string(output_text),
      "translated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "hash_tree" => hash_tree,
      "server_context" => context_provenance
    }
  end

  @doc """
  Builds the complete dependency tree for one translation work item.

  Only effective server context content participates in the root hash. Source
  voice and glossary version numbers remain in lockfile provenance, so an
  unrelated glossary edit does not make every translated file stale.
  """
  def build_hash_state(input) when is_map(input) do
    source_hash = source_hash(input.format, input.source_content)

    source_node =
      hash_node("source", input.source_path, %{"content_hash" => source_hash}, [])

    config_node =
      hash_node(
        "translation_config",
        "generation",
        %{
          "provider" => input.provider,
          "model" => input.model,
          "format" => input.format,
          "source_language" => input.source_language,
          "language" => input.language,
          "locale" => input.locale,
          "frontmatter_mode" => to_string(input.frontmatter_mode),
          "preserve" => input |> Map.get(:preserve, []) |> Enum.sort(),
          "custom_prompt_hash" => hash_string(input.custom_prompt || ""),
          "prompt_version" => Prompt.version(),
          "segmentation_version" => Format.segmentation_version(),
          "preservation_version" => PreservedTokens.version(),
          "retries" => Map.get(input, :retries, 0),
          "validation_hash" =>
            hash_json(%{
              check_cmd: Map.get(input, :check_cmd),
              check_cmds: Map.get(input, :check_cmds),
              validation: Map.get(input, :validation),
              validation_relative_path: Map.get(input, :validation_relative_path)
            })
        },
        []
      )

    server_hash_input = Context.hash_input(input.server_context)

    server_context_children =
      [
        hash_node(
          "context",
          "voice",
          %{"content_hash" => server_hash_input["voice_content_hash"]},
          []
        ),
        hash_node(
          "context",
          "terminology",
          %{"content_hash" => server_hash_input["terminology_content_hash"]},
          []
        )
      ]
      |> maybe_add_project_memory(server_hash_input["project_context_content_hash"])

    server_context_node =
      hash_node(
        "server_context",
        "organization",
        %{
          "compiler_version" => server_hash_input["compiler_version"],
          "selector_version" => server_hash_input["selector_version"]
        },
        server_context_children
      )

    context_node =
      hash_node("context_bundle", "context", %{}, [
        hash_node(
          "context",
          "project",
          %{"content_hash" => hash_string(input.context_body || "")},
          []
        ),
        hash_node(
          "context",
          "locale",
          %{"content_hash" => hash_string(input.locale_override_body || "")},
          []
        ),
        server_context_node
      ])

    root =
      hash_node("translation_input", input.source_path, %{}, [
        source_node,
        config_node,
        context_node
      ])

    %{hash: root["hash"], tree: %{"root" => root}}
  end

  def build_hash_state(
        format,
        source_path,
        source_content,
        provider,
        model,
        context_body,
        locale_override_body
      ) do
    build_hash_state(%{
      format: format,
      source_path: source_path,
      source_content: source_content,
      provider: provider,
      model: model,
      source_language: "",
      language: "",
      locale: "",
      frontmatter_mode: :preserve,
      preserve: [],
      custom_prompt: nil,
      context_body: context_body,
      locale_override_body: locale_override_body,
      server_context: Context.empty_bundle()
    })
  end

  defp hash_node(kind, label, metadata, children) do
    child_hashes = Enum.map(children, & &1["hash"])
    descriptor = %{kind: kind, label: label, metadata: metadata, child_hashes: child_hashes}
    hash = :crypto.hash(:sha256, Jason.encode!(descriptor)) |> Base.encode16(case: :lower)

    %{
      "kind" => kind,
      "label" => label,
      "hash" => hash,
      "metadata" => metadata,
      "children" => children
    }
  end

  defp maybe_add_project_memory(children, nil), do: children

  defp maybe_add_project_memory(children, content_hash) do
    children ++
      [hash_node("context", "reviewed_project_memory", %{"content_hash" => content_hash}, [])]
  end

  @doc "Hash of the translation input: source (format-normalized), provider, model, context."
  def build_hash(format, source_content, provider, model, context_body, locale_override_body) do
    [source_hash(format, source_content), provider, model, context_body, locale_override_body]
    |> Enum.join("\0")
    |> hash_string()
  end

  @doc "Hash of the output content."
  def output_hash(output_text), do: hash_string(output_text)

  @doc "Format-aware source hash (PO ignores line-number churn)."
  def source_hash("po", content), do: hash_string(normalized_po_source(content))
  def source_hash(_format, content), do: hash_string(content)

  defp hash_string(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  defp hash_json(value), do: value |> Jason.encode!() |> hash_string()

  # Collapses consecutive `#: ` reference runs into a single sorted/deduped line
  # and strips trailing `:<line-number>` from each reference.
  defp normalized_po_source(content) do
    content
    |> String.split("\n")
    |> normalize_lines([])
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp normalize_lines([], acc), do: acc

  defp normalize_lines([line | rest], acc) do
    case strip_ref_prefix(line) do
      nil ->
        normalize_lines(rest, [line | acc])

      ref ->
        {refs, remaining} = collect_refs(rest, split_refs(ref))
        merged = "#: " <> (refs |> Enum.sort() |> Enum.dedup() |> Enum.join(" "))
        normalize_lines(remaining, [merged | acc])
    end
  end

  defp collect_refs([line | rest] = lines, acc) do
    case strip_ref_prefix(line) do
      nil -> {acc, lines}
      ref -> collect_refs(rest, acc ++ split_refs(ref))
    end
  end

  defp collect_refs([], acc), do: {acc, []}

  defp strip_ref_prefix("#: " <> rest), do: rest
  defp strip_ref_prefix(_line), do: nil

  defp split_refs(ref),
    do: ref |> String.split(~r/\s+/, trim: true) |> Enum.map(&normalize_reference/1)

  defp normalize_reference(ref) do
    case rsplit_once(ref, ":") do
      nil -> ref
      {rest, last} -> if Regex.match?(~r/^\d*$/, last), do: rest, else: ref
    end
  end

  defp rsplit_once(str, sep) do
    case :binary.matches(str, sep) do
      [] ->
        nil

      matches ->
        {start, len} = List.last(matches)
        {binary_part(str, 0, start), binary_part(str, start + len, byte_size(str) - start - len)}
    end
  end

  defp normalize_slashes(input), do: String.replace(input, "\\", "/")
end
