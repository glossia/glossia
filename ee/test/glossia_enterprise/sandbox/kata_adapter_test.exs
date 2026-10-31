defmodule GlossiaEnterprise.Sandbox.KataAdapterTest do
  # Rewrites the application-wide managed runner settings.
  use ExUnit.Case, async: false

  alias GlossiaEnterprise.Sandbox.KataAdapter

  setup do
    previous = Application.get_env(:glossia, :managed_runner)
    on_exit(fn -> Application.put_env(:glossia, :managed_runner, previous) end)
    :ok
  end

  defp put_placement(k8s) do
    Application.put_env(:glossia, :managed_runner, k8s: k8s)
  end

  test "editor previews fail closed without an explicitly configured Kata runtime" do
    for runtime <- [nil, "", "runc", "gvisor"] do
      put_placement(runtime_class_name: runtime)
      refute KataAdapter.preview_isolated?()

      assert {:error, :preview_requires_isolation} =
               KataAdapter.build_manifest("preview", %{purpose: "editor_preview"})

      assert {:error, :preview_requires_isolation} =
               KataAdapter.execute_preview("unused", "true", [])
    end

    put_placement(runtime_class_name: "kata-qemu")
    assert KataAdapter.preview_isolated?()

    assert {:ok, %{"spec" => spec, "metadata" => metadata}} =
             KataAdapter.build_manifest("preview", %{purpose: "editor_preview"})

    assert spec["runtimeClassName"] == "kata-qemu"
    assert metadata["labels"]["glossia.ai/purpose"] == "editor_preview"
  end

  test "preview admission requires the chart's complete network restrictions" do
    # Validate the shipped chart body, not an independently maintained fixture.
    spec =
      Path.expand(
        "../../../../deploy/helm/glossia/templates/editor-preview-network-policy.yaml",
        __DIR__
      )
      |> File.read!()
      |> String.split("\nspec:\n", parts: 2)
      |> List.last()
      |> String.split("\n{{-", parts: 2)
      |> hd()
      |> YamlElixir.read_from_string!()

    policy = %{
      "apiVersion" => "cilium.io/v2",
      "kind" => "CiliumNetworkPolicy",
      "metadata" => %{},
      "spec" => spec
    }

    assert KataAdapter.preview_network_policy_valid?(policy)

    for unsafe <- [
          nil,
          %{},
          put_in(policy, ["metadata", "deletionTimestamp"], "2026-10-31T00:00:00Z"),
          Map.put(policy, "specs", [spec]),
          put_in(policy, ["spec", "egressDeny"], []),
          put_in(policy, ["spec", "egress"], [%{"toEntities" => ["all"]}]),
          put_in(policy, ["spec", "endpointSelector"], %{"matchLabels" => %{}})
        ] do
      refute KataAdapter.preview_network_policy_valid?(unsafe)
    end
  end

  test "leaves the runtime class unset when the cluster does not configure one" do
    put_placement(runtime_class_name: "", node_selector: %{}, tolerations: [], affinity: %{})

    assert {:ok, %{"spec" => spec}} = KataAdapter.build_manifest("glossia-sb-1", %{})

    refute Map.has_key?(spec, "runtimeClassName")
    refute Map.has_key?(spec, "nodeSelector")
    refute Map.has_key?(spec, "tolerations")
    refute Map.has_key?(spec, "affinity")
  end

  test "follows the managed runner placement" do
    put_placement(
      runtime_class_name: "kata-qemu",
      node_selector: %{"glossia.io/managed-runner" => "true"},
      tolerations: [%{"key" => "managed-runner", "operator" => "Exists"}],
      affinity: %{}
    )

    assert {:ok, %{"spec" => spec}} = KataAdapter.build_manifest("glossia-sb-1", %{})

    assert spec["runtimeClassName"] == "kata-qemu"
    assert spec["nodeSelector"] == %{"glossia.io/managed-runner" => "true"}
    assert spec["tolerations"] == [%{"key" => "managed-runner", "operator" => "Exists"}]
    refute Map.has_key?(spec, "affinity")
  end

  test "runs the sandbox container without a service-account token or privileges" do
    put_placement([])

    assert {:ok, %{"spec" => %{"containers" => [container]} = spec}} =
             KataAdapter.build_manifest("glossia-sb-1", %{})

    assert spec["automountServiceAccountToken"] == false
    assert container["workingDir"] == "/tmp"

    assert container["securityContext"] == %{
             "allowPrivilegeEscalation" => false,
             "capabilities" => %{"drop" => ["ALL"]}
           }
  end
end
