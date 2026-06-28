defmodule Glossia.FlameTest do
  use ExUnit.Case, async: true

  test "runner manifest copies parent pod fields without inheriting selector labels" do
    k8s_config = [
      runtime_class_name: "kata-qemu",
      resources: %{"requests" => %{"cpu" => "500m"}},
      node_selector: %{"pool" => "runners"},
      tolerations: [%{"key" => "runners", "operator" => "Exists"}],
      affinity: %{"podAntiAffinity" => %{}}
    ]

    manifest =
      Glossia.Flame.runner_manifest(
        %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/name" => "glossia",
              "app.kubernetes.io/instance" => "glossia"
            }
          },
          "spec" => %{
            "serviceAccountName" => "glossia",
            "imagePullSecrets" => [%{"name" => "registry-pull-secret"}]
          }
        },
        %{
          "env" => [
            %{"name" => "GLOSSIA_PHX_SERVER", "value" => "true"},
            %{"name" => "RELEASE_NODE", "value" => "glossia@$(POD_IP)"},
            %{
              "name" => "POD_NAME",
              "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
            },
            %{"name" => "CUSTOM_ENV", "value" => "kept"}
          ],
          "envFrom" => [%{"secretRef" => %{"name" => "glossia-app-env"}}]
        },
        k8s_config
      )

    assert manifest["metadata"]["labels"] == %{"app.kubernetes.io/component" => "runner"}
    assert manifest["spec"]["serviceAccountName"] == "glossia"
    assert manifest["spec"]["imagePullSecrets"] == [%{"name" => "registry-pull-secret"}]
    assert manifest["spec"]["runtimeClassName"] == "kata-qemu"
    assert manifest["spec"]["nodeSelector"] == %{"pool" => "runners"}
    assert manifest["spec"]["tolerations"] == [%{"key" => "runners", "operator" => "Exists"}]
    assert manifest["spec"]["affinity"] == %{"podAntiAffinity" => %{}}

    [container] = manifest["spec"]["containers"]
    assert container["env"] == [%{"name" => "CUSTOM_ENV", "value" => "kept"}]
    assert container["envFrom"] == [%{"secretRef" => %{"name" => "glossia-app-env"}}]
    assert container["resources"] == %{"requests" => %{"cpu" => "500m"}}
  end
end
