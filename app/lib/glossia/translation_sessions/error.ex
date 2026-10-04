defmodule Glossia.TranslationSessions.Error do
  @moduledoc """
  Safe, actionable messages for session failures before file translation starts.

  Unknown reasons stay in server logs, not in member-facing activity. Legacy
  inspected errors are normalized without evaluating the stored Elixir text.
  """

  @sources_mapping_error "sources must be a mapping of source patterns to target path templates"

  def describe({:planning_failed, @sources_mapping_error}) do
    "The translation configuration is invalid. In L10N.md, define sources as a mapping from source patterns to target path templates, then retry."
  end

  def describe({:planning_failed, _reason}) do
    "The translation plan could not be created. Check the configuration in L10N.md and any locale overlays, then retry."
  end

  def describe(_reason) do
    "The translation could not be completed. Please retry. If the problem persists, contact support with the session ID."
  end

  @doc "Normalizes stored activity errors, including legacy inspected terms."
  def display("Translation failed: {:planning_failed, \"" <> rest) do
    if rest == @sources_mapping_error <> "\"}" do
      describe({:planning_failed, @sources_mapping_error})
    else
      describe({:planning_failed, nil})
    end
  end

  def display("Translation failed: " <> _reason), do: describe(nil)
  def display(message), do: message
end
