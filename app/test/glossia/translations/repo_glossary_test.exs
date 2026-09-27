defmodule Glossia.Translations.RepoGlossaryTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.RepoGlossary

  describe "resolve/3" do
    test "returns no entries when neither terms nor translations are declared" do
      assert {:ok, []} = RepoGlossary.resolve(nil, nil, "es")
    end

    test "a term without a translation for the locale produces no entry" do
      assert {:ok, []} = RepoGlossary.resolve([%{"source" => "commit"}], nil, "es")
    end

    test "joins a term with its translation keyed by source" do
      terms = [%{"source" => "commit", "definition" => "The version-control action."}]

      assert {:ok, [entry]} = RepoGlossary.resolve(terms, %{"commit" => "commit"}, "es")

      assert entry == %{
               id: "repo:commit",
               namespaced_id: "repo:commit",
               logical_key: "commit",
               origin: :repo,
               term: "commit",
               definition: "The version-control action.",
               case_sensitive: false,
               translation: "commit",
               translation_locale: "es"
             }
    end

    test "joins a term with its translation keyed by id" do
      terms = [%{"id" => "vcs-branch", "source" => "branch", "case_sensitive" => true}]

      assert {:ok, [entry]} = RepoGlossary.resolve(terms, %{"vcs-branch" => "rama"}, "es")
      assert %{term: "branch", translation: "rama", case_sensitive: true} = entry
      assert entry.namespaced_id == "repo:vcs-branch"
    end

    test "a locale can declare a term the base L10N.md does not" do
      assert {:ok, [entry]} = RepoGlossary.resolve(nil, %{"pull request" => "pull request"}, "es")
      assert %{term: "pull request", logical_key: "pull-request", definition: nil} = entry
    end

    test "rejects a term that declares targets" do
      assert {:error, message} =
               RepoGlossary.resolve(
                 [%{"source" => "commit", "targets" => %{"es" => "c"}}],
                 nil,
                 "es"
               )

      assert message =~ "translations belong in L10N/<locale>.md"
    end

    test "rejects a term without a source" do
      assert {:error, "glossary term is missing `source`"} =
               RepoGlossary.resolve([%{"definition" => "x"}], nil, "es")
    end

    test "rejects duplicate term ids" do
      assert {:error, "glossary has duplicate term id `commit`"} =
               RepoGlossary.resolve(
                 [%{"source" => "commit"}, %{"id" => "commit", "source" => "commit-noun"}],
                 nil,
                 "es"
               )
    end

    test "rejects wrongly typed term fields" do
      assert {:error, message} =
               RepoGlossary.resolve([%{"source" => "API", "case_sensitive" => "true"}], nil, "es")

      assert message =~ "case_sensitive"

      assert {:error, message} = RepoGlossary.resolve([%{"id" => 42, "source" => "x"}], nil, "es")
      assert message =~ "non-string `id`"
    end

    test "rejects terms that are not a list and translations that are not a map" do
      assert {:error, _} = RepoGlossary.resolve(%{"commit" => "commit"}, nil, "es")
      assert {:error, _} = RepoGlossary.resolve(nil, [%{"source" => "commit"}], "es")
    end

    test "rejects empty or non-string translations" do
      assert {:error, message} = RepoGlossary.resolve(nil, %{"commit" => "  "}, "es")
      assert message =~ "is empty"

      assert {:error, message} = RepoGlossary.resolve(nil, %{"commit" => %{"a" => "b"}}, "es")
      assert message =~ "must be a string"
    end
  end
end
