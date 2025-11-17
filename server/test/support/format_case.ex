defmodule Glossia.FormatCase do
  @moduledoc """
  This module defines the test case to be used by
  tests for format handlers.

  It provides utilities for mocking the AI translator.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      import Glossia.FormatCase

      # Make sure mocks are verified when the test exits
      setup :verify_on_exit!

      # Set the translator implementation to the mock
      setup do
        Application.put_env(:glossia, :translator_impl, Glossia.AI.TranslatorMock)
        on_exit(fn -> Application.delete_env(:glossia, :translator_impl) end)
        :ok
      end
    end
  end

  @doc """
  Expects a successful translation and returns the expected result.
  """
  def expect_translate(text, source, target, result) do
    Mox.expect(Glossia.AI.TranslatorMock, :translate, fn ^text, ^source, ^target ->
      {:ok, result}
    end)
  end

  @doc """
  Expects a translation error.
  """
  def expect_translate_error(text, source, target, error) do
    Mox.expect(Glossia.AI.TranslatorMock, :translate, fn ^text, ^source, ^target ->
      {:error, error}
    end)
  end
end
