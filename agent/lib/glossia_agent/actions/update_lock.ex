defmodule GlossiaAgent.Actions.UpdateLock do
  @moduledoc """
  Jido Action: Update the lock file after a successful translation.

  Records source hash, context hash, output hash, and timestamp
  in the lock file so subsequent runs can skip unchanged files.
  """

  use Jido.Action,
    name: "update_lock",
    description: "Update lock file after successful translation",
    schema: [
      directory: [type: :string, required: true, doc: "Path to the localizable directory"],
      source_path: [type: :string, required: true, doc: "Relative source file path"],
      lang_key: [type: :string, required: true, doc: "Language key for the output"],
      output_path: [type: :string, required: true, doc: "Relative output file path"],
      source_hash: [type: :string, required: true, doc: "SHA-256 hash of source content"],
      context_hash: [type: :string, required: true, doc: "SHA-256 hash of context"],
      output_hash: [type: :string, required: true, doc: "SHA-256 hash of translated output"]
    ]

  alias GlossiaAgent.Locks

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    # Input shape (params):
    # %{
    #   directory: "/content",
    #   source_path: "docs/intro.md",
    #   lang_key: "es",
    #   output_path: "docs/i18n/es/intro.md",
    #   source_hash: "abc...",
    #   context_hash: "def...",
    #   output_hash: "ghi..."
    # }
    lock =
      Locks.read_lock(params.directory, params.source_path) ||
        Locks.create_lock(params.source_path)

    updated_lock = %{lock | source_hash: params.source_hash, context_hash: params.context_hash}

    updated_lock =
      put_in(updated_lock.outputs[params.lang_key], %Locks.OutputLock{
        path: params.output_path,
        hash: params.output_hash,
        context_hash: params.context_hash,
        checked_at: DateTime.to_iso8601(DateTime.utc_now())
      })

    Locks.write_lock(params.directory, params.source_path, updated_lock)

    # Output shape merged into agent state:
    # %{lock_updated: true, source_path: "docs/intro.md", lang_key: "es"}
    {:ok, %{lock_updated: true, source_path: params.source_path, lang_key: params.lang_key}}
  end
end
