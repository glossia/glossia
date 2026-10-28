defmodule Glossia.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :glossia

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          &run_migrations(&1, [Ecto.Migrator.migrations_path(&1)], :up, all: true)
        )
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(
        repo,
        &run_migrations(&1, [Ecto.Migrator.migrations_path(&1)], :down, to: version)
      )
  end

  def run_migrations(repo, sources, direction, opts) do
    sources =
      sources ++
        Glossia.Extensions.audit_migrations(repo) ++
        Glossia.Extensions.organization_authentication_migrations(repo)

    Ecto.Migrator.run(repo, sources, direction, opts)
  end

  @doc """
  Points UAInspector at the release's writable priv dir at boot. Referenced as
  the `:init` MFA in `runtime.exs` (mirrors Plausible's setup).
  """
  def configure_ua_inspector do
    priv_dir = Application.app_dir(@app, "priv/ua_inspector")
    Application.put_env(:ua_inspector, :database_path, priv_dir)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
