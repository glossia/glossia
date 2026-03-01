defmodule Glossia.Sandbox.Docker do
  @moduledoc """
  Docker-based sandbox adapter for development.

  Implements the five primitive sandbox operations using Docker CLI
  via MuonTrap. Agent session orchestration lives in `Glossia.Sandbox`.
  """

  @behaviour Glossia.Sandbox

  require Logger

  @image "node:22"

  @impl true
  def create(_params) do
    id = "glossia-setup-#{Uniq.UUID.uuid7()}"

    {_, 0} =
      MuonTrap.cmd("docker", [
        "create",
        "--name",
        id,
        @image,
        "sleep",
        "infinity"
      ])

    {_, 0} = MuonTrap.cmd("docker", ["start", id])

    Logger.info("Docker sandbox created: #{id}")
    {:ok, id}
  rescue
    e -> {:error, {:docker_create_failed, Exception.message(e)}}
  end

  @impl true
  def execute(sandbox_id, command, _opts \\ []) do
    case MuonTrap.cmd("docker", ["exec", sandbox_id, "sh", "-c", command], stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, %{"exitCode" => 0, "result" => output}}

      {output, code} ->
        {:ok, %{"exitCode" => code, "result" => output}}
    end
  rescue
    e -> {:error, {:docker_exec_failed, Exception.message(e)}}
  end

  @impl true
  def upload_file(sandbox_id, remote_path, content) do
    tmp_path = tmp_file_path("glossia-upload")

    try do
      File.write!(tmp_path, content)
      {_, 0} = MuonTrap.cmd("docker", ["cp", tmp_path, "#{sandbox_id}:#{remote_path}"])
      :ok
    after
      File.rm(tmp_path)
    end
  rescue
    e -> {:error, {:docker_upload_failed, Exception.message(e)}}
  end

  @impl true
  def download_file(sandbox_id, remote_path) do
    tmp_path = tmp_file_path("glossia-download")

    try do
      {_, 0} = MuonTrap.cmd("docker", ["cp", "#{sandbox_id}:#{remote_path}", tmp_path])
      {:ok, File.read!(tmp_path)}
    after
      File.rm(tmp_path)
    end
  rescue
    _e -> {:error, :file_not_found}
  end

  @impl true
  def delete(sandbox_id) do
    MuonTrap.cmd("docker", ["rm", "-f", sandbox_id])
    Logger.info("Docker sandbox deleted: #{sandbox_id}")
    :ok
  rescue
    e ->
      Logger.warning("Failed to delete Docker sandbox #{sandbox_id}: #{Exception.message(e)}")
      {:error, {:docker_delete_failed, Exception.message(e)}}
  end

  defp tmp_file_path(prefix) do
    Path.join("/tmp", "#{prefix}-#{:erlang.unique_integer([:positive])}")
  end
end
