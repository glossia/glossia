defmodule Glossia.TranslationSessions.EngineRelease do
  @moduledoc "Translation engine identity and optional release-aware recovery."

  def image, do: Application.get_env(:glossia, :engine_image)

  def ready_release, do: Glossia.Extensions.translation_runtime().ready_release()

  def pinned?(image) when is_binary(image),
    do: Regex.match?(~r/@sha256:[a-f0-9]{64}\z/, image)

  def pinned?(_image), do: false
end
