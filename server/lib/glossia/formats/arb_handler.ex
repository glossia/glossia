defmodule Glossia.Formats.ArbHandler do
  @moduledoc """
  Handles ARB (Application Resource Bundle) files.
  ARB is Flutter's localization format - essentially JSON with metadata.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.Formats.JsonHandler

  @impl true
  def translate(content, source_locale, target_locale) do
    # ARB is JSON-based, so we can delegate to JsonHandler
    JsonHandler.translate(content, source_locale, target_locale)
  end

  @impl true
  def validate(content) do
    # ARB is JSON, so validate as JSON
    JsonHandler.validate(content)
  end
end
