defmodule Glossia.TranslationSessions.PublicationPacing do
  @moduledoc """
  Spaces translation branch updates across all sessions of a project.

  Admission runs under the project's database publication lock. Reserving a
  slot before calling GitHub also counts ambiguous failures: an HTTP timeout
  may mean GitHub advanced the branch even though we did not get its response.
  Source merges and final flushes use the same budget as intermediate batches.
  Waiters release the database lock before sleeping and recheck admission when
  they wake. A new session or application restart does not reset the budget.
  """

  alias Glossia.Accounts.Project
  alias Glossia.Repo

  # Fixed product default. The compile-time test override avoids production-
  # sized sleeps without exposing an operator-facing runtime setting.
  @max_pushes_per_hour Application.compile_env(:glossia, __MODULE__, [])
                       |> Keyword.get(:max_pushes_per_hour, 4)

  def run(project_id, callback) when is_function(callback, 0) do
    with :ok <- admit(project_id) do
      try do
        callback.()
      after
        # Count from completion, not admission: building a large Git tree can
        # take minutes. Otherwise slow and fast batches could push back-to-back.
        Repo.get!(Project, project_id)
        |> Ecto.Changeset.change(translation_last_pushed_at: DateTime.utc_now())
        |> Repo.update!()
      end
    end
  end

  def admit(project_id, opts \\ []) do
    project = Repo.get!(Project, project_id)
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)

    max_pushes = Keyword.get(opts, :max_pushes_per_hour, @max_pushes_per_hour)

    unless is_integer(max_pushes) and max_pushes > 0 do
      raise ArgumentError, "translation max_pushes_per_hour must be a positive integer"
    end

    # Round up so non-divisors of an hour cannot exceed the configured cap.
    interval_ms = div(3_600_000 + max_pushes - 1, max_pushes)

    remaining_ms =
      if project.translation_last_pushed_at do
        interval_ms - DateTime.diff(now, project.translation_last_pushed_at, :millisecond)
      else
        0
      end

    if remaining_ms > 0 do
      {:wait, remaining_ms}
    else
      project
      |> Ecto.Changeset.change(translation_last_pushed_at: now)
      |> Repo.update!()

      :ok
    end
  end
end
