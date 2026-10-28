defmodule GlossiaEnterprise.TranslationSessions.LauncherTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.{Translate, TranslateWorker}
  alias GlossiaEnterprise.Kubernetes
  alias GlossiaEnterprise.TranslationSessions.{EngineRelease, Launcher}

  @image "ghcr.io/glossia/glossia@sha256:#{String.duplicate("b", 64)}"

  defp pod do
    %{
      "spec" => %{
        "containers" => [
          %{
            "name" => "web",
            "image" => @image,
            "imagePullPolicy" => "IfNotPresent",
            "env" => [
              %{"name" => "GLOSSIA_ENGINE_IMAGE", "value" => "incorrect-inherited-image"},
              %{
                "name" => "POD_IP",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
              },
              %{"name" => "RELEASE_NODE", "value" => "glossia@$(POD_IP)"}
            ],
            "envFrom" => [%{"secretRef" => %{"name" => "glossia"}}]
          }
        ],
        "imagePullSecrets" => [%{"name" => "ghcr"}]
      }
    }
  end

  test "pins the exact image and passes its identity to the executing process" do
    assert {:ok, manifest} = Launcher.build_manifest("session", pod())
    refute Map.has_key?(manifest["metadata"], "ownerReferences")
    [container] = get_in(manifest, ["spec", "template", "spec", "containers"])
    assert container["image"] == @image
    assert container["envFrom"] == [%{"secretRef" => %{"name" => "glossia"}}]

    assert Enum.filter(container["env"], &(&1["name"] == "GLOSSIA_ENGINE_IMAGE")) == [
             %{"name" => "GLOSSIA_ENGINE_IMAGE", "value" => @image}
           ]

    names = Enum.map(container["env"], & &1["name"])

    assert Enum.find_index(names, &(&1 == "POD_IP")) <
             Enum.find_index(names, &(&1 == "RELEASE_NODE"))
  end

  test "a release continuation waits until this worker's release is fully rolled out" do
    user = TestHelpers.create_user("release-launch@test.com", "release-launch")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{handle: "release", name: "Release"})

    {:ok, session} = TranslationSessions.create_session(user.account, project, %{})
    session |> Ecto.Changeset.change(engine_retry_count: 1) |> Repo.update!()

    stub(Kubernetes, :in_cluster?, fn -> true end)
    stub(Kubernetes, :namespace, fn -> {:ok, "glossia"} end)
    stub(Kubernetes, :self_pod, fn -> {:ok, pod()} end)
    stub(EngineRelease, :ready_image, fn -> :not_ready end)
    reject(&Kubernetes.create_job/2)
    assert {:snooze, 30} = Launcher.launch(session.id)
    assert TranslationSessions.get_session!(session.id).status == "pending"
  end

  test "API failures, repeated rollback images and expired rollout waits fail explicitly" do
    user = TestHelpers.create_user("failed-launch@test.com", "failed-launch")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{handle: "failed", name: "Failed"})

    {:ok, session} = TranslationSessions.create_session(user.account, project, %{})
    session |> Ecto.Changeset.change(engine_retry_count: 1) |> Repo.update!()

    stub(Kubernetes, :in_cluster?, fn -> true end)
    stub(Kubernetes, :namespace, fn -> {:ok, "glossia"} end)
    stub(Kubernetes, :self_pod, fn -> {:ok, pod()} end)
    reject(&Kubernetes.create_job/2)
    stub(Translate, :fail_session, fn _id, _reason -> :ok end)

    stub(EngineRelease, :ready_image, fn -> {:error, :forbidden} end)

    assert {:error, {:translation_job_launch_failed, {:engine_release_unavailable, :forbidden}}} =
             Launcher.launch(session.id)

    stub(EngineRelease, :ready_image, fn -> {:ok, @image} end)
    session |> Ecto.Changeset.change(previous_engine_images: [@image]) |> Repo.update!()

    assert {:error, {:translation_job_launch_failed, :engine_already_attempted}} =
             Launcher.launch(session.id)

    session
    |> Ecto.Changeset.change(
      previous_engine_images: [],
      inserted_at: DateTime.add(DateTime.utc_now(), -16 * 60, :second)
    )
    |> Repo.update!()

    stub(EngineRelease, :ready_image, fn -> :not_ready end)

    assert {:error, {:translation_job_launch_failed, :engine_rollout_timeout}} =
             Launcher.launch(session.id)
  end

  test "ordinary launches do not wait for a rollout or replace their pinned image" do
    user = TestHelpers.create_user("ordinary-launch@test.com", "ordinary-launch")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{handle: "ordinary", name: "Ordinary"})

    {:ok, session} = TranslationSessions.create_session(user.account, project, %{})
    stub(Kubernetes, :in_cluster?, fn -> true end)
    stub(Kubernetes, :namespace, fn -> {:ok, "glossia"} end)
    stub(Kubernetes, :self_pod, fn -> {:ok, pod()} end)
    reject(&EngineRelease.ready_image/0)
    expect(Kubernetes, :create_job, fn "glossia", _manifest -> {:ok, %{}} end)
    assert :ok = Glossia.TranslationSessions.Launcher.launch(session.id)
  end

  test "cancellation through the core facade deletes the enterprise job" do
    stub(Kubernetes, :in_cluster?, fn -> true end)
    stub(Kubernetes, :namespace, fn -> {:ok, "glossia"} end)
    expect(Kubernetes, :delete_job, fn "glossia", "glossia-translate-session" -> {:ok, %{}} end)
    assert :ok = Glossia.TranslationSessions.Launcher.cancel("session")
  end

  test "the translation worker propagates deployment waits to Oban" do
    expect(Glossia.TranslationSessions.Launcher, :launch, fn "session" -> {:snooze, 30} end)
    assert {:snooze, 30} = TranslateWorker.perform(%Oban.Job{args: %{"session_id" => "session"}})
  end

  test "the launcher creates the recovery job once its release is ready" do
    user = TestHelpers.create_user("ready-launch@test.com", "ready-launch")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{handle: "ready", name: "Ready"})

    {:ok, session} = TranslationSessions.create_session(user.account, project, %{})
    session |> Ecto.Changeset.change(engine_retry_count: 1) |> Repo.update!()

    stub(Kubernetes, :in_cluster?, fn -> true end)
    stub(Kubernetes, :namespace, fn -> {:ok, "glossia"} end)
    stub(Kubernetes, :self_pod, fn -> {:ok, pod()} end)
    stub(EngineRelease, :ready_image, fn -> {:ok, @image} end)

    expect(Kubernetes, :create_job, fn "glossia", manifest ->
      assert get_in(manifest, ["spec", "template", "spec", "containers", Access.at(0), "image"]) ==
               @image

      {:ok, %{}}
    end)

    assert :ok = Launcher.launch(session.id)
  end
end
