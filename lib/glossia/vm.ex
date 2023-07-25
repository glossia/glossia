defmodule Glossia.VM do
  use Boundary, deps: [], exports: []

  require Logger

  @moduledoc """
  It provides utilities to interact with virtualized environments where builds run.
  """
  def translate(translation_id: translation_id) do
    Logger.info("Translating #{translation_id}...")
    logs_path = "/translations/#{translation_id}.log"

    Glossia.VM.Builder.run(
      command: "translate",
      logs_path: logs_path,
      env: %{GLOSSIA_TRANSLATION_ID: translation_id}
    )
  end
end
