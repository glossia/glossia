defmodule GlossiaEnterprise.Runners do
  @moduledoc """
  Managed runner pool with operator-controlled scaling.

  Uses FLAME's Kubernetes backend to provide:

  1. Pre-warmed capacity — `min` defaults above zero so calls to the pool
     can use a worker without waiting for pod boot. Detached translation
     Jobs are scheduled separately and do not use this pool.
  2. Dedicated placement — a nodeSelector pins runners to nodes the operator
     provisions and scales for translation load.
  3. A named pool for runner inspection and metrics. Community does not
     start a remote runner pool.

  Configuration reads from `:glossia, :managed_runner`, populated
  by `config/runtime.exs` from `GLOSSIA_MANAGED_*` env vars.
  """

  alias GlossiaEnterprise.Flame
  alias GlossiaEnterprise.Kubernetes

  @pool_name Glossia.RunnerPool

  def pool_name, do: @pool_name

  def child?, do: Flame.child?()

  def call(fun, opts), do: FLAME.call(@pool_name, fun, opts)

  def place_child(child_spec, opts), do: FLAME.place_child(@pool_name, child_spec, opts)

  def pool_child_spec do
    config = Application.get_env(:glossia, :managed_runner, [])
    k8s_config = Keyword.get(config, :k8s, [])

    backend = Keyword.get(config, :backend, default_backend())

    opts =
      [
        name: @pool_name,
        min: Keyword.get(config, :min, 2),
        max: Keyword.get(config, :max, 20),
        max_concurrency: Keyword.get(config, :max_concurrency, 2),
        idle_shutdown_after: Keyword.get(config, :idle_shutdown_after, 300_000),
        timeout: Keyword.get(config, :timeout, 3_600_000),
        boot_timeout: Keyword.get(config, :boot_timeout, 180_000),
        log: Keyword.get(config, :log, false)
      ]
      |> maybe_put_backend(backend, k8s_config)

    {FLAME.Pool, opts}
  end

  # A non-cluster environment (dev, CI, mix tasks) does not have a service
  # account token, so booting the pool with the k8s backend would fail. Fall
  # back to the local FLAME backend when the pod isn't in-cluster.
  defp default_backend do
    if Kubernetes.in_cluster?(), do: :k8s, else: :local
  end

  defp maybe_put_backend(opts, :k8s, k8s_config) do
    Keyword.put(opts, :backend, {FLAMEK8sBackend, k8s_backend_opts(k8s_config)})
  end

  defp maybe_put_backend(opts, _other, _k8s_config), do: opts

  # Reuses `GlossiaEnterprise.Flame.runner_manifest/3` so the manifest shape
  # stays canonical, with the managed pool supplying its own k8s config
  # (dedicated node selector, larger resources, tolerations for the pool).
  defp k8s_backend_opts(k8s_config) do
    [
      app_container_name: Keyword.get(k8s_config, :app_container_name, "web"),
      manifest: fn parent_pod_manifest, app_container ->
        Flame.runner_manifest(parent_pod_manifest, app_container, k8s_config)
      end,
      env: Keyword.get(k8s_config, :env, %{}),
      log: Keyword.get(k8s_config, :log, false)
    ]
  end
end
