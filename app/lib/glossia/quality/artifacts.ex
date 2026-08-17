defmodule Glossia.Quality.Artifacts do
  @moduledoc false

  require Logger

  def store_screenshot(run, filename, content) when is_binary(content) do
    path = "quality/#{run.account_id}/#{run.project_id}/#{run.id}/#{Path.basename(filename)}"
    store_screenshot(path, content)
  end

  defp store_screenshot(path, content) do
    if local_directory() do
      store_local_screenshot(path, content, :local_storage_failed)
    else
      store_remote_screenshot(path, content)
    end
  end

  defp store_remote_screenshot(path, content) do
    case Glossia.Storage.upload(path, content, content_type: "image/png") do
      {:ok, _response} ->
        path

      {:error, reason} ->
        log_storage_failure(reason)
    end
  rescue
    error ->
      log_storage_failure(error)
  catch
    :exit, reason -> log_storage_failure(reason)
  end

  def fetch_screenshot("local:" <> relative_path) do
    with directory when is_binary(directory) <- local_directory(),
         {:ok, path} <- local_path(directory, relative_path) do
      File.read(path)
    else
      _ -> {:error, :screenshot_not_found}
    end
  end

  def fetch_screenshot(path) when is_binary(path) do
    case Glossia.Storage.download(path) do
      {:ok, %{body: body}} when is_binary(body) -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_screenshot("local:" <> relative_path) do
    with directory when is_binary(directory) <- local_directory(),
         {:ok, path} <- local_path(directory, relative_path) do
      case File.rm(path) do
        :ok -> :ok
        {:error, :enoent} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      _ -> {:error, :screenshot_not_found}
    end
  end

  def delete_screenshot(path) when is_binary(path), do: Glossia.Storage.delete(path)

  defp store_local_screenshot(path, content, storage_error) do
    with directory when is_binary(directory) <- local_directory(),
         {:ok, local_path} <- local_path(directory, path),
         :ok <- File.mkdir_p(Path.dirname(local_path)),
         :ok <- File.write(local_path, content) do
      "local:#{path}"
    else
      _ ->
        log_storage_failure(storage_error)
    end
  end

  defp log_storage_failure(reason) do
    Logger.warning("Could not store quality screenshot", reason: inspect(reason))
    nil
  end

  defp local_directory do
    Application.get_env(:glossia, __MODULE__, [])[:local_directory]
  end

  defp local_path(directory, relative_path) do
    root = Path.expand(directory)
    path = Path.expand(relative_path, root)

    if String.starts_with?(path, root <> "/") do
      {:ok, path}
    else
      {:error, :invalid_screenshot_path}
    end
  end
end
