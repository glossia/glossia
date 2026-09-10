defmodule Glossia.TranslationSessions.Launcher.Default do
  @moduledoc """
  Default `Glossia.TranslationSessions.Launcher` — runs the translation
  synchronously in the calling process. See the moduledoc on
  `Glossia.TranslationSessions.Launcher` for the seam a scale-out build plugs
  into.
  """

  @behaviour Glossia.TranslationSessions.Launcher

  alias Glossia.TranslationSessions

  @impl true
  def launch(session_id) do
    TranslationSessions.Translate.run(session_id)
    :ok
  end

  @impl true
  def cancel(_session_id), do: :ok
end
