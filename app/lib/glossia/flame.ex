defmodule Glossia.Flame do
  @moduledoc false

  @pool_name Glossia.RunnerPool
  @runner_managed_env_names ~w(
    FLAME_PARENT
    GLOSSIA_PHX_SERVER
    PHX_SERVER
    POD_IP
    POD_NAME
    POD_NAMESPACE
    RELEASE_COOKIE
    RELEASE_DISTRIBUTION
    RELEASE_NODE
  )
  @runner_allowed_env_names ~w(GLOSSIA_SANDBOX_ADAPTER)

  def pool_name, do: @pool_name

  def child? do
    not is_nil(parent()) or System.get_env("GLOSSIA_ISOLATED_CHILD") in ["true", "1"]
  end

  def parent do
    FLAME.Parent.get()
  end

  def pool_child_spec do
    config = Application.get_env(:glossia, :flame, [])

    [
      name: @pool_name,
      min: Keyword.get(config, :min, 0),
      max: Keyword.get(config, :max, 10),
      max_concurrency: Keyword.get(config, :max_concurrency, 1),
      idle_shutdown_after: Keyword.get(config, :idle_shutdown_after, 30_000),
      timeout: Keyword.get(config, :timeout, 300_000),
      boot_timeout: Keyword.get(config, :boot_timeout, 120_000),
      log: Keyword.get(config, :log, false)
    ]
    |> maybe_put_backend(config)
    |> then(&{FLAME.Pool, &1})
  end

  defp maybe_put_backend(opts, config) do
    case Keyword.get(config, :backend, :local) do
      :k8s ->
        Keyword.put(opts, :backend, {FLAMEK8sBackend, k8s_backend_opts(config)})

      _ ->
        opts
    end
  end

  defp k8s_backend_opts(config) do
    k8s_config = Keyword.get(config, :k8s, [])

    [
      app_container_name: Keyword.get(k8s_config, :app_container_name, "web"),
      manifest: &runner_manifest/2,
      env: Keyword.get(k8s_config, :env, %{}),
      log: Keyword.get(k8s_config, :log, false)
    ]
  end

  def runner_manifest(parent_pod_manifest, app_container) do
    k8s_config =
      Application.get_env(:glossia, :flame, [])
      |> Keyword.get(:k8s, [])

    runner_manifest(parent_pod_manifest, app_container, k8s_config)
  end

  def runner_manifest(parent_pod_manifest, app_container, k8s_config) do
    parent_spec = parent_pod_manifest["spec"] || %{}

    spec =
      %{
        "containers" => [
          %{
            "env" => runner_env(app_container)
          }
          |> maybe_put_map("resources", Keyword.get(k8s_config, :resources, %{}))
        ]
      }
      |> Map.put("automountServiceAccountToken", false)
      |> maybe_put_string("serviceAccountName", parent_spec["serviceAccountName"])
      |> maybe_put_list("imagePullSecrets", parent_spec["imagePullSecrets"] || [])
      |> maybe_put_string("runtimeClassName", Keyword.get(k8s_config, :runtime_class_name))
      |> maybe_put_map("nodeSelector", Keyword.get(k8s_config, :node_selector, %{}))
      |> maybe_put_list("tolerations", Keyword.get(k8s_config, :tolerations, []))
      |> maybe_put_map("affinity", Keyword.get(k8s_config, :affinity, %{}))

    %{
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "runner"
        }
      },
      "spec" => spec
    }
  end

  defp runner_env(app_container) do
    app_container
    |> Map.get("env", [])
    |> Enum.filter(&runner_allowed_env?/1)
  end

  defp runner_allowed_env?(%{"name" => name, "value" => _value}) do
    name in @runner_allowed_env_names and name not in @runner_managed_env_names
  end

  defp runner_allowed_env?(_env), do: false

  defp maybe_put_string(map, _key, nil), do: map
  defp maybe_put_string(map, _key, ""), do: map
  defp maybe_put_string(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_map(map, _key, nil), do: map
  defp maybe_put_map(map, _key, value) when value == %{}, do: map
  defp maybe_put_map(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_list(map, _key, nil), do: map
  defp maybe_put_list(map, _key, []), do: map
  defp maybe_put_list(map, key, value), do: Map.put(map, key, value)
end
