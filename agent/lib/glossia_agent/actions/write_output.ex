defmodule GlossiaAgent.Actions.WriteOutput do
  @moduledoc """
  Jido Action: Write translated content to an output file.

  Ensures the parent directory exists and writes the translated
  content to the specified path.
  """

  use Jido.Action,
    name: "write_output",
    description: "Write translated content to an output file on disk",
    schema: [
      output_path: [type: :string, required: true, doc: "Absolute path to the output file"],
      content: [type: :string, required: true, doc: "Translated content to write"]
    ]

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    # Input shape (params):
    # %{output_path: "/repo/docs/i18n/es/intro.md", content: "# Hola"}
    output_dir = Path.dirname(params.output_path)
    File.mkdir_p!(output_dir)
    File.write!(params.output_path, params.content)

    # Output shape merged into agent state:
    # %{output_path: "/repo/docs/i18n/es/intro.md", bytes_written: 6}
    {:ok, %{output_path: params.output_path, bytes_written: byte_size(params.content)}}
  end
end
