defmodule Glossia.TranslationSessions.CompletionHandler.Default do
  @behaviour Glossia.TranslationSessions.CompletionHandler

  @impl true
  def on_completed(_session), do: :ok
end
