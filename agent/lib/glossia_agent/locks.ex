defmodule GlossiaAgent.Locks do
  @moduledoc """
  Lock file management for incremental translation.
  Ported from agent/locks.ts / cli/internal/glossia/locks.go
  """

  defmodule OutputLock do
    @moduledoc false
    defstruct [:path, :hash, :context_hash, :checked_at]

    @type t :: %__MODULE__{
            path: String.t(),
            hash: String.t(),
            context_hash: String.t(),
            checked_at: String.t()
          }
  end

  defmodule LockFile do
    @moduledoc false
    defstruct [:source_path, source_hash: "", context_hash: "", outputs: %{}, updated_at: ""]

    @type t :: %__MODULE__{
            source_path: String.t(),
            source_hash: String.t(),
            context_hash: String.t(),
            outputs: %{String.t() => GlossiaAgent.Locks.OutputLock.t()},
            updated_at: String.t()
          }
  end

  @doc "Create a new empty lock for the given source path."
  @spec create_lock(String.t()) :: LockFile.t()
  def create_lock(source_path) do
    %LockFile{source_path: source_path}
  end

  @doc "Compute the file path for a lock file."
  @spec lock_path(String.t(), String.t()) :: String.t()
  def lock_path(root, source_path) do
    Path.join([root, ".glossia", "locks", source_path <> ".lock"])
  end

  @doc "Read a lock file. Returns nil if not found or invalid."
  @spec read_lock(String.t(), String.t()) :: LockFile.t() | nil
  def read_lock(root, source_path) do
    path = lock_path(root, source_path)

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> decode_lock(data)
          {:error, _} -> nil
        end

      {:error, _} ->
        nil
    end
  end

  @doc "Write a lock file to disk."
  @spec write_lock(String.t(), String.t(), LockFile.t()) :: :ok
  def write_lock(root, source_path, lock) do
    lock = %{lock | updated_at: DateTime.to_iso8601(DateTime.utc_now())}
    path = lock_path(root, source_path)
    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, Jason.encode!(encode_lock(lock), pretty: true) <> "\n")
    :ok
  end

  @doc "Get the context hash from a lock for a specific language."
  @spec lock_context_hash(LockFile.t() | nil, String.t()) :: String.t()
  def lock_context_hash(nil, _language), do: ""

  def lock_context_hash(lock, language) do
    case Map.get(lock.outputs, language) do
      %OutputLock{context_hash: hash} when hash != "" -> hash
      _ -> lock.context_hash || ""
    end
  end

  # -- Encoding/Decoding -------------------------------------------------------

  defp decode_lock(data) when is_map(data) do
    outputs =
      (data["outputs"] || %{})
      |> Enum.into(%{}, fn {key, val} ->
        {key,
         %OutputLock{
           path: val["path"] || "",
           hash: val["hash"] || "",
           context_hash: val["context_hash"] || "",
           checked_at: val["checked_at"] || ""
         }}
      end)

    %LockFile{
      source_path: data["source_path"] || "",
      source_hash: data["source_hash"] || "",
      context_hash: data["context_hash"] || "",
      outputs: outputs,
      updated_at: data["updated_at"] || ""
    }
  end

  defp encode_lock(%LockFile{} = lock) do
    outputs =
      Enum.into(lock.outputs, %{}, fn {key, %OutputLock{} = val} ->
        {key,
         %{
           "path" => val.path,
           "hash" => val.hash,
           "context_hash" => val.context_hash,
           "checked_at" => val.checked_at
         }}
      end)

    %{
      "source_path" => lock.source_path,
      "source_hash" => lock.source_hash,
      "context_hash" => lock.context_hash,
      "outputs" => outputs,
      "updated_at" => lock.updated_at
    }
  end
end
