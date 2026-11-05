defmodule Glossia.Editor.SyncCache do
  @moduledoc """
  Collapses the repository refresh the editor starts whenever it opens.

  Concurrent opens of one project share a single checkout, a refresh that just
  finished is reused for a minute instead of cloning again, and the checkout
  runs in Cachex's courier rather than in the page's process, so leaving the
  page no longer aborts a refresh halfway and leaves the snapshot stale.
  Failures are not cached; the next open retries.
  """

  import Cachex.Spec

  alias Glossia.Editor

  @cache __MODULE__
  @ttl :timer.minutes(1)

  def child_spec(opts) do
    name = Keyword.get(opts, :name, @cache)

    Supervisor.child_spec({Cachex, name: name, expiration: expiration(default: @ttl)}, id: name)
  end

  def synchronize(user, project, cache \\ @cache) do
    with :ok <- Editor.authorize(user, project) do
      result =
        Cachex.fetch(cache, project.id, fn _project_id ->
          case Editor.synchronize(user, project) do
            {:ok, _files} -> {:commit, {:ok, :synchronized}}
            error -> {:ignore, error}
          end
        end)

      case result do
        {status, value} when status in [:ok, :commit, :ignore] -> value
        {:error, _reason} = error -> error
      end
    end
  end
end
