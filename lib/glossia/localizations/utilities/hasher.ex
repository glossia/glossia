defmodule Glossia.Localizations.Utilities.Hasher do
  @moduledoc ~S"""
  This module represents a utility to calculate a hash deterministically from a set of values.
  If the order of the elements or their values change, the hash will change.

  This module is useful to support incremental localization based on the hash of the content and
  the context it depends on.
  """
  defstruct [:hashables, :algorithm]

  def new(opts \\ []) do
    algorithm = Keyword.get(opts, :algorithm, :sha256)
    %__MODULE__{hashables: [], algorithm: algorithm}
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_binary(hashable) do
    %{hasher | hashables: [hash(hashable, hasher.algorithm) | hasher.hashables]}
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_boolean(hashable) do
    boolean_string = if hashable, do: "1", else: "0"
    %{hasher | hashables: [hash(boolean_string, hasher.algorithm) | hasher.hashables]}
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_number(hashable) do
    %{hasher | hashables: [hash("#{hashable}", hasher.algorithm) | hasher.hashables]}
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_list(hashable) do
    hashable |> Enum.reduce(hasher, fn hashable, hasher -> combine(hasher, hashable) end)
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_tuple(hashable) do
    combine(hasher, hashable |> Tuple.to_list())
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_atom(hashable) do
    combine(hasher, hashable |> Atom.to_string())
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_map(hashable) do
    combine(hasher, hashable |> Map.to_list() |> Enum.sort())
  end

  def combine(%__MODULE__{} = hasher, hashable) when is_struct(hashable) do
    combine(hasher, hashable |> Map.to_list() |> Enum.sort())
  end

  def finalize(%__MODULE__{} = hasher) do
    hasher.hashables |> Enum.join("|") |> hash(hasher.algorithm)
  end

  defp hash(value, algorithm) when is_binary(value) do
    :crypto.hash(algorithm, value) |> Base.encode16() |> String.downcase()
  end
end
