defmodule GlossiaAgent.Hash do
  @moduledoc """
  SHA-256 hashing for lock freshness checks.
  Ported from agent/hash.ts / cli/internal/glossia/hash.go
  """

  @doc "Compute the SHA-256 hex digest of a string."
  @spec hash_string(String.t()) :: String.t()
  def hash_string(input) do
    :crypto.hash(:sha256, input)
    |> Base.encode16(case: :lower)
  end

  @doc "Compute the SHA-256 hex digest of multiple strings joined by double newlines."
  @spec hash_strings([String.t()]) :: String.t()
  def hash_strings([]), do: hash_string("")
  def hash_strings(parts), do: hash_string(Enum.join(parts, "\n\n"))
end
