defmodule GlossiaAgent.Checks.Validator do
  @moduledoc """
  Top-level output validation for translated output.
  """

  alias GlossiaAgent.Checks.Syntax

  @doc """
  Validate translated output. Returns nil if valid, or an error string.
  """
  @spec validate(GlossiaAgent.Format.t(), String.t(), String.t(), keyword()) :: String.t() | nil
  def validate(format, output, source, _opts \\ []) do
    case Syntax.validate(format, output, source) do
      nil ->
        nil

      err ->
        "syntax-validator tool failed: #{err}"
    end
  end
end
