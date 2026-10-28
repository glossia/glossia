defmodule Glossia.TranslationSessions.Launcher do
  @moduledoc "Routes translation execution to the configured runtime."

  def launch(session_id), do: Glossia.Extensions.translation_runtime().launch(session_id)
  def cancel(session_id), do: Glossia.Extensions.translation_runtime().cancel(session_id)
end
