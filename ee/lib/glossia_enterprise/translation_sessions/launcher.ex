defmodule GlossiaEnterprise.TranslationSessions.Launcher do
  @moduledoc """
  Isolated translation runner implementation.

  Runs each translation session in a Kubernetes Job that owns its own
  lifetime. A translation runs for an hour or more, and a rolling deploy of
  the web tier would kill anything tied to a web pod: this Job is created
  without an `ownerReference`, so nothing garbage-collects it when the pod
  that scheduled it is replaced.

  The Job pod is derived from the manifest of the scheduling pod, so it
  inherits the exact image, environment, `envFrom`, and pull secrets that
  were live at that moment. No long-lived worker sits around running last
  month's code — each translation runs the release image it was scheduled
  against.

  Job lifetime and resources come from `:glossia, :translation_job` config.
  Placement and the optional runtime class come from `:glossia, :managed_runner`.
  `config/runtime.exs` populates these from `GLOSSIA_TRANSLATION_JOB_*` and
  `GLOSSIA_MANAGED_*` environment variables. MicroVM isolation requires a
  configured runtime class such as `kata-qemu`.
  """

  require Logger

  alias Glossia.TranslationSessions
  alias GlossiaEnterprise.Kubernetes
  alias GlossiaEnterprise.TranslationSessions.EngineRelease

  @job_name_prefix "glossia-translate"
  @container_name "translate"

  def launch(session_id) do
    if Kubernetes.in_cluster?() do
      launch_job(session_id)
    else
      # No cluster to schedule onto (dev, test). Behave like the in-cluster fallback:
      # run the translation inline in the calling process.
      TranslationSessions.Translate.run(session_id)
      :ok
    end
  end

  def cancel(session_id) do
    if Kubernetes.in_cluster?() do
      cancel_job(session_id)
    else
      :ok
    end
  end

  defp cancel_job(session_id) do
    with {:ok, namespace} <- Kubernetes.namespace() do
      case Kubernetes.delete_job(namespace, job_name(session_id)) do
        {:ok, _body} -> :ok
        {:error, :not_found} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp launch_job(session_id) do
    with {:ok, namespace} <- Kubernetes.namespace(),
         {:ok, pod} <- Kubernetes.self_pod(),
         :ok <- release_ready(session_id),
         {:ok, manifest} <- build_manifest(session_id, pod) do
      case Kubernetes.create_job(namespace, manifest) do
        {:ok, _job} ->
          Logger.info("Launched detached translation job",
            translation_session_id: session_id,
            job_name: job_name(session_id)
          )

          :ok

        # A retried launch finds the Job it already created. The session is
        # already being translated, so this is success, not a collision.
        {:error, :already_exists} ->
          :ok

        {:error, reason} ->
          fail(session_id, reason)
      end
    else
      :not_ready -> {:snooze, 30}
      :not_active -> :ok
      {:error, reason} -> fail(session_id, reason)
    end
  end

  # Recovery jobs can be picked up by any replica. Do not let an old replica
  # spend a release continuation on the same engine while a rollout is pending.
  defp release_ready(session_id) do
    case TranslationSessions.get_session(session_id) do
      %{status: status} when status not in ["pending", "running"] ->
        :not_active

      %{engine_retry_count: count} = session when count > 0 ->
        case EngineRelease.ready_image() do
          {:ok, image} ->
            if image in session.previous_engine_images,
              do: {:error, :engine_already_attempted},
              else: :ok

          :not_ready ->
            if DateTime.diff(DateTime.utc_now(), session.inserted_at) >= 15 * 60,
              do: {:error, :engine_rollout_timeout},
              else: :not_ready

          {:error, reason} ->
            {:error, {:engine_release_unavailable, reason}}
        end

      nil ->
        :not_active

      _ ->
        :ok
    end
  end

  # Nothing is going to run, so the session is failed here rather than left
  # pending for the reaper. Reusing the run's own failure path keeps the
  # recorded error, the broadcast and the analytics event identical to a
  # translation that died halfway.
  defp fail(session_id, reason) do
    Logger.error("Could not launch detached translation job",
      translation_session_id: session_id,
      reason: inspect(reason)
    )

    TranslationSessions.Translate.fail_session(
      session_id,
      {:translation_job_launch_failed, reason}
    )

    {:error, {:translation_job_launch_failed, reason}}
  end

  @doc false
  def build_manifest(session_id, pod) do
    with {:ok, container} <- app_container(pod) do
      pod_spec = Map.get(pod, "spec", %{})

      {:ok,
       %{
         "apiVersion" => "batch/v1",
         "kind" => "Job",
         "metadata" => %{
           "name" => job_name(session_id),
           "labels" => %{
             "app.kubernetes.io/name" => "glossia",
             "app.kubernetes.io/component" => "translation",
             "glossia.ai/translation-session-id" => to_string(session_id)
           }
           # Deliberately no ownerReferences: an owner is what would let
           # Kubernetes delete this Job when the pod that created it is
           # replaced, which is the whole failure being fixed here.
         },
         "spec" =>
           %{
             # Every validated file is checkpointed to the translation branch.
             # A replacement pod therefore reuses that branch and plans only
             # the remaining stale files. Two bounded retries cover a pod or
             # gateway interruption without turning a persistent translation
             # error into an unbounded job.
             "backoffLimit" => 2,
             "ttlSecondsAfterFinished" => ttl_seconds_after_finished(),
             "template" => %{
               "metadata" => %{
                 "labels" => %{
                   "app.kubernetes.io/name" => "glossia",
                   "app.kubernetes.io/component" => "translation"
                 }
               },
               "spec" =>
                 %{
                   "restartPolicy" => "Never",
                   # The translation talks to Postgres, GitHub and the model
                   # gateway; it never talks to Kubernetes.
                   "automountServiceAccountToken" => false,
                   "containers" => [job_container(session_id, container)]
                 }
                 |> maybe_put("imagePullSecrets", Map.get(pod_spec, "imagePullSecrets"))
                 |> maybe_put("nodeSelector", placement(:node_selector))
                 |> maybe_put("tolerations", placement(:tolerations))
                 |> maybe_put("affinity", placement(:affinity))
                 |> maybe_put("runtimeClassName", placement(:runtime_class_name))
             }
           }
           |> maybe_put("activeDeadlineSeconds", active_deadline_seconds())
       }}
    end
  end

  defp job_container(session_id, container) do
    %{
      "name" => @container_name,
      "image" => Map.fetch!(container, "image"),
      # The image's own entrypoint is kept so the release boots the same way
      # it does everywhere else; only the role is different, and that is env.
      "env" => job_env(session_id, Map.get(container, "env", []), Map.fetch!(container, "image"))
    }
    |> maybe_put("imagePullPolicy", Map.get(container, "imagePullPolicy"))
    |> maybe_put("envFrom", Map.get(container, "envFrom"))
    |> maybe_put("resources", resources())
  end

  # The pod's own environment is inherited wholesale, which is what carries
  # the database URL, the distribution cookie and the downward-API POD_IP
  # that RELEASE_NODE interpolates. Order matters for that interpolation, so
  # entries are replaced in place rather than appended.
  defp job_env(session_id, env, image) do
    overrides = [
      %{"name" => "GLOSSIA_ENGINE_IMAGE", "value" => image},
      %{"name" => "GLOSSIA_TRANSLATION_JOB", "value" => "1"},
      %{"name" => "GLOSSIA_TRANSLATION_SESSION_ID", "value" => to_string(session_id)},
      # No HTTP server, no readiness probe, nothing to serve. The supervision
      # tree for this role omits the endpoint too; this keeps the release's
      # boot script from starting one before it gets there.
      %{"name" => "PHX_SERVER", "value" => "false"},
      %{"name" => "GLOSSIA_PHX_SERVER", "value" => "false"},
      %{"name" => "OTEL_SERVICE_NAME", "value" => "glossia-translation"}
    ]

    Enum.reduce(overrides, env, fn %{"name" => name} = override, acc ->
      case Enum.find_index(acc, &(Map.get(&1, "name") == name)) do
        nil -> acc ++ [override]
        index -> List.replace_at(acc, index, override)
      end
    end)
  end

  defp app_container(pod) do
    containers = get_in(pod, ["spec", "containers"]) || []

    case Enum.find(containers, &(Map.get(&1, "name") == app_container_name())) do
      nil -> {:error, {:app_container_not_found, app_container_name()}}
      container -> {:ok, container}
    end
  end

  @doc false
  def job_name(session_id), do: "#{@job_name_prefix}-#{session_id}"

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, _key, value) when value == %{}, do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp config, do: Application.get_env(:glossia, :translation_job, [])

  defp ttl_seconds_after_finished,
    do: Keyword.get(config(), :ttl_seconds_after_finished, 3_600)

  defp active_deadline_seconds, do: Keyword.get(config(), :active_deadline_seconds)

  defp resources, do: Keyword.get(config(), :resources, %{})

  defp app_container_name do
    :glossia
    |> Application.get_env(:managed_runner, [])
    |> Keyword.get(:k8s, [])
    |> Keyword.get(:app_container_name, "web")
  end

  # A translation is sized and placed the same way as a FLAME runner, so the
  # managed-runner k8s config supplies its placement description too.
  defp placement(key) do
    :glossia
    |> Application.get_env(:managed_runner, [])
    |> Keyword.get(:k8s, [])
    |> Keyword.get(key)
  end
end
