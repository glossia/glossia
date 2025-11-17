defmodule Glossia.FormatCase do
  @moduledoc """
  This module defines the test case to be used by
  tests for format handlers.

  It provides utilities for mocking the AI translator.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Mimic
      import Glossia.FormatCase
    end
  end

  @doc """
  Expects a successful translation and returns the expected result.
  """
  def expect_translate(text, source, target, result) do
    Mimic.expect(Glossia.AI.Translator, :translate, fn ^text, ^source, ^target ->
      {:ok, result}
    end)
  end

  @doc """
  Expects a translation error.
  """
  def expect_translate_error(text, source, target, error) do
    Mimic.expect(Glossia.AI.Translator, :translate, fn ^text, ^source, ^target ->
      {:error, error}
    end)
  end
end
