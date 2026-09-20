defmodule Glossia.Flame do
  @moduledoc """
  Enterprise-side FLAME wrapper.

  Ports the FLAME pool + Kubernetes runner-manifest builder that used to live
  in `Glossia.Flame` on the earlier tree. The repository no longer knows
  what FLAME is; enterprise carries every reference here, and
  `Glossia.Runners` reaches these functions rather than
  calling `FLAME.*` inline. `runner_manifest/3` is what shapes the runner
  pod (image inheritance, kata runtime class, node selectors, resources).
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
