defmodule GlossiaEnterprise.TranslationSessions.EngineRelease do
  @moduledoc """
  Identifies the running translation engine independently of repository content.

  A release is eligible for recovery only after its Kubernetes Deployment has
  fully rolled out, and only when this worker belongs to that release. An old
  web replica must never recover work backwards during a rolling update.
  """

  alias GlossiaEnterprise.Kubernetes

  defdelegate image(), to: Glossia.TranslationSessions.EngineRelease
  defdelegate pinned?(image), to: Glossia.TranslationSessions.EngineRelease

  def ready_image do
    case ready_release() do
      {:ok, %{image: image}} -> {:ok, image}
      other -> other
    end
  end

  def ready_release do
    deployment_name = Application.get_env(:glossia, :engine_deployment)

    with image when is_binary(image) <- image(),
         true <- pinned?(image),
         name when is_binary(name) and name != "" <- deployment_name,
         true <- Kubernetes.in_cluster?(),
         {:ok, namespace} <- Kubernetes.namespace(),
         {:ok, deployment} <- Kubernetes.get_deployment(namespace, name) do
      release(deployment, image, app_container_name())
    else
      {:error, reason} -> {:error, reason}
      _ -> :not_ready
    end
  end

  @doc false
  def release(deployment, image, container_name \\ "web") do
    with true <- ready?(deployment, image, container_name),
         {:ok, deployed_at} <- deployed_at(deployment) do
      {:ok, %{image: image, deployed_at: deployed_at}}
    else
      _ -> :not_ready
    end
  end

  def ready?(deployment, image, container_name \\ "web") when is_map(deployment) do
    generation = get_in(deployment, ["metadata", "generation"])
    replicas = get_in(deployment, ["spec", "replicas"]) || 1
    status = Map.get(deployment, "status", %{})
    containers = get_in(deployment, ["spec", "template", "spec", "containers"]) || []

    pinned?(image) and is_integer(generation) and replicas > 0 and
      is_nil(get_in(deployment, ["metadata", "deletionTimestamp"])) and
      (status["observedGeneration"] || 0) >= generation and
      status["updatedReplicas"] == replicas and status["replicas"] == replicas and
      (status["readyReplicas"] || 0) >= replicas and
      (status["availableReplicas"] || 0) >= replicas and
      Enum.any?(containers, &(&1["name"] == container_name and &1["image"] == image))
  end

  defp deployed_at(deployment) do
    condition =
      deployment
      |> get_in(["status", "conditions"])
      |> List.wrap()
      |> Enum.find(
        &(&1["type"] == "Progressing" and &1["status"] == "True" and
            &1["reason"] == "NewReplicaSetAvailable")
      )

    case condition && condition["lastUpdateTime"] do
      timestamp when is_binary(timestamp) ->
        case DateTime.from_iso8601(timestamp) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          _ -> :not_ready
        end

      _ ->
        :not_ready
    end
  end

  defp app_container_name do
    :glossia
    |> Application.get_env(:managed_runner, [])
    |> Keyword.get(:k8s, [])
    |> Keyword.get(:app_container_name, "web")
  end
end
