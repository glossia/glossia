defmodule Glossia.TranslationSessions.Launcher do
  @moduledoc """
  Starts a translation session as a Kubernetes Job that owns its own lifetime.

  A translation runs for an hour or more. Anything tied to the web pod's
  lifetime — a FLAME runner, a placed sandbox child, an Oban job executing in
  the web process — dies with it, and a web pod is replaced on every deploy, on
  every node drain, and on every eviction. No shutdown grace period can cover a
  job that long, so the work is moved out instead: the Job is created without an
  `ownerReference`, so nothing garbage-collects it when the pod that asked for
  it goes away, and it runs to completion on its own.

  The Job's pod spec is derived from the manifest of the pod doing the asking,
  so it inherits the exact image, environment and pull secrets that are live
  right now. That is what keeps it from drifting: each translation runs the code
  that was current when it started, with no long-lived worker to update.

  Outside a cluster there is nothing to schedule onto, so `:inline` runs the
  translation in the calling process, which is what development and tests want.
  """

  require Logger

  alias Glossia.Kubernetes
  alias Glossia.TranslationSessions

  @job_name_prefix "glossia-translate"
  @container_name "translate"

  @doc """
  Runs the session, detached when the cluster can host it.

  Returns `:ok` once the work is under way — for the Kubernetes backend that is
  when the Job has been accepted, not when the translation finishes.
  """
  def launch(session_id) do
    case backend() do
      :kubernetes -> launch_job(session_id)
      :inline -> TranslationSessions.Translate.run(session_id)
    end
  end

  @doc "Deletes the Job backing a session, used when a session is cancelled."
  def cancel(session_id) do
    with :kubernetes <- backend(),
         {:ok, namespace} <- Kubernetes.namespace() do
      case Kubernetes.delete_job(namespace, job_name(session_id)) do
        {:ok, _body} -> :ok
        {:error, :not_found} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :inline -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp launch_job(session_id) do
    with {:ok, namespace} <- Kubernetes.namespace(),
         {:ok, pod} <- Kubernetes.self_pod(),
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
      {:error, reason} -> fail(session_id, reason)
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
             # One attempt. Without checkpointing, a retry would re-translate
             # every file from the beginning and pay for it again, so a lost
             # pod is surfaced by the session reaper instead.
             "backoffLimit" => 0,
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
      # The image's own entrypoint is kept so the release boots the same way it
      # does everywhere else; only the role is different, and that is env.
      "env" => job_env(session_id, Map.get(container, "env", []))
    }
    |> maybe_put("imagePullPolicy", Map.get(container, "imagePullPolicy"))
    |> maybe_put("envFrom", Map.get(container, "envFrom"))
    |> maybe_put("resources", resources())
  end

  # The pod's own environment is inherited wholesale, which is what carries the
  # database URL, the distribution cookie and the downward-API POD_IP that
  # RELEASE_NODE interpolates. Order matters for that interpolation, so entries
  # are replaced in place rather than appended.
  defp job_env(session_id, env) do
    overrides = [
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

  defp config, do: Application.get_env(:glossia, __MODULE__, [])

  defp backend do
    case Keyword.get(config(), :backend) do
      nil -> if Kubernetes.in_cluster?(), do: :kubernetes, else: :inline
      backend -> backend
    end
  end

  defp ttl_seconds_after_finished,
    do: Keyword.get(config(), :ttl_seconds_after_finished, 3_600)

  defp active_deadline_seconds, do: Keyword.get(config(), :active_deadline_seconds)

  defp resources, do: Keyword.get(config(), :resources, %{})

  defp app_container_name do
    Application.get_env(:glossia, :flame, [])
    |> Keyword.get(:k8s, [])
    |> Keyword.get(:app_container_name, "web")
  end

  # A translation is sized and placed the same way it was as a FLAME runner, so
  # those knobs stay the single description of where this workload belongs.
  defp placement(key) do
    Application.get_env(:glossia, :flame, [])
    |> Keyword.get(:k8s, [])
    |> Keyword.get(key)
  end
end
