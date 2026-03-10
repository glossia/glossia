defmodule GlossiaAgent.Checks.Validator do
  @moduledoc """
  Top-level output validation combining syntax and preserve checks.
  """

  alias GlossiaAgent.Checks.{Syntax, Preserve}

  @doc """
  Validate translated output. Returns nil if valid, or an error string.
  """
  @spec validate(GlossiaAgent.Format.t(), String.t(), String.t(), keyword()) :: String.t() | nil
  def validate(format, output, source, opts \\ []) do
    preserve_kinds = Keyword.get(opts, :preserve, [])

    case Syntax.validate(format, output, source) do
      nil ->
        kinds = Preserve.resolve_kinds(preserve_kinds)

        if kinds != [] do
          case Preserve.validate(output, source, kinds) do
            nil -> nil
            err -> "preserve-check tool failed: #{err}"
          end
        end

      err ->
        "syntax-validator tool failed: #{err}"
    end
  end
end
