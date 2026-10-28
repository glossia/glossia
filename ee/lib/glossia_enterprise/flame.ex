defmodule GlossiaEnterprise.Flame do
  @moduledoc """
  FLAME runner roles and Kubernetes manifest construction.

  `runner_manifest/3` configures the runner pod's runtime class, node
  selectors, resources, and inherited pull secrets.
  """

  @pool_name Glossia.RunnerPool

  def pool_name, do: @pool_name

  def child? do
    not is_nil(parent()) or System.get_env("GLOSSIA_ISOLATED_CHILD") in ["true", "1"]
  end

  def parent, do: FLAME.Parent.get()

  def runner_manifest(parent_pod_manifest, _app_container, k8s_config) do
    parent_spec = parent_pod_manifest["spec"] || %{}

    spec =
      %{
        "containers" => [
          %{"env" => []}
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
      "metadata" => %{"labels" => %{"app.kubernetes.io/component" => "runner"}},
      "spec" => spec
    }
  end

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
