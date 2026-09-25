defmodule Glossia.Translations.RepoGlossaryTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.RepoGlossary

  describe "parse/1" do
    test "returns an empty list when the document is nil or empty" do
      assert {:ok, []} = RepoGlossary.parse(nil)
      assert {:ok, []} = RepoGlossary.parse(%{})
      assert {:ok, []} = RepoGlossary.parse(%{"entries" => []})
    end

    test "derives logical keys from source when none is given" do
      {:ok, entries} =
        RepoGlossary.parse(%{
          "entries" => [
            %{"source" => "Version-control commit", "targets" => %{"es" => "confirmación"}}
          ]
        })

      assert [%{logical_key: "version-control-commit", source: "Version-control commit"}] =
               entries
    end

    test "keeps caller-provided identifiers verbatim" do
      {:ok, entries} =
        RepoGlossary.parse(%{
          "entries" => [
            %{"id" => "vcs-commit", "source" => "commit", "targets" => %{"es" => "confirmación"}}
          ]
        })

      assert [%{logical_key: "vcs-commit"}] = entries
    end

    test "rejects duplicate identifiers" do
      assert {:error, "glossary has duplicate entry id `commit`"} =
               RepoGlossary.parse(%{
                 "entries" => [
                   %{"id" => "commit", "source" => "commit"},
                   %{"id" => "commit", "source" => "commit-noun"}
                 ]
               })
    end

    test "rejects entries with missing source" do
      assert {:error, "glossary entry is missing `source`"} =
               RepoGlossary.parse(%{"entries" => [%{"targets" => %{}}]})
    end

    test "rejects entries with an empty translation" do
      assert {:error, message} =
               RepoGlossary.parse(%{
                 "entries" => [%{"source" => "commit", "targets" => %{"es" => "   "}}]
               })

      assert message =~ "empty translation for `es`"
    end
  end

  describe "resolve_for_locale/2" do
    test "picks the most specific target locale" do
      {:ok, entries} =
        RepoGlossary.parse(%{
          "entries" => [
            %{
              "source" => "commit",
              "targets" => %{"zh" => "提交", "zh-Hans" => "提交", "es" => "confirmación"}
            }
          ]
        })

      assert [%{translation: "提交", translation_locale: "zh-Hans"}] =
               RepoGlossary.resolve_for_locale(entries, "zh-Hans-CN")

      assert [%{translation: "confirmación", translation_locale: "es"}] =
               RepoGlossary.resolve_for_locale(entries, "es")

      assert [] = RepoGlossary.resolve_for_locale(entries, "ja")
    end

    test "namespaces repo entry ids so they never collide with account entry ids" do
      {:ok, entries} =
        RepoGlossary.parse(%{
          "entries" => [
            %{"id" => "commit", "source" => "commit", "targets" => %{"es" => "confirmación"}}
          ]
        })

      assert [%{id: "repo:commit", origin: :repo}] =
               RepoGlossary.resolve_for_locale(entries, "es")
    end
  end

  describe "content_hash/1" do
    test "is stable across entry order and target-map ordering" do
      {:ok, entries_a} =
        RepoGlossary.parse(%{
          "entries" => [
            %{"id" => "a", "source" => "a", "targets" => %{"es" => "eA", "fr" => "fA"}},
            %{"id" => "b", "source" => "b", "targets" => %{"fr" => "fB", "es" => "eB"}}
          ]
        })

      {:ok, entries_b} =
        RepoGlossary.parse(%{
          "entries" => [
            %{"id" => "b", "source" => "b", "targets" => %{"es" => "eB", "fr" => "fB"}},
            %{"id" => "a", "source" => "a", "targets" => %{"fr" => "fA", "es" => "eA"}}
          ]
        })

      assert RepoGlossary.content_hash(entries_a) == RepoGlossary.content_hash(entries_b)
    end

    test "changes when a translation changes" do
      {:ok, entries_a} =
        RepoGlossary.parse(%{
          "entries" => [%{"id" => "a", "source" => "a", "targets" => %{"es" => "one"}}]
        })

      {:ok, entries_b} =
        RepoGlossary.parse(%{
          "entries" => [%{"id" => "a", "source" => "a", "targets" => %{"es" => "two"}}]
        })

      refute RepoGlossary.content_hash(entries_a) == RepoGlossary.content_hash(entries_b)
    end
  end

  describe "load/1" do
    test "returns an empty list when the file is absent" do
      dir =
        System.tmp_dir!()
        |> Path.join("glossia_repo_glossary_#{System.unique_integer([:positive])}")

      File.mkdir_p!(dir)
      on_exit(fn -> File.rm_rf!(dir) end)

      assert {:ok, []} = RepoGlossary.load(dir)
    end

    test "reads .glossia/glossary.yaml from the checkout root" do
      dir =
        System.tmp_dir!()
        |> Path.join("glossia_repo_glossary_#{System.unique_integer([:positive])}")

      File.mkdir_p!(Path.join(dir, ".glossia"))
      on_exit(fn -> File.rm_rf!(dir) end)

      File.write!(Path.join(dir, ".glossia/glossary.yaml"), """
      entries:
        - id: commit
          source: commit
          targets:
            es: confirmación
      """)

      assert {:ok, [%{logical_key: "commit", targets: %{"es" => "confirmación"}}]} =
               RepoGlossary.load(dir)
    end
  end
end
