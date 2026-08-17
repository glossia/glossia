defmodule Glossia.Quality.Runner do
  @moduledoc "Runs one localization quality assurance audit inside a project sandbox."

  require Logger

  alias Glossia.Quality
  alias Glossia.Quality.Checks
  alias Glossia.Quality.PageAddress
  alias Glossia.Quality.URLSafety
  alias Glossia.Sandboxes

  def run(run_id, opts \\ []) do
    run = Quality.get_run!(run_id)
    adapter = Keyword.get(opts, :sandbox_adapter, Glossia.Sandbox.adapter())
    browser = Keyword.get(opts, :browser, Glossia.Quality.Browser.Chromium)

    with {:ok, browser_policy} <-
           URLSafety.browser_policy(run.configuration["locale_origins"]),
         {:ok, sandbox} <- create_sandbox(run, adapter) do
      case Quality.mark_run_running(run, sandbox.id) do
        {:ok, running} ->
          try do
            case browser_health_check(browser, sandbox, browser_policy) do
              :ok ->
                capture_and_check(running, sandbox, browser, browser_policy)

              {:error, reason} ->
                Quality.fail_run(running, reason)
                {:error, reason}
            end
          after
            Sandboxes.destroy_sandbox(sandbox,
              adapter: adapter,
              reason: "quality_run_completed"
            )
          end

        {:error, reason} ->
          _ =
            Sandboxes.destroy_sandbox(sandbox,
              adapter: adapter,
              reason: "quality_run_start_failed"
            )

          maybe_fail_run(run, reason)
          {:error, reason}
      end
    else
      {:error, reason} ->
        maybe_fail_run(run, reason)
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Quality run crashed",
        quality_run_id: run_id,
        reason: Exception.message(error)
      )

      case safe_get_run(run_id) do
        nil -> :ok
        run -> Quality.fail_run(run, error)
      end

      {:error, error}
  end

  defp capture_and_check(run, sandbox, browser, browser_policy) do
    pages = capture_pages(run, sandbox, browser, browser_policy)

    if Quality.run_active?(run) do
      {:ok, _event} =
        Quality.record_session_event(run, %{
          kind: "analysis_started",
          label: "Analyzing captured pages",
          detail: "The agent is comparing navigation, declared languages, and visible copy."
        })

      :ok = Checks.run(run, pages)

      case Quality.complete_run(run) do
        {:ok, _completed} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :quality_run_not_active}
    end
  end

  defp capture_pages(run, sandbox, browser, browser_policy) do
    configuration = run.configuration
    origins = configuration["locale_origins"] || %{}
    paths = (configuration["seed_paths"] || ["/"]) |> Enum.take(configuration["max_pages"] || 20)

    targets =
      for {locale, origin} <- Enum.sort(origins), logical_path <- paths do
        {locale, origin, logical_path}
      end
      |> Enum.take(100)

    targets
    |> Enum.reduce_while([], fn target, pages ->
      if Quality.run_active?(run) do
        case capture_page(run, sandbox, browser, browser_policy, target) do
          {:ok, page} ->
            Quality.heartbeat_run(run)
            {:cont, [page | pages]}

          :cancelled ->
            {:halt, pages}
        end
      else
        {:halt, pages}
      end
    end)
    |> Enum.reverse()
  end

  defp capture_page(run, sandbox, browser, browser_policy, {locale, origin, logical_path}) do
    page_url = PageAddress.build(origin, logical_path)
    artifact_name = artifact_name(locale, logical_path)

    {:ok, _event} =
      Quality.record_session_event(run, %{
        kind: "navigation_started",
        label: "Opening #{locale} #{logical_path}",
        detail: page_url,
        metadata: %{
          "locale" => locale,
          "logical_path" => logical_path,
          "requested_url" => page_url
        }
      })

    attrs =
      case browser.capture(run, sandbox, page_url, artifact_name, browser_policy) do
        {:ok, captured} ->
          Map.merge(captured, %{
            locale: locale,
            logical_path: logical_path,
            requested_url: page_url,
            final_url: page_url,
            load_error: nil
          })

        {:error, reason} ->
          %{
            locale: locale,
            logical_path: logical_path,
            requested_url: page_url,
            final_url: nil,
            visible_text: "",
            alternate_links: %{},
            load_error: inspect(reason)
          }
      end

    if Quality.run_active?(run) do
      {:ok, page} = Quality.create_page(run, attrs)

      {:ok, _event} =
        Quality.record_session_event(run, %{
          kind: "page_captured",
          label: "Captured #{locale} #{logical_path}",
          detail: page.title || page.final_url || page.requested_url,
          page_id: page.id,
          metadata: %{
            "locale" => page.locale,
            "logical_path" => page.logical_path,
            "load_error" => page.load_error
          }
        })

      {:ok, page}
    else
      :cancelled
    end
  end

  defp create_sandbox(run, adapter) do
    attrs = %{
      purpose: "quality_run",
      labels: %{
        "project_id" => to_string(run.project_id),
        "quality_run_id" => to_string(run.id),
        "purpose" => "quality_run"
      }
    }

    Sandboxes.create_sandbox(run.account, run.project, attrs, adapter: adapter)
  end

  defp browser_health_check(browser, sandbox, browser_policy) do
    if function_exported?(browser, :health_check, 2) do
      browser.health_check(sandbox, browser_policy)
    else
      :ok
    end
  end

  defp artifact_name(locale, logical_path) do
    digest = :crypto.hash(:sha256, logical_path) |> Base.encode16(case: :lower)
    "#{locale}-#{String.slice(digest, 0, 16)}"
  end

  defp safe_get_run(run_id) do
    Quality.get_run!(run_id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp maybe_fail_run(_run, :quality_run_not_pending), do: :ok
  defp maybe_fail_run(run, reason), do: Quality.fail_run(run, reason)
end
