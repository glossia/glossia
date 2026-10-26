defmodule Glossia.LinguisticReviews.RepositoryContextTest do
  use ExUnit.Case, async: true

  alias Glossia.LinguisticReviews.RepositoryContext
  alias Glossia.Translations.DocumentSpec
  alias Glossia.Translations.Frontmatter

  defstruct [:id, :guidance, :context_path, :context_digest, :source_text]

  @first_id "00000000-0000-4000-8000-000000000001"
  @second_id "00000000-0000-4000-8000-000000000002"

  setup do
    root = Path.join(System.tmp_dir!(), "repository-context-#{Ecto.UUID.generate()}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    {:ok, root: root}
  end

  test "proposes an absent nested locale overlay without creating directories", %{root: root} do
    review = review("docs/product/L10N/pt-BR.md", nil, "Use ‘espaço de trabalho’.")

    assert {:ok, [proposal]} = RepositoryContext.proposals(root, [review])
    assert proposal.path == review.context_path
    assert proposal.status == "added"
    assert proposal.review_ids == [@first_id]
    assert String.starts_with?(proposal.content, "---\nlocale: pt-BR\n---\n\n")
    assert proposal.content =~ "## Linguistic review decision (pt-BR)"
    assert proposal.content =~ review.guidance
    assert proposal.content =~ "<!-- glossia:linguistic-review:#{@first_id} -->"
    assert {:ok, %{frontmatter: frontmatter}} = Frontmatter.parse_content(proposal.content)
    assert :ok = DocumentSpec.validate_document(proposal.path, frontmatter)
    assert File.ls!(root) == []
  end

  test "preserves YAML, comments, CRLF, body and trailing whitespace verbatim", %{root: root} do
    original =
      "---\r\n# Keep this comment\r\nsource_language: en\r\nmodel: 'openai/gpt-5'\r\n---\r\n\r\n# Voice\r\n\r\nExisting prose.  \r\n\r\n"

    write(root, "L10N.md", original)

    review =
      review("L10N.md", original, "Use informal language.\n\nKeep product names unchanged.  ")

    assert {:ok, [%{status: "modified", content: content}]} =
             RepositoryContext.proposals(root, [review])

    assert binary_part(content, 0, byte_size(original)) == original
    assert content =~ review.guidance
    assert File.read!(Path.join(root, "L10N.md")) == original
  end

  test "groups by file and sorts paths and decisions deterministically", %{root: root} do
    original = "# Scoped voice\n"
    write(root, "docs/L10N.md", original)
    first = review("docs/L10N.md", original, "First decision.")
    second = %{review("docs/L10N.md", original, "Second decision.") | id: @second_id}
    locale = %{review("L10N/es.md", nil, "Usa un tono cercano.") | id: Ecto.UUID.generate()}

    assert {:ok, [overlay, scoped] = proposals} =
             RepositoryContext.proposals(root, [second, locale, first, first])

    assert {:ok, ^proposals} = RepositoryContext.proposals(root, [first, second, locale])
    assert overlay.path == "L10N/es.md"
    assert scoped.path == "docs/L10N.md"
    assert scoped.review_ids == [@first_id, @second_id]
    assert [_, middle, _] = String.split(scoped.content, ["First decision.", "Second decision."])
    assert middle =~ @second_id
    assert File.read!(Path.join(root, "docs/L10N.md")) == original
    refute File.exists?(Path.join(root, "L10N"))
  end

  test "replaying exact decisions is a no-op with original or refreshed digests", %{root: root} do
    for {path, original} <- [{"L10N/es.md", nil}, {"docs/L10N.md", "Existing prose."}] do
      if original, do: write(root, path, original)
      item = review(path, original, "Keep the chosen term.")
      assert {:ok, [proposal]} = RepositoryContext.proposals(root, [item])
      write(root, path, proposal.content)

      assert {:ok, []} = RepositoryContext.proposals(root, [item])

      assert {:ok, []} =
               RepositoryContext.proposals(root, [
                 %{item | context_digest: digest(proposal.content)}
               ])
    end
  end

  test "replay checks full marker-delimited guidance, not just an ID", %{root: root} do
    item = review("L10N/es.md", nil, "Original decision.")
    assert {:ok, [proposal]} = RepositoryContext.proposals(root, [item])
    write(root, item.context_path, proposal.content)

    assert {:error, :guidance_conflict} =
             RepositoryContext.proposals(root, [%{item | guidance: "Changed decision."}])

    for content <- [
          String.replace(proposal.content, "Original decision.", "Edited in repository."),
          String.replace(
            proposal.content,
            "<!-- /glossia:linguistic-review:#{@first_id} -->",
            ""
          ),
          proposal.content <> proposal.content
        ] do
      write(root, item.context_path, content)
      assert {:error, :guidance_conflict} = RepositoryContext.proposals(root, [item])
    end
  end

  test "can append a current decision alongside an exact replay", %{root: root} do
    first = review("L10N/es.md", nil, "First decision.")
    assert {:ok, [proposal]} = RepositoryContext.proposals(root, [first])
    write(root, first.context_path, proposal.content)
    second = %{review(first.context_path, proposal.content, "Second decision.") | id: @second_id}

    assert {:ok, [%{content: content, review_ids: [@first_id, @second_id]}]} =
             RepositoryContext.proposals(root, [second, first])

    assert String.starts_with?(content, proposal.content)
    assert length(:binary.matches(content, "First decision.")) == 1
    assert content =~ "Second decision."
  end

  test "rejects stale, deleted, newly present, or inconsistent original snapshots", %{root: root} do
    original = "Original prose."
    item = review("docs/L10N.md", original, "Decision.")
    write(root, item.context_path, "Changed prose.")
    assert {:error, :context_changed} = RepositoryContext.proposals(root, [item])
    assert File.read!(Path.join(root, item.context_path)) == "Changed prose."

    File.rm!(Path.join(root, item.context_path))
    assert {:error, :context_changed} = RepositoryContext.proposals(root, [item])
    write(root, item.context_path, original)

    assert {:error, :context_changed} =
             RepositoryContext.proposals(root, [%{item | context_digest: nil}])

    stale = %{review(item.context_path, "Stale prose.", "Other decision.") | id: @second_id}
    assert {:error, :context_changed} = RepositoryContext.proposals(root, [item, stale])
  end

  test "rejects traversal, absolute, malformed and non-context paths", %{root: root} do
    for path <- [
          "../L10N.md",
          "docs/../L10N.md",
          "./L10N.md",
          "docs/./L10N.md",
          "/L10N.md",
          Path.join(root, "L10N.md"),
          "docs//L10N.md",
          "L10N.md/",
          "docs\\L10N.md",
          "L10N/es.md\0",
          "README.md",
          "L10N/es/extra.md",
          "L10N/not_a_locale.md",
          "L10N/en-US!.md",
          "L10N/.md",
          "L10N/es.yaml"
        ] do
      assert {:error, :unsafe_context_path} =
               RepositoryContext.proposals(root, [review(path, nil, "Decision.")]),
             path
    end
  end

  test "rejects symlink roots, ancestors, files, dangling links and special files", %{root: root} do
    outside = root <> "-outside"
    File.mkdir_p!(outside)
    on_exit(fn -> File.rm_rf!(outside) end)
    File.write!(Path.join(outside, "L10N.md"), "Outside context.")
    File.ln_s!(outside, Path.join(root, "linked"))
    File.ln_s!(Path.join(outside, "L10N.md"), Path.join(root, "L10N.md"))
    File.ln_s!(Path.join(root, "missing"), Path.join(root, "dangling"))

    for path <- ["linked/L10N.md", "L10N.md", "dangling/L10N.md"] do
      assert {:error, :unsafe_context_path} =
               RepositoryContext.proposals(root, [review(path, nil, "Decision.")])
    end

    assert {:error, :unsafe_context_path} =
             RepositoryContext.proposals(Path.join(root, "linked"), [])

    assert {:error, :unsafe_context_path} =
             RepositoryContext.proposals(Path.join(outside, "L10N.md"), [])

    assert File.read!(Path.join(outside, "L10N.md")) == "Outside context."

    File.mkdir_p!(Path.join(root, "directory/L10N.md"))

    assert {:error, :unsafe_context_path} =
             RepositoryContext.proposals(root, [review("directory/L10N.md", nil, "Decision.")])

    fifo = Path.join(root, "fifo/L10N.md")
    File.mkdir_p!(Path.dirname(fifo))
    assert {_, 0} = MuonTrap.cmd("mkfifo", [fifo], into: "", timeout: 5_000)

    assert {:error, :unsafe_context_path} =
             RepositoryContext.proposals(root, [review("fifo/L10N.md", nil, "Decision.")])
  end

  test "supports absent scoped prose but does not invent global source_language", %{root: root} do
    assert {:ok, [%{status: "added", content: content}]} =
             RepositoryContext.proposals(root, [review("docs/L10N.md", nil, "Use concise prose.")])

    refute String.starts_with?(content, "---")

    assert {:error, :invalid_context_document} =
             RepositoryContext.proposals(root, [review("L10N.md", nil, "Use concise prose.")])
  end

  test "never reuses source prose when guidance is omitted and accepts structs and string keys",
       %{root: root} do
    for guidance <- [nil, "", " \n\t"] do
      assert {:ok, []} =
               RepositoryContext.proposals(root, [
                 %{guidance: guidance, source_text: "Not approved guidance."}
               ])
    end

    item = review("L10N/zh-Hans.md", nil, "使用简体中文。")
    string_keys = Map.new(item, fn {key, value} -> {Atom.to_string(key), value} end)
    # A struct with unrelated fields still uses only the explicitly supplied fields.
    struct_review = struct!(__MODULE__, Map.put(item, :source_text, "Not approved guidance."))
    assert {:ok, [proposal]} = RepositoryContext.proposals(root, [struct_review])
    refute proposal.content =~ "Not approved guidance."
    assert {:ok, [^proposal]} = RepositoryContext.proposals(root, [string_keys])
  end

  test "bounds guidance, document sizes, and invalid inputs", %{root: root} do
    item = review("docs/L10N.md", nil, String.duplicate("é", 8_000))
    assert {:ok, [_]} = RepositoryContext.proposals(root, [item])

    for guidance <- [
          123,
          <<255>>,
          String.duplicate("a", 8_001),
          "<!-- glossia:linguistic-review:#{@second_id} -->"
        ] do
      assert {:error, :invalid_guidance} =
               RepositoryContext.proposals(root, [%{item | guidance: guidance}])
    end

    for invalid <- [
          %{item | id: "not-a-uuid"},
          %{item | context_digest: "A" <> String.duplicate("0", 63)},
          :invalid
        ] do
      assert {:error, :invalid_review} = RepositoryContext.proposals(root, [invalid])
    end

    assert {:error, :guidance_conflict} =
             RepositoryContext.proposals(root, [item, %{item | guidance: "Changed."}])

    original = String.duplicate("a", 1_048_576)
    write(root, item.context_path, original)

    assert {:error, :context_too_large} =
             RepositoryContext.proposals(root, [review(item.context_path, original, "Decision.")])

    write(root, item.context_path, original <> "a")
    assert {:error, :context_too_large} = RepositoryContext.proposals(root, [item])
  end

  test "returns bounded errors for invalid repository frontmatter or text", %{root: root} do
    for original <- [
          "---\nmodel: [\n---\nBody",
          "---\nmodel: \"\"\n---\nBody",
          "---\nsources: {a: {nested: value}}\n---\nBody",
          <<255>>
        ] do
      write(root, "docs/L10N.md", original)

      assert {:error, :invalid_context_document} =
               RepositoryContext.proposals(root, [review("docs/L10N.md", original, "Decision.")])
    end
  end

  defp review(path, original, guidance) do
    %{
      id: @first_id,
      context_path: path,
      context_digest: if(is_nil(original), do: nil, else: digest(original)),
      guidance: guidance
    }
  end

  defp digest(content), do: Base.encode16(:crypto.hash(:sha256, content), case: :lower)

  defp write(root, path, content) do
    absolute = Path.join(root, path)
    File.mkdir_p!(Path.dirname(absolute))
    File.write!(absolute, content)
  end
end
