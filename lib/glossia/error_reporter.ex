defmodule Glossia.ErrorReporter do
  def handle_event([:oban, :job, :exception], _measure, meta, _) do
    Appsignal.set_error(meta.error, meta.stacktrace)
  end
end
