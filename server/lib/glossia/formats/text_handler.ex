defmodule Glossia.Formats.TextHandler do
  @moduledoc """
  Handles plain text translation.
  """

  @behaviour Glossia.Formats.Handler

  @impl true
  def translate(content, source_locale, target_locale) do
    with :ok <- validate(content),
         {:ok, translated_content} <-
           Glossia.AI.Translator.translate(content, source_locale, target_locale),
         :ok <- validate(translated_content) do
      {:ok, translated_content}
    end
  end

  @impl true
  def validate(content) do
    # Basic validation: ensure content is not nil and is a binary (string)
    cond do
      is_nil(content) ->
        {:error, "Content cannot be nil"}

      not is_binary(content) ->
        {:error, "Content must be a string"}

      true ->
        :ok
    end
  end
end
