defmodule Glossia.Translations.Agent do
  @moduledoc """
  A minimal Condukt agent used for one-shot streamed translations.

  It carries no tools and no static prompt of its own: the model, API key, and
  system prompt are supplied per session via `start_link/1` options (which
  override the `use Condukt` defaults), so a single agent module serves every
  account/model. Callers start a transient session, stream one user message, and
  stop it — see `Glossia.Translations.translate_stream/3`.
  """

  use Condukt
end
