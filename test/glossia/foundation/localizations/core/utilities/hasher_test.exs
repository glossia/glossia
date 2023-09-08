defmodule Glossia.Foundation.Localizations.Core.Utilities.HasherTest do
  use Glossia.DataCase
  alias Glossia.Foundation.Localizations.Core.Utilities.Hasher

  test "hashes strings deterministically" do
    # Given
    first =
      Hasher.new() |> Hasher.combine("first") |> Hasher.combine("second") |> Hasher.finalize()

    second =
      Hasher.new() |> Hasher.combine("first") |> Hasher.combine("second") |> Hasher.finalize()

    # When/Then
    assert first == second
  end

  test "hashes booleans deterministically" do
    # Given
    first = Hasher.new() |> Hasher.combine(true) |> Hasher.combine(false) |> Hasher.finalize()
    second = Hasher.new() |> Hasher.combine(true) |> Hasher.combine(false) |> Hasher.finalize()

    # When/Then
    assert first == second
  end

  test "hashes numbers deterministically" do
    # Given
    first = Hasher.new() |> Hasher.combine(5) |> Hasher.combine(22) |> Hasher.finalize()
    second = Hasher.new() |> Hasher.combine(5) |> Hasher.combine(22) |> Hasher.finalize()

    # When/Then
    assert first == second
  end

  test "hashes lists deterministically" do
    # Given
    first =
      Hasher.new()
      |> Hasher.combine([5])
      |> Hasher.combine([true])
      |> Hasher.combine(["foo", "bar"])
      |> Hasher.finalize()

    second =
      Hasher.new()
      |> Hasher.combine([5])
      |> Hasher.combine([true])
      |> Hasher.combine(["foo", "bar"])
      |> Hasher.finalize()

    # When/Then
    assert first == second
  end

  test "hashes tuples deterministically" do
    # Given
    first =
      Hasher.new()
      |> Hasher.combine({5})
      |> Hasher.combine({true})
      |> Hasher.combine({"foo", "bar"})
      |> Hasher.finalize()

    second =
      Hasher.new()
      |> Hasher.combine({5})
      |> Hasher.combine({true})
      |> Hasher.combine({"foo", "bar"})
      |> Hasher.finalize()

    # When/Then
    assert first == second
  end

  test "hashes maps deterministically" do
    # Given
    first =
      Hasher.new()
      |> Hasher.combine(%{foo: "bar", bar: "foo"})
      |> Hasher.combine(%{test: "foo", test2: "bar"})
      |> Hasher.finalize()

    second =
      Hasher.new()
      |> Hasher.combine(%{foo: "bar", bar: "foo"})
      |> Hasher.combine(%{test: "foo", test2: "bar"})
      |> Hasher.finalize()

    # When/Then
    assert first == second
  end
end
