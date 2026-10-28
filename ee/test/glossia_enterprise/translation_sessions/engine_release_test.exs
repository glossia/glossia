defmodule GlossiaEnterprise.TranslationSessions.EngineReleaseTest do
  use ExUnit.Case, async: true

  alias GlossiaEnterprise.TranslationSessions.EngineRelease

  @image "ghcr.io/glossia/glossia@sha256:#{String.duplicate("a", 64)}"

  defp deployment do
    %{
      "metadata" => %{"generation" => 2},
      "spec" => %{
        "replicas" => 2,
        "template" => %{"spec" => %{"containers" => [%{"name" => "web", "image" => @image}]}}
      },
      "status" => %{
        "observedGeneration" => 2,
        "replicas" => 2,
        "updatedReplicas" => 2,
        "readyReplicas" => 2,
        "availableReplicas" => 2,
        "conditions" => [
          %{
            "type" => "Progressing",
            "status" => "True",
            "reason" => "NewReplicaSetAvailable",
            "lastUpdateTime" => "2026-10-22T12:00:00Z"
          }
        ]
      }
    }
  end

  test "requires an immutable image and a fully observed, available rollout" do
    assert EngineRelease.ready?(deployment(), @image)
    refute EngineRelease.ready?(deployment(), "ghcr.io/glossia/glossia:main")
    refute EngineRelease.ready?(deployment(), String.replace(@image, "aaaa", "bbbb"))
    refute EngineRelease.ready?(%{}, @image)

    for {field, value} <- [
          {"observedGeneration", 1},
          {"replicas", 3},
          {"updatedReplicas", 1},
          {"readyReplicas", 1},
          {"availableReplicas", 1}
        ] do
      refute EngineRelease.ready?(put_in(deployment(), ["status", field], value), @image)
    end
  end

  test "requires a verified rollout completion time and the application container, not a sidecar" do
    assert {:ok, %{image: @image, deployed_at: ~U[2026-10-22 12:00:00Z]}} =
             EngineRelease.release(deployment(), @image)

    assert :not_ready =
             EngineRelease.release(put_in(deployment(), ["status", "conditions"], []), @image)

    refute EngineRelease.ready?(deployment(), @image, "another-container")

    changed =
      put_in(deployment(), ["spec", "template", "spec", "containers"], [
        %{"name" => "web", "image" => "old-image"},
        %{"name" => "sidecar", "image" => @image}
      ])

    refute EngineRelease.ready?(changed, @image)
  end

  test "does not treat a scaled-down or deleting deployment as a healthy release" do
    refute EngineRelease.ready?(put_in(deployment(), ["spec", "replicas"], 0), @image)

    refute EngineRelease.ready?(
             put_in(deployment(), ["metadata", "deletionTimestamp"], "2026-10-22T12:00:00Z"),
             @image
           )
  end
end
