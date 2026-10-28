defmodule GlossiaEnterprise.TranslationSessions.Runtime do
  @moduledoc "Isolated translation runners, their boot roles, and supervision."

  alias Glossia.Ingestion
  alias GlossiaEnterprise.{Flame, Runners}
  alias GlossiaEnterprise.TranslationSessions.{EngineRelease, Job, Launcher}

  defdelegate launch(session_id), to: Launcher
  defdelegate cancel(session_id), to: Launcher
  defdelegate ready_release(), to: EngineRelease
  defdelegate runner_child?(), to: Flame, as: :child?
  defdelegate translation_job?(), to: Job, as: :current?

  def parent_children, do: [Runners.pool_child_spec()]

  # nil selects the ordinary web supervision tree; [] is a FLAME-owned child.
  def children do
    cond do
      runner_child?() -> []
      translation_job?() -> translation_job_children()
      true -> nil
    end
  end

  defp translation_job_children do
    oban_config =
      :glossia
      |> Application.fetch_env!(Oban)
      |> Keyword.merge(queues: false, plugins: false)

    [
      Glossia.Vault,
      {Finch,
       name: Glossia.Finch,
       pools: %{default: [size: Application.get_env(:glossia, :http_pool_size, 50)]}},
      Glossia.Repo,
      Glossia.ClickHouseRepo,
      Glossia.IngestRepo,
      {Oban, oban_config},
      {DNSCluster, query: Application.get_env(:glossia, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Glossia.PubSub},
      FunWithFlags.Supervisor,
      Glossia.RateLimiter,
      Supervisor.child_spec(
        {Ingestion.Buffer,
         [name: Ingestion.TranslationSessionEventBuffer, flush_interval_ms: 1_000] ++
           (Ingestion.TranslationSessionEvent.buffer_opts()
            |> Map.take([:insert_sql, :insert_opts, :header])
            |> Map.to_list())},
        id: Ingestion.TranslationSessionEventBuffer
      ),
      Glossia.Github.InstallationTokens
    ] ++ Glossia.Extensions.audit_children() ++ [Job]
  end
end
