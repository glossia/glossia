defmodule Glossia.Translations.Fingerprint do
  @moduledoc """
  Stable JSON fingerprints, independent of VM-local atom ordering.

  Legacy aliases cover the historical four-atom-key validation, decision, and
  glossary records. They are computed from current values only, so accepting an
  old serialization never hides an actual settings or terminology change.
  """

  def hash(value), do: value |> encode() |> IO.iodata_to_binary() |> digest()

  # Human-review identities use the original v1 protocol. Keep it separate from
  # canonical lock fingerprints so deployment does not discard existing answers.
  def legacy_hash(value), do: value |> JSON.encode!() |> digest()

  def legacy_hashes(value, keys) when length(keys) <= 4 do
    keys
    |> permutations()
    |> MapSet.new(fn order ->
      value |> legacy_encode(order) |> IO.iodata_to_binary() |> digest()
    end)
  end

  defp encode(value) when is_map(value) do
    entries =
      value
      |> Enum.sort_by(fn {key, _} -> to_string(key) end)
      |> Enum.map(fn {key, nested} -> [JSON.encode!(to_string(key)), ":", encode(nested)] end)

    ["{", Enum.intersperse(entries, ","), "}"]
  end

  defp encode(value) when is_list(value),
    do: ["[", Enum.intersperse(Enum.map(value, &encode/1), ","), "]"]

  defp encode(value), do: JSON.encode_to_iodata!(value)

  # Only these small atom-key records varied with atom creation order. Values
  # were scalar/argv or binary-key maps, whose old encoding is kept verbatim.
  # Glossary entries share the same key order throughout a VM, not an
  # independent permutation per entry (which would be exponential).
  defp legacy_encode(value, order) when is_map(value) do
    entries =
      for key <- order,
          Map.has_key?(value, key),
          do: [JSON.encode!(to_string(key)), ":", JSON.encode_to_iodata!(Map.fetch!(value, key))]

    ["{", Enum.intersperse(entries, ","), "}"]
  end

  defp legacy_encode(value, order) when is_list(value),
    do: ["[", Enum.intersperse(Enum.map(value, &legacy_encode(&1, order)), ","), "]"]

  defp permutations([]), do: [[]]

  defp permutations(keys) do
    for key <- keys, rest <- permutations(List.delete(keys, key)), do: [key | rest]
  end

  defp digest(json), do: :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
end
