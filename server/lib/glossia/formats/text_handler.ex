defmodule Glossia.Formats.TextHandler do
  @moduledoc """
  Handles plain text translation.
  """

  @behaviour Glossia.Formats.Handler

  @impl true
  def translate(content, source_locale, target_locale) do
    Glossia.AI.Translator.translate(content, source_locale, target_locale)
  end

  @impl true
  def validate(_content) do
    # Plain text is always valid
    :ok
  end
end
