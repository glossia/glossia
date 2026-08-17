defmodule Glossia.Quality.Browser.Chromium do
  @moduledoc false

  alias Glossia.Quality.Artifacts
  alias Glossia.Quality.DOM
  alias Glossia.Sandboxes

  @browser_flags [
    "--headless",
    "--disable-gpu",
    "--disable-dev-shm-usage",
    "--hide-scrollbars",
    "--virtual-time-budget=5000",
    "--window-size=1440,1000"
  ]

  def health_check(sandbox, browser_policy) do
    command =
      Enum.join(
        ["chromium" | browser_flags(browser_policy) ++ ["--dump-dom", "about:blank"]],
        " "
      )

    case Sandboxes.execute_sandbox(sandbox, command,
           timeout_ms: 15_000,
           output_limit_bytes: 20_000
         ) do
      {:ok, %{"exitCode" => 0}} -> :ok
      _result -> {:error, :browser_sandbox_unavailable}
    end
  end

  def capture(run, sandbox, page_url, artifact_name, browser_policy) do
    with {:ok, %{"exitCode" => 0, "stdout" => output}} <-
           dump_document(sandbox, page_url, browser_policy) do
      parsed = DOM.parse(output, page_url)
      screenshot_path = capture_screenshot(run, sandbox, page_url, artifact_name, browser_policy)
      {:ok, Map.put(parsed, :screenshot_path, screenshot_path)}
    else
      {:ok, result} -> {:error, browser_error(result)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp dump_document(sandbox, page_url, browser_policy) do
    command =
      Enum.join(
        ["chromium" | browser_flags(browser_policy) ++ ["--dump-dom", page_url]],
        " "
      )

    Sandboxes.execute_sandbox(sandbox, command,
      timeout_ms: 45_000,
      output_limit_bytes: 1_500_000
    )
  end

  defp capture_screenshot(run, sandbox, page_url, artifact_name, browser_policy) do
    relative_path = "quality/#{artifact_name}.png"
    :ok = ensure_artifact_directory(sandbox)

    command =
      Enum.join(
        [
          "chromium"
          | browser_flags(browser_policy) ++ ["--screenshot=#{relative_path}", page_url]
        ],
        " "
      )

    with {:ok, %{"exitCode" => 0}} <-
           Sandboxes.execute_sandbox(sandbox, command, timeout_ms: 45_000),
         {:ok, content} <- Sandboxes.read_file(sandbox, relative_path) do
      Artifacts.store_screenshot(run, "#{artifact_name}.png", content)
    else
      _error -> nil
    end
  end

  defp ensure_artifact_directory(sandbox) do
    case Sandboxes.execute_sandbox(sandbox, "mkdir -p quality") do
      {:ok, %{"exitCode" => 0}} -> :ok
      _error -> :ok
    end
  end

  defp browser_error(result) do
    result["stdout"] || result["stderr"] || "The browser could not load this page."
  end

  defp browser_flags(browser_policy) do
    resolver_flag =
      ~s("--host-resolver-rules=#{Map.fetch!(browser_policy, :resolver_rules)}")

    @browser_flags ++ [resolver_flag]
  end
end
