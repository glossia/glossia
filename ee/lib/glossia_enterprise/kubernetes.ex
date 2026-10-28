defmodule GlossiaEnterprise.Kubernetes do
  @moduledoc """
  Minimal in-cluster Kubernetes API client.

  Reads the scheduling pod and Deployment rollout status and manages detached
  translation Jobs and sandbox Pods. Credentials are the projected service account
  token, the namespace, and the cluster CA — everything the pod already
  has, nothing to configure.
  """

  @service_account_dir "/var/run/secrets/kubernetes.io/serviceaccount"

  @doc "Whether this process is running inside a Kubernetes cluster."
  def in_cluster? do
    is_binary(System.get_env("KUBERNETES_SERVICE_HOST")) and File.dir?(@service_account_dir)
  end

  @doc "The namespace this pod belongs to."
  def namespace do
    case File.read(Path.join(@service_account_dir, "namespace")) do
      {:ok, namespace} -> {:ok, String.trim(namespace)}
      {:error, reason} -> {:error, {:namespace_unavailable, reason}}
    end
  end

  @doc "The manifest of the pod this process is running in."
  def self_pod do
    with {:ok, namespace} <- namespace(),
         {:ok, name} <- pod_name() do
      get(path(["api", "v1", "namespaces", namespace, "pods", name]))
    end
  end

  @doc "Reads a Deployment, including its rollout status."
  def get_deployment(namespace, name) do
    get(path(["apis", "apps", "v1", "namespaces", namespace, "deployments", name]))
  end

  @doc "Creates a Job in `namespace`."
  def create_job(namespace, manifest) do
    post(path(["apis", "batch", "v1", "namespaces", namespace, "jobs"]), manifest)
  end

  @doc "Reads a Job by name, or `{:error, :not_found}`."
  def get_job(namespace, name) do
    get(path(["apis", "batch", "v1", "namespaces", namespace, "jobs", name]))
  end

  @doc "Creates a Pod in `namespace`."
  def create_pod(namespace, manifest) do
    post(path(["api", "v1", "namespaces", namespace, "pods"]), manifest)
  end

  @doc "Reads a Pod by name, or `{:error, :not_found}`."
  def get_pod(namespace, name) do
    get(path(["api", "v1", "namespaces", namespace, "pods", name]))
  end

  @doc "Deletes a Pod. `propagationPolicy=Background` removes it and its dependents."
  def delete_pod(namespace, name) do
    ["api", "v1", "namespaces", namespace, "pods", name]
    |> path(%{"propagationPolicy" => "Background"})
    |> delete()
  end

  @doc """
  Deletes a Job and the pods it owns.

  `propagationPolicy=Background` is what removes the pods; without it the Job
  goes and its pods are left behind.
  """
  def delete_job(namespace, name) do
    ["apis", "batch", "v1", "namespaces", namespace, "jobs", name]
    |> path(%{"propagationPolicy" => "Background"})
    |> delete()
  end

  defp pod_name do
    case System.get_env("POD_NAME") do
      name when is_binary(name) and name != "" -> {:ok, name}
      _ -> {:error, :pod_name_unavailable}
    end
  end

  # The Kubernetes API is not one of glossia's routes, so `~p` does not apply.
  # Segments are escaped rather than interpolated so a name can never reshape
  # the path.
  defp path(segments, query \\ nil) do
    encoded = Enum.map_join(segments, "/", &URI.encode_www_form/1)
    %URI{path: "/" <> encoded, query: query && URI.encode_query(query)} |> URI.to_string()
  end

  defp get(path), do: request(:get, path, nil)
  defp post(path, body), do: request(:post, path, body)
  defp delete(path), do: request(:delete, path, nil)

  defp request(method, path, body) do
    with {:ok, token} <- token() do
      options =
        [
          method: method,
          url: url(path),
          headers: [{"authorization", "Bearer " <> token}],
          connect_options: [transport_opts: [cacertfile: ca_cert_path()]],
          receive_timeout: :timer.seconds(30),
          # A failed request is reported to the caller, which decides whether
          # the session can proceed. Retrying inside here would hide that.
          retry: false
        ]
        |> then(fn options -> if body, do: Keyword.put(options, :json, body), else: options end)

      # Built with `Req.new/1` rather than glossia's shared helper: pinning the
      # cluster CA needs `:connect_options`, and Req refuses that alongside the
      # `:finch` instance that helper configures.
      case options |> Req.new() |> OpentelemetryReq.attach() |> Req.request() do
        {:ok, %Req.Response{status: status, body: response_body}} when status in 200..299 ->
          {:ok, response_body}

        {:ok, %Req.Response{status: 404}} ->
          {:error, :not_found}

        {:ok, %Req.Response{status: 409}} ->
          {:error, :already_exists}

        {:ok, %Req.Response{status: status, body: response_body}} ->
          {:error, {:api_error, status, api_message(response_body)}}

        {:error, reason} ->
          {:error, {:transport_error, reason}}
      end
    end
  end

  defp url(path) do
    host = System.get_env("KUBERNETES_SERVICE_HOST")
    port = System.get_env("KUBERNETES_SERVICE_PORT_HTTPS") || "443"

    %URI{scheme: "https", host: host, port: String.to_integer(port)}
    |> URI.merge(path)
    |> URI.to_string()
  end

  defp token do
    case File.read(Path.join(@service_account_dir, "token")) do
      {:ok, token} -> {:ok, String.trim(token)}
      {:error, reason} -> {:error, {:token_unavailable, reason}}
    end
  end

  defp ca_cert_path, do: Path.join(@service_account_dir, "ca.crt")

  defp api_message(%{"message" => message}) when is_binary(message), do: message
  defp api_message(body), do: inspect(body)
end
