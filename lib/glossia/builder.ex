defmodule Glossia.Builder do
  use Boundary, deps: [], exports: []

  require Logger

  @moduledoc """
  It provides utilities to interact with virtualized environments where builds run.
  """
  @spec translate(
          attrs :: [translation_id: integer(), status_update_cb: (String.t(), atom() -> nil)]
        ) :: :ok
  def translate(translation_id: translation_id, status_update_cb: status_update_cb) do
    Logger.info("Translating #{translation_id}...")

    Glossia.Builder.VM.run(
      command: "translate",
      env: %{GLOSSIA_TRANSLATION_ID: translation_id},
      status_update_cb: status_update_cb
    )
  end
end
