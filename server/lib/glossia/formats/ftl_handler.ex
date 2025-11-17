defmodule Glossia.Formats.FtlHandler do
  @moduledoc """
  Handles Mozilla Fluent (.ftl) files while preserving formatting.

  Fluent is Mozilla's modern localization format used in Pontoon.
  Format: key = value (with support for attributes, variants, etc.)

  This handler uses a Wasm module (written in Zig) for parsing and formatting,
  while translation happens in Elixir via AI.Translator.

  Example:
    hello = Hello, World!
    welcome-message = Welcome, {$name}!

  See: https://projectfluent.org/
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.Formats.WasmHandler

  @handler_name "ftl"

  @impl true
  def translate(content, source_locale, target_locale) do
    with {:ok, strings} <- WasmHandler.extract_strings(@handler_name, content) do
      # Translate each string
      translations =
        Enum.reduce_while(strings, {:ok, []}, fn string, {:ok, acc} ->
          value = string["value"]

          case Glossia.AI.Translator.translate(value, source_locale, target_locale) do
            {:ok, translated} ->
              translation = %{
                "index" => string["index"],
                "translation" => translated
              }
              {:cont, {:ok, [translation | acc]}}

            {:error, _} = error ->
              {:halt, error}
          end
        end)

      case translations do
        {:ok, trans_list} ->
          # Reverse to maintain order
          trans_list_ordered = Enum.reverse(trans_list)
          WasmHandler.apply_translations(@handler_name, content, trans_list_ordered)

        error ->
          error
      end
    end
  end

  @impl true
  def validate(content) do
    WasmHandler.validate(@handler_name, content)
  end
end
