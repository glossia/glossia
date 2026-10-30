defmodule Glossia.Editor.ContentTest do
  use ExUnit.Case, async: true

  alias Glossia.Editor.Content

  defp field_id(fields, value), do: Enum.find(fields, &(&1.value == value)).id

  test "nested asymmetric JSON objects and arrays expose only string leaves" do
    data = %{
      "a.b" => "literal dot",
      "a" => %{"b" => "nested", "0" => "object index"},
      "items" => ["first", %{"different" => [false, "deep"]}, 7, nil],
      "0" => "root key",
      "count" => 42,
      "flag" => true,
      "empty" => %{}
    }

    source = Jason.encode!(data)
    assert {:ok, fields} = Content.fields(:json, source)
    assert length(fields) == 6
    assert length(Enum.uniq_by(fields, & &1.id)) == 6
    assert Enum.all?(fields, &(Map.keys(&1) |> Enum.sort() == [:id, :label, :value]))
    assert Enum.any?(fields, &(&1.label == ~s($["a.b"])))
    assert Enum.any?(fields, &(&1.label == "$.items[1].different[1]"))

    assert {:ok, updated} =
             Content.update(:json, source, %{
               field_id(fields, "literal dot") => "new dot",
               field_id(fields, "deep") => "new deep"
             })

    assert Jason.decode!(updated) ==
             data
             |> Map.put("a.b", "new dot")
             |> put_in(["items", Access.at(1), "different", Access.at(1)], "new deep")
  end

  test "encoded paths distinguish delimiter-like keys and index types and are stable" do
    data = %{
      "a.b" => "one",
      "a" => %{"b" => "two"},
      "items" => ["three"],
      "items[0]" => "four",
      "" => "five",
      "~/" => "six"
    }

    assert {:ok, fields} = Content.fields("json", Jason.encode!(data))
    assert length(Enum.uniq_by(fields, & &1.id)) == 6
    assert {:ok, same_fields} = Content.fields(:json, Jason.encode!(Map.put(data, "new", 42)))
    assert fields == same_fields

    for field <- fields do
      assert {:ok, updated} = Content.update(:json, Jason.encode!(data), %{field.id => "changed"})
      assert {:ok, edited_fields} = Content.fields(:json, updated)
      assert Enum.count(edited_fields, &(&1.value == "changed")) == 1
    end

    assert {:ok, array_fields} = Content.fields(:json, ~s(["zero"]))
    assert {:ok, object_fields} = Content.fields(:json, ~s({"0":"zero"}))
    refute hd(array_fields).id == hd(object_fields).id
  end

  test "JSON edits preserve numeric lexemes, metadata, whitespace and untouched string escapes" do
    source =
      " \r\n" <>
        ~S({ "label":"Hello", "amount":1.0000000000000001, "scientific":-2.34000E-019, "nested": [true, {"value" : "Deep", "count":9007199254740993, "zero":-0.000, "exponent":1e+02}], "metadata":{"keep":"h\u0069\/there", "null":null} }) <>
        "\t\r\n"

    assert {:ok, fields} = Content.fields(:json, source)
    assert Enum.sort(Enum.map(fields, & &1.value)) == ["Deep", "Hello", "hi/there"]

    assert {:ok, updated} =
             Content.update(:json, source, %{
               field_id(fields, "Hello") => "Hi",
               field_id(fields, "Deep") => "Longer nested string",
               field_id(fields, "hi/there") => "hi/there"
             })

    assert updated ==
             source
             |> String.replace(~S("Hello"), ~S("Hi"))
             |> String.replace(~S("Deep"), ~S("Longer nested string"))

    assert {:ok, edited} = Content.fields(:json, updated)
    assert Enum.map(edited, & &1.id) == Enum.map(fields, & &1.id)
  end

  test "JSON token spans use bytes for Unicode and preserve escaped keys and adjacent values" do
    source =
      ~S({"é😀":"雪", "qu\"ote\\key": {"a.b":[["say \"hi\" \\ end", "\u96ea\/\uD83D\uDE00"]]}, "a":{"b":"other"}, "tail":"last"})

    assert {:ok, fields} = Content.fields(:json, source)
    assert length(fields) == 5
    assert length(Enum.uniq_by(fields, & &1.id)) == 5
    assert Enum.any?(fields, &(&1.label == ~S($["qu\"ote\\key"]["a.b"][0][0])))
    assert Enum.any?(fields, &(&1.value == "雪/😀"))

    replacements = [
      {"雪", "é😀\n\"quoted\"\\"},
      {"say \"hi\" \\ end", "新\tvalue\r\n"},
      {"last", "終"}
    ]

    assert {:ok, updated} =
             Content.update(
               :json,
               source,
               Map.new(replacements, fn {old, new} ->
                 {field_id(fields, old), new}
               end)
             )

    expected =
      source
      |> String.replace(~S("雪"), Jason.encode!("é😀\n\"quoted\"\\"))
      |> String.replace(~S("say \"hi\" \\ end"), Jason.encode!("新\tvalue\r\n"))
      |> String.replace(~S("last"), Jason.encode!("終"))

    assert updated == expected

    assert Jason.decode!(updated) ==
             source
             |> Jason.decode!()
             |> Map.put("é😀", "é😀\n\"quoted\"\\")
             |> put_in(["qu\"ote\\key", "a.b", Access.at(0), Access.at(0)], "新\tvalue\r\n")
             |> Map.put("tail", "終")
  end

  test "JSON duplicate decoded keys fail closed even in uneditable nested metadata" do
    for source <- [
          ~S({"label":"first","label":"second"}),
          ~S({"label":"first","\u006cabel":"second"}),
          ~S({"label":"Hello","metadata":[{"amount":1,"amount":2}]}),
          ~S({"nested":{"same":"first","same":{"child":"second"}}}),
          ~S({"qu\"ote":true,"qu\u0022ote":false})
        ] do
      assert {:error, "unsupported JSON: duplicate object keys are not editable"} =
               Content.fields(:json, source)

      assert {:error, "unsupported JSON: duplicate object keys are not editable"} =
               Content.update(:json, source, %{})

      assert {:error, "unsupported JSON: duplicate object keys are not editable"} =
               Content.update(:json, source, %{"forged" => "changed"})
    end

    assert {:ok, fields} =
             Content.fields(:json, ~S([{"same":"first"},{"same":"second"}]))

    assert length(fields) == 2
    refute hd(fields).id == List.last(fields).id
  end

  test "JSON root strings and nested arrays splice only the selected tokens" do
    assert {:ok, [field]} = Content.fields(:json, ~S( "h\u0069" ))
    assert field.label == "$"

    assert Content.update(:json, ~S( "h\u0069" ), %{field.id => "bye"}) ==
             {:ok, ~S( "bye" )}

    source = ~S([1e02, [[], {}, ["nested", false]], null, "tail"])
    assert {:ok, fields} = Content.fields(:json, source)
    assert Enum.map(fields, & &1.label) == ["$[1][2][0]", "$[3]"]

    assert Content.update(:json, source, %{field_id(fields, "nested") => "changed"}) ==
             {:ok, ~S([1e02, [[], {}, ["changed", false]], null, "tail"])}
  end

  test "all formats preserve exact bytes on empty and unchanged submissions" do
    for {format, source} <- [
          {:json, " {\r\n  \"name\" : \"h\\u0069\", \"n\": 1e2 } \n"},
          {:yaml, "# header\r\ntitle: 'hi' # keep\r\ndescription: |-\r\n  first\r\n  second\r\n"},
          {:markdown, "---\r\ntitle: hi # keep\r\ncount: 3\r\n---\r\n\r\n# Body\r\n"},
          {:text, "  hello\r\n\n"}
        ] do
      assert {:ok, fields} = Content.fields(format, source)
      assert Content.update(format, source, %{}) == {:ok, source}
      assert Content.update(format, source, Map.new(fields, &{&1.id, &1.value})) == {:ok, source}
    end
  end

  test "rejects unknown IDs and non-string values, even with no legitimate changes" do
    for {format, source} <- [
          {:json, ~s({"count":3,"title":"hi"})},
          {:yaml, "title: hi\n"},
          {:markdown, "Body"},
          {:text, "hi"}
        ] do
      assert {:ok, [field | _]} = Content.fields(format, source)

      assert {:error, "unrecognized field ID"} =
               Content.update(format, source, %{"forged" => "bad"})

      assert {:error, "unrecognized field ID"} =
               Content.update(format, source, %{field.id => field.value, "forged" => "bad"})

      assert {:error, _} = Content.update(format, source, %{field.id => 42})
      assert {:error, _} = Content.update(format, source, %{field.id => <<255>>})
    end
  end

  test "YAML nested objects, string arrays and typed values retain comments and untouched bytes" do
    source =
      "# heading\n'a.b': literal\na:\n  b: nested # inline\nitems:\n  - first\n  - other: deep\nnumber: 2.5\nflag: true\nnull_value: null\n"

    assert {:ok, fields} = Content.fields(:yaml, source)
    assert length(fields) == 4

    assert {:ok, updated} =
             Content.update(:yaml, source, %{
               field_id(fields, "nested") => "false",
               field_id(fields, "first") => "a: b # c"
             })

    assert updated ==
             String.replace(source, "b: nested", ~s(b: "false"))
             |> String.replace("- first", ~s(- "a: b # c"))

    assert {:ok, decoded} = YamlElixir.read_from_string(updated)
    assert decoded["number"] === 2.5
    assert decoded["flag"] === true
    assert decoded["null_value"] === nil
    assert decoded["a"]["b"] === "false"
  end

  test "multiline YAML strings can be updated without losing adjacent metadata or comments" do
    source = "title: hi\ndescription: |- # explanation\n  first\n  second\ncount: 4\n"
    assert {:ok, fields} = Content.fields(:yaml, source)

    assert {:ok, updated} =
             Content.update(:yaml, source, %{field_id(fields, "first\nsecond") => "new\nlines\n"})

    assert updated == "title: hi\ndescription: \"new\\nlines\\n\" # explanation\ncount: 4\n"

    assert {:ok, %{"description" => "new\nlines\n", "count" => 4}} =
             YamlElixir.read_from_string(updated)
  end

  test "YAML empty, nested, explicitly indented and root block strings round-trip safely" do
    for source <- [
          "empty: |-\nnext: text\n",
          "items:\n  - description: |2-\n      indented\n    next: text\n",
          "description: |2-\n    extra\n  less\nnext: hi\n",
          "description: |+\n  text\n\nnext: text\n",
          "|-\n  root text\n",
          "|-\nroot text\n...\n# tail\n",
          "description: |\n  final line"
        ] do
      assert {:ok, fields} = Content.fields(:yaml, source)
      assert Content.update(:yaml, source, Map.new(fields, &{&1.id, &1.value})) == {:ok, source}

      assert {:ok, updated} =
               Content.update(:yaml, source, Map.new(fields, &{&1.id, &1.value <> " edited"}))

      assert {:ok, edited} = Content.fields(:yaml, updated)
      assert Enum.map(edited, & &1.value) == Enum.map(fields, &(&1.value <> " edited"))

      if String.contains?(source, "# tail"),
        do: assert(String.ends_with?(updated, "...\n# tail\n"))
    end
  end

  test "YAML quoted scalars, Unicode byte positions, flow arrays and delimiter-like strings" do
    source =
      "é: 'it''s fine' # keep\n数组: [plain, \"quoted \\\"ok\\\"\", 3, false, null]\npunctuation: words, [brackets] # keep\n"

    assert {:ok, fields} = Content.fields(:yaml, source)

    assert {:ok, updated} =
             Content.update(:yaml, source, Map.new(fields, &{&1.id, &1.value <> "!"}))

    assert {:ok, edited} = Content.fields(:yaml, updated)
    assert Enum.map(edited, & &1.value) == Enum.map(fields, &(&1.value <> "!"))
    assert String.contains?(updated, "# keep")
  end

  test "Markdown edits body and frontmatter strings, never raw metadata or typed values" do
    source =
      "---\r\n# metadata\r\ntitle: Hello\r\nsummary: >-\r\n  first\r\n  second\r\ntags: [one, two]\r\ncount: 3\r\ndraft: false\r\n---\r\n\r\n# Body\r\n"

    assert {:ok, fields} = Content.fields(:markdown, source)
    assert Enum.find(fields, &(&1.id == "body")).value == "\r\n# Body\r\n"
    assert length(fields) == 5

    assert {:ok, body_only} = Content.update(:markdown, source, %{"body" => "New body\n"})
    assert body_only == String.replace_suffix(source, "\r\n# Body\r\n", "New body\n")

    assert {:ok, updated} =
             Content.update(:markdown, source, %{
               field_id(fields, "Hello") => "true",
               field_id(fields, "first second") => "new\nsummary",
               "body" => "Changed body"
             })

    assert String.contains?(updated, "# metadata\r\ntitle: \"true\"\r\n")
    assert String.contains?(updated, "count: 3\r\ndraft: false\r\n---\r\nChanged body")
    assert {:ok, edited} = Content.fields(:markdown, updated)
    assert Enum.any?(edited, &(&1.value == "new\nsummary"))
  end

  test "plain Markdown and text expose one whole-body field" do
    assert {:ok, [%{id: "body", label: "Body", value: "# Hi\n"}]} =
             Content.fields(:markdown, "# Hi\n")

    assert Content.update(:markdown, "# Hi\n", %{"body" => "# New"}) == {:ok, "# New"}
    assert Content.update(:text, "hi", %{"text" => "bye"}) == {:ok, "bye"}
    assert {:ok, [%{value: ""}]} = Content.fields(:text, "")
  end

  test "unsafe YAML fails closed before extraction or update" do
    for source <- [
          "a: &anchor hello\nb: *anchor\n",
          "a: !custom value\n",
          "a: !!str 42\n",
          "a: ! value\n",
          "%YAML 1.2\n---\na: hello\n",
          "a: first\na: second\n",
          "<<: {a: hello}\n",
          "3: hello\n",
          "? [a, b]\n: hello\n",
          "a: first\n---\nb: second\n",
          "a: first\n  second\n"
        ] do
      assert {:error, reason} = Content.fields(:yaml, source)
      assert is_binary(reason)
      assert {:error, _} = Content.update(:yaml, source, %{})
    end

    assert {:ok, _} = Content.fields(:yaml, "a: 'literal &anchor !tag *alias' # &comment\n")
    assert {:error, _} = Content.fields(:markdown, "---\na: &anchor hi\n---\nBody")
  end

  test "invalid input and unsupported frontmatter fail clearly" do
    assert {:error, _} = Content.fields(:json, "{")
    assert {:error, _} = Content.fields(:yaml, "a: [")
    assert {:error, _} = Content.fields(:markdown, "---\ntitle: hi\n")
    assert {:error, _} = Content.fields(:markdown, "+++\ntitle = \"hi\"\n+++\nBody")
    assert {:error, _} = Content.fields(:markdown, "%{title: \"hi\"}\n---\nBody")
    assert {:error, _} = Content.fields(:unknown, "hello")
    assert {:ok, []} = Content.fields(:json, "[3, true, null, {}]")
    assert {:ok, []} = Content.fields(:yaml, "# empty\n")
  end
end
