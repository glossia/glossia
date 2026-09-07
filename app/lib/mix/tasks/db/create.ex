defmodule Mix.Tasks.Db.Create do
  @moduledoc ~S"""
  Creates the storage for every configured repo and checks each one connects.

  `mix ecto.create` reports success as soon as the database exists, so a repo
  that is created but unreachable — wrong port, ClickHouse not running yet —
  only fails later, halfway through a migration or a seed script, with an error
  that points at the wrong step. Connecting to each repo here turns that into a
  failure at creation time.

  The repos are started on their own rather than through `app.start`: Glossia's
  supervision tree reads from the database as it boots, which a database that
  has just been created and not yet migrated cannot answer.

  This task backs the `ecto.create` alias, so plain `mix ecto.create` runs it.
  """

  use Mix.Task

  import Mix.Ecto

  @shortdoc "Creates the repos' storage and verifies each one connects"

  def run(args) do
    Mix.Tasks.Ecto.Create.run(args)

    for repo <- parse_repo(args) do
      ensure_repo(repo, args)
      {:ok, _result, _apps} = Ecto.Migrator.with_repo(repo, fn _repo -> :ok end)
    end
  end
end
