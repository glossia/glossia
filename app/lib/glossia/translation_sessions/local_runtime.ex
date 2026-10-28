defmodule Glossia.TranslationSessions.LocalRuntime do
  @moduledoc """
  Community execution: translations run in the calling Oban worker on this host.

  Repository validation commands share the application's operating-system user
  and environment. This runtime does not provide a security isolation boundary.
  """

  def launch(session_id) do
    Glossia.TranslationSessions.Translate.run(session_id)
    :ok
  end

  def cancel(_session_id), do: :ok
  def children, do: nil
  def parent_children, do: []
  def runner_child?, do: false
  def translation_job?, do: false
  def ready_release, do: :not_ready
end
