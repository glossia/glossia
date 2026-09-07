defmodule Glossia.SentryOban do
  @moduledoc false

  def report_error?(_worker, %{attempt: attempt, max_attempts: max_attempts})
      when is_integer(attempt) and is_integer(max_attempts) do
    attempt >= max_attempts
  end

  def report_error?(_worker, _job), do: true
end
