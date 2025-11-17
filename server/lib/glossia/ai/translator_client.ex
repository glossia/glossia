defmodule Glossia.AI.TranslatorClient do
  @moduledoc """
  Client module for accessing the translator implementation.
  Uses the real translator in production and allows mocking in tests.
  """

  @doc """
  Returns the configured translator module.
  """
  def impl do
    Application.get_env(:glossia, :translator_impl, Glossia.AI.Translator)
  end

  @doc """
  Translates text using the configured translator implementation.
  """
  def translate(text, source_locale, target_locale) do
    impl().translate(text, source_locale, target_locale)
  end
end
