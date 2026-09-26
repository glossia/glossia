defmodule Glossia.Accounts.GlossaryEntryTest do
  use ExUnit.Case, async: true

  alias Glossia.Accounts.GlossaryEntry

  describe "slugify/1" do
    test "preserves distinguishing punctuation so common technical terms do not collide" do
      refute GlossaryEntry.slugify("C++") == GlossaryEntry.slugify("C#")
      refute GlossaryEntry.slugify("C++") == GlossaryEntry.slugify("C")
      refute GlossaryEntry.slugify(".NET") == GlossaryEntry.slugify("NET")
      refute GlossaryEntry.slugify("Foo & Bar") == GlossaryEntry.slugify("Foo Bar")
    end

    test "returns the term verbatim when nothing survives normalization" do
      assert GlossaryEntry.slugify("!!!") == "!!!"
    end

    test "produces deterministic output" do
      assert GlossaryEntry.slugify("Version-Control Commit") == "version-control-commit"
    end
  end

  describe "changeset/2" do
    test "derives logical_key from term when neither id nor logical_key is set" do
      changeset = GlossaryEntry.changeset(%GlossaryEntry{}, %{"term" => "commit"})
      assert Ecto.Changeset.get_field(changeset, :logical_key) == "commit"
    end

    test "promotes a binary `id` to logical_key" do
      changeset = GlossaryEntry.changeset(%GlossaryEntry{}, %{"term" => "commit", "id" => "vcs-commit"})
      assert Ecto.Changeset.get_field(changeset, :logical_key) == "vcs-commit"
    end

    test "drops a null logical_key so `id` or the term-derived default wins" do
      changeset =
        GlossaryEntry.changeset(%GlossaryEntry{}, %{
          "term" => "commit",
          "id" => "vcs-commit",
          "logical_key" => nil
        })

      assert Ecto.Changeset.get_field(changeset, :logical_key) == "vcs-commit"
    end

    test "drops a non-string logical_key so `id` or the term-derived default wins" do
      changeset =
        GlossaryEntry.changeset(%GlossaryEntry{}, %{
          "term" => "commit",
          "logical_key" => 42
        })

      assert Ecto.Changeset.get_field(changeset, :logical_key) == "commit"
    end

    test "ignores a non-string `id` and falls back to the term-derived default" do
      changeset = GlossaryEntry.changeset(%GlossaryEntry{}, %{"term" => "commit", "id" => 42})
      assert Ecto.Changeset.get_field(changeset, :logical_key) == "commit"
    end
  end
end
