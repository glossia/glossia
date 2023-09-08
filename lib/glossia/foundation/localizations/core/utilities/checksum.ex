defmodule Glossia.Foundation.Localizations.Core.Utilities.Checksum do
  alias Glossia.Foundation.Localizations.Core.Utilities.Hasher
  alias Glossia.Foundation.Localizations.Core.Utilities.Prompts

  def get_source_content_checksum(source_content, algorithm) do
    Hasher.new(algorithm: algorithm) |> Hasher.combine(source_content) |> Hasher.finalize()
  end

  def get_localized_content_checksum(
        source_content,
        source,
        format,
        target,
        :new_target_localizable = type,
        algorithm
      ) do
    prompt =
      Prompts.get_localize_prompt(
        source_content,
        source,
        format,
        target,
        type,
        :content,
        :summary
      )

    Hasher.new(algorithm: algorithm) |> Hasher.combine(prompt) |> Hasher.finalize()
  end
end
