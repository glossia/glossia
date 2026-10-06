defmodule Glossia.TranslationStubs do
  @moduledoc """
  Answers stubbed translation requests the way a model would.

  Markdown is sent as a JSON array of units and answered with a JSON object
  keyed by unit id; every other request carries its text directly. `respond/2`
  applies `fun` to each piece of text, so a test can describe a translation
  once regardless of how the engine packaged the request.
  """

  def respond(%{"segment_kind" => "markdown_units", "source_content" => content}, fun) do
    content
    |> JSON.decode!()
    |> Map.new(fn %{"id" => id, "text" => text} -> {id, fun.(text)} end)
    |> JSON.encode!()
  end

  def respond(%{"source_content" => content}, fun), do: fun.(content)

  @doc "The unit texts of a Markdown units request."
  def unit_texts(%{"segment_kind" => "markdown_units", "source_content" => content}),
    do: content |> JSON.decode!() |> Enum.map(& &1["text"])
end
