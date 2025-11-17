defmodule Glossia.Formats.Handler do
  @moduledoc """
  Behaviour for format handlers that translate structured content
  while preserving formatting and minimizing diffs.
  """

  @doc """
  Translates content in a specific format.

  Returns the translated content in the same format with minimal changes.
  Must preserve formatting, whitespace, key order, and structure.
  """
  @callback translate(content :: String.t(), source_locale :: String.t(), target_locale :: String.t()) ::
              {:ok, String.t()} | {:error, term()}

  @doc """
  Validates that content is valid for the format.
  """
  @callback validate(content :: String.t()) :: :ok | {:error, term()}
end
