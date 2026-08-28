defmodule Glossia.TranslationSessions.LauncherTest do
  use ExUnit.Case, async: true

  alias Glossia.TranslationSessions.Launcher

  @session_id "01a0479f-64e2-7645-b6e4-f26512c86260"

  defp pod do
    %{
      "metadata" => %{
        "name" => "glossia-6ddb46c6f-76bqw",
        "uid" => "8f2b0f1e-0000-4000-8000-000000000000",
        "labels" => %{"app.kubernetes.io/name" => "glossia"}
      },
      "spec" => %{
        "serviceAccountName" => "glossia-flame",
        "imagePullSecrets" => [%{"name" => "ghcr-pull-secret"}],
        "containers" => [
          %{
            "name" => "web",
            "image" => "ghcr.io/glossia/glossia@sha256:abc",
            "imagePullPolicy" => "IfNotPresent",
            "env" => [
              %{
                "name" => "POD_IP",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
              },
              %{"name" => "RELEASE_NODE", "value" => "glossia@$(POD_IP)"},
              %{"name" => "PHX_SERVER", "value" => "true"}
            ],
            "envFrom" => [%{"secretRef" => %{"name" => "glossia-app-env"}}],
            "ports" => [%{"containerPort" => 4050}],
            "livenessProbe" => %{"httpGet" => %{"path" => "/up"}}
          }
        ]
      }
    }
  end

  defp container(manifest) do
    manifest |> get_in(["spec", "template", "spec", "containers"]) |> hd()
  end

  defp env(manifest, name) do
    container(manifest)["env"] |> Enum.find(&(&1["name"] == name))
  end

  test "the Job has no owner, so no rollout can garbage-collect it" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    refute Map.has_key?(manifest["metadata"], "ownerReferences")
  end

  test "the Job does not retry, because a restart would re-translate everything" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    assert manifest["spec"]["backoffLimit"] == 0
    assert manifest["spec"]["template"]["spec"]["restartPolicy"] == "Never"
  end

  test "inherits the image and environment of the pod that created it" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    assert container(manifest)["image"] == "ghcr.io/glossia/glossia@sha256:abc"
    assert container(manifest)["envFrom"] == [%{"secretRef" => %{"name" => "glossia-app-env"}}]

    assert manifest["spec"]["template"]["spec"]["imagePullSecrets"] == [
             %{"name" => "ghcr-pull-secret"}
           ]
  end

  test "tells the pod which session it exists to translate" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    assert env(manifest, "GLOSSIA_TRANSLATION_JOB")["value"] == "1"
    assert env(manifest, "GLOSSIA_TRANSLATION_SESSION_ID")["value"] == @session_id

    assert manifest["metadata"]["labels"]["glossia.ai/translation-session-id"] == @session_id
  end

  test "turns the web server off rather than leaving the parent's value" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    assert env(manifest, "PHX_SERVER")["value"] == "false"
    assert env(manifest, "GLOSSIA_PHX_SERVER")["value"] == "false"
  end

  test "keeps POD_IP ahead of RELEASE_NODE so the node name still interpolates" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    names = Enum.map(container(manifest)["env"], & &1["name"])

    assert Enum.find_index(names, &(&1 == "POD_IP")) <
             Enum.find_index(names, &(&1 == "RELEASE_NODE"))

    assert env(manifest, "RELEASE_NODE")["value"] == "glossia@$(POD_IP)"
  end

  test "does not carry over the web container's ports or probes" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    refute Map.has_key?(container(manifest), "ports")
    refute Map.has_key?(container(manifest), "livenessProbe")
  end

  test "does not give the translation pod a Kubernetes token it never uses" do
    {:ok, manifest} = Launcher.build_manifest(@session_id, pod())

    assert manifest["spec"]["template"]["spec"]["automountServiceAccountToken"] == false
  end

  test "reports a pod whose app container cannot be found" do
    pod = put_in(pod(), ["spec", "containers"], [%{"name" => "sidecar", "image" => "x"}])

    assert {:error, {:app_container_not_found, "web"}} =
             Launcher.build_manifest(@session_id, pod)
  end

  test "names the Job after the session so a relaunch is a conflict, not a duplicate" do
    assert Launcher.job_name(@session_id) == "glossia-translate-#{@session_id}"
    assert String.length(Launcher.job_name(@session_id)) <= 63
  end
end
