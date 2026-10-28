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
