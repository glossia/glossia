defmodule Glossia.Foundation.Analytics.Core.Posthog do
  use Application.Module

  defbehaviour do
    @callback capture(event :: String.t(), metadata :: map()) :: any()
  end

  defimplementation do
    def capture(event, metadata) do
      {:ok, _ } = Posthog.capture(event, metadata)
    end
  end
end
