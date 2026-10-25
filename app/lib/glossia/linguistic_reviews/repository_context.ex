defmodule Glossia.LinguisticReviews.RepositoryContext do
  @moduledoc """
  Builds repository-context proposals from explicitly edited review guidance.

  `proposals/2` only reads the checkout. Reviews are maps or structs with `id`,
  `guidance`, `context_path`, and `context_digest` fields (string keys also work).
  Nil or blank guidance is omitted; other guidance must be valid UTF-8 with at
  most 8,000 characters. No source text or other review fields are reused.

  Results are sorted by path, with decisions sorted by UUID. Each proposal has
  `path`, `status`, `content`, and sorted `review_ids` provenance. The original
  bytes are preserved as a prefix, including frontmatter and trailing whitespace.
  Output is limited to 1 MiB per file.

  An exact, marker-delimited replay produces no change, even with the original
  digest. Different guidance for an already recorded UUID is a conflict. Every
  not-yet-recorded decision for a file must reference its current SHA-256 digest
  (or nil for an absent file). Digests are checked once per file, before appending.

  Missing locale overlays get minimal YAML frontmatter. Missing scoped L10N.md
  files can start with empty prose; a missing global L10N.md cannot be invented,
  because DocumentSpec requires a source_language there.

  Errors are bounded atoms: `:context_changed`, `:unsafe_context_path`,
  `:invalid_review`, `:invalid_guidance`, `:guidance_conflict`,
  `:invalid_context_document`, `:context_too_large`, or `:context_unreadable`.
  Callers must revalidate the checkout when applying a proposal; this helper
  neither locks it nor writes files, git commits, or pull requests.
  """

  alias Glossia.Translations.DocumentSpec
  alias Glossia.Translations.Frontmatter

  @max_file_bytes 1_048_576
  @max_guidance_characters 8_000
  @uuid ~r/\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\z/
  @digest ~r/\A[0-9a-f]{64}\z/
  @locale ~r/\A[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*\z/

  @doc "Returns proposed context-file contents without changing the checkout."
  def proposals(repo_root, reviews) when is_binary(repo_root) and is_list(reviews) do
    with {:ok, root} <- directory_root(repo_root),
         {:ok, normalized} <- normalize_reviews(reviews) do
      normalized
      |> Enum.group_by(& &1.context_path)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.reduce_while({:ok, []}, fn {path, items}, {:ok, proposals} ->
        case propose(root, path, Enum.sort_by(items, & &1.id)) do
          {:ok, nil} -> {:cont, {:ok, proposals}}
          {:ok, proposal} -> {:cont, {:ok, [proposal | proposals]}}
          {:error, _} = error -> {:halt, error}
        end
      end)
      |> case do
        {:ok, proposals} -> {:ok, Enum.reverse(proposals)}
        error -> error
      end
    end
  end

  def proposals(_, _), do: {:error, :invalid_review}

  defp normalize_reviews(reviews) do
    Enum.reduce_while(reviews, {:ok, %{}}, fn review, {:ok, by_id} ->
      case normalize_review(review) do
        {:ok, nil} ->
          {:cont, {:ok, by_id}}

        {:ok, item} ->
          case Map.fetch(by_id, item.id) do
            :error -> {:cont, {:ok, Map.put(by_id, item.id, item)}}
            {:ok, ^item} -> {:cont, {:ok, by_id}}
            {:ok, _} -> {:halt, {:error, :guidance_conflict}}
          end

        {:error, _} = error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, by_id} -> {:ok, Map.values(by_id)}
      error -> error
    end
  end

  defp normalize_review(review) when is_map(review) do
    guidance = field(review, :guidance)

    cond do
      is_nil(guidance) ->
        {:ok, nil}

      not is_binary(guidance) or byte_size(guidance) > @max_guidance_characters * 4 ->
        {:error, :invalid_guidance}

      not String.valid?(guidance) or String.length(guidance) > @max_guidance_characters ->
        {:error, :invalid_guidance}

      String.trim(guidance) == "" ->
        {:ok, nil}

      String.contains?(guidance, [
        "<!-- glossia:linguistic-review:",
        "<!-- /glossia:linguistic-review:"
      ]) ->
        {:error, :invalid_guidance}

      true ->
        normalize_fields(review, guidance)
    end
  end

  defp normalize_review(_), do: {:error, :invalid_review}

  defp normalize_fields(review, guidance) do
    id = field(review, :id)
    path = field(review, :context_path)
    digest = field(review, :context_digest)

    with true <- is_binary(id) and Regex.match?(@uuid, id),
         true <- is_nil(digest) or (is_binary(digest) and Regex.match?(@digest, digest)),
         {:ok, _kind} <- context_kind(path) do
      {:ok,
       %{id: String.downcase(id), guidance: guidance, context_path: path, context_digest: digest}}
    else
      false -> {:error, :invalid_review}
      {:error, _} = error -> error
    end
  end

  defp field(review, key), do: Map.get(review, key, Map.get(review, Atom.to_string(key)))

  defp context_kind(path) when is_binary(path) do
    segments = String.split(path, "/")

    if String.valid?(path) and not String.contains?(path, ["\\", <<0>>]) and
         Enum.all?(segments, &(&1 not in ["", ".", ".."])) and
         Path.type(path) == :relative do
      case DocumentSpec.classify(path) do
        {:ok, {:locale_overlay, locale}} = result ->
          if Regex.match?(@locale, locale), do: result, else: {:error, :unsafe_context_path}

        {:ok, kind} ->
          {:ok, kind}

        {:error, _} ->
          {:error, :unsafe_context_path}
      end
    else
      {:error, :unsafe_context_path}
    end
  end

  defp context_kind(_), do: {:error, :unsafe_context_path}

  defp directory_root(root) do
    if String.valid?(root) and root != "" and not String.contains?(root, <<0>>) do
      expanded = Path.expand(root)

      case File.lstat(expanded) do
        {:ok, %{type: :directory}} -> {:ok, expanded}
        _ -> {:error, :unsafe_context_path}
      end
    else
      {:error, :unsafe_context_path}
    end
  end

  defp propose(root, path, reviews) do
    with {:ok, original} <- read_context(root, path),
         {:ok, pending} <- pending_reviews(original || "", path, reviews),
         :ok <- check_digest(original, pending) do
      build_proposal(path, original, pending, reviews)
    end
  end

  defp read_context(root, path) do
    case walk_path(root, String.split(path, "/")) do
      :absent -> {:ok, nil}
      :regular -> read_regular(Path.join(root, path))
      {:error, _} = error -> error
    end
  end

  defp walk_path(parent, [segment | rest]) do
    path = Path.join(parent, segment)

    case File.lstat(path) do
      {:ok, %{type: :directory}} when rest != [] -> walk_path(path, rest)
      {:ok, %{type: :regular, size: size}} when rest == [] and size <= @max_file_bytes -> :regular
      {:ok, %{type: :regular}} when rest == [] -> {:error, :context_too_large}
      {:ok, _} -> {:error, :unsafe_context_path}
      {:error, :enoent} -> :absent
      {:error, _} -> {:error, :context_unreadable}
    end
  end

  defp read_regular(path) do
    case File.open(path, [:read, :binary], &IO.binread(&1, @max_file_bytes + 1)) do
      {:ok, :eof} ->
        {:ok, ""}

      {:ok, content} when is_binary(content) and byte_size(content) > @max_file_bytes ->
        {:error, :context_too_large}

      {:ok, content} when is_binary(content) ->
        if String.valid?(content), do: {:ok, content}, else: {:error, :invalid_context_document}

      _ ->
        {:error, :context_unreadable}
    end
  end

  defp pending_reviews(content, path, reviews) do
    Enum.reduce_while(reviews, {:ok, []}, fn review, {:ok, pending} ->
      {start_marker, end_marker} = markers(review.id)
      starts = :binary.matches(content, start_marker)
      ends = :binary.matches(content, end_marker)

      cond do
        starts == [] and ends == [] ->
          {:cont, {:ok, [review | pending]}}

        length(starts) == 1 and length(ends) == 1 and
            String.contains?(content, decision(path, review)) ->
          {:cont, {:ok, pending}}

        true ->
          {:halt, {:error, :guidance_conflict}}
      end
    end)
    |> case do
      {:ok, pending} -> {:ok, Enum.reverse(pending)}
      error -> error
    end
  end

  defp check_digest(_original, []), do: :ok

  defp check_digest(original, pending) do
    actual = if is_nil(original), do: nil, else: sha256(original)

    if Enum.all?(pending, &(&1.context_digest == actual)),
      do: :ok,
      else: {:error, :context_changed}
  end

  defp sha256(content), do: Base.encode16(:crypto.hash(:sha256, content), case: :lower)

  defp build_proposal(_path, _original, [], _reviews), do: {:ok, nil}

  defp build_proposal(path, original, pending, reviews) do
    base = original || initial_content(path)

    appended =
      Enum.reduce_while(pending, {:ok, base}, fn review, {:ok, content} ->
        updated = append_decision(content, decision(path, review))

        if byte_size(updated) <= @max_file_bytes,
          do: {:cont, {:ok, updated}},
          else: {:halt, {:error, :context_too_large}}
      end)

    with {:ok, content} <- appended,
         :ok <- validate_content(path, content) do
      {:ok,
       %{
         path: path,
         status: if(is_nil(original), do: "added", else: "modified"),
         content: content,
         review_ids: Enum.map(reviews, & &1.id)
       }}
    end
  end

  defp initial_content(path) do
    case context_kind(path) do
      {:ok, {:locale_overlay, locale}} -> "---\nlocale: #{locale}\n---\n"
      {:ok, _} -> ""
    end
  end

  defp append_decision("", decision), do: decision

  defp append_decision(content, decision) do
    separator =
      cond do
        String.ends_with?(content, "\n\n") -> ""
        String.ends_with?(content, "\n") -> "\n"
        true -> "\n\n"
      end

    content <> separator <> decision
  end

  defp decision(path, review) do
    {start_marker, end_marker} = markers(review.id)

    suffix =
      case context_kind(path) do
        {:ok, {:locale_overlay, locale}} -> " (#{locale})"
        {:ok, _} -> ""
      end

    "#{start_marker}\n## Linguistic review decision#{suffix}\n\n#{review.guidance}\n#{end_marker}\n"
  end

  defp markers(id),
    do: {"<!-- glossia:linguistic-review:#{id} -->", "<!-- /glossia:linguistic-review:#{id} -->"}

  defp validate_content(path, content) do
    with {:ok, %{frontmatter: frontmatter}} <- Frontmatter.parse_content(content),
         :ok <- DocumentSpec.validate_document(path, frontmatter) do
      :ok
    else
      _ -> {:error, :invalid_context_document}
    end
  rescue
    _ -> {:error, :invalid_context_document}
  end
end
