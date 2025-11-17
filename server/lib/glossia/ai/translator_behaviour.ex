defmodule Glossia.AI.TranslatorBehaviour do
  @moduledoc """
  Behaviour for AI translation services.
  """

  @doc """
  Translates text from source locale to target locale.
  """
  @callback translate(text :: String.t(), source_locale :: String.t(), target_locale :: String.t()) ::
              {:ok, String.t()} | {:error, term()}
end
