defmodule Glossia.Translations.ContentSegmentsTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.ContentSegments

  test "keeps short prose in one segment" do
    content = "# Guide\n\nA short paragraph.\n"
    assert ContentSegments.split(content, max_segment_bytes: 100) == [String.trim(content)]
  end

  test "packs long prose at block boundaries without splitting protected blocks" do
    code = "```elixir\n\nIO.puts(\"hello\")\n\n```"

    content = """
    # Guide

    #{String.duplicate("First paragraph. ", 8)}

    #{code}

    ## Next

    #{String.duplicate("Second paragraph. ", 8)}
    """

    segments =
      ContentSegments.split(content,
        max_segment_bytes: 180,
        protected_delimiters: ["```", "~~~"]
      )

    assert length(segments) > 1
    assert Enum.count(segments, &String.contains?(&1, code)) == 1
    assert Enum.join(segments, "\n\n") =~ "## Next"
  end
end
