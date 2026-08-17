defmodule GlossiaWeb.QualityScreenshotController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Projects
  alias Glossia.Quality
  alias Glossia.Quality.Artifacts

  def show(
        conn,
        %{
          "handle" => handle,
          "project" => project_handle,
          "run_id" => run_id,
          "page_id" => page_id
        }
      ) do
    with account when not is_nil(account) <- Accounts.get_account_by_handle(handle),
         project when not is_nil(project) <- Projects.get_project(account, project_handle),
         true <- Glossia.Authz.authorize?(:quality_read, conn.assigns.current_user, account),
         page when not is_nil(page) <- Quality.get_page(project, run_id, page_id),
         path when is_binary(path) <- page.screenshot_path,
         {:ok, body} <- Artifacts.fetch_screenshot(path) do
      conn
      |> put_resp_content_type("image/png")
      |> put_resp_header("cache-control", "private, max-age=300, must-revalidate")
      |> send_resp(200, body)
    else
      _ -> send_resp(conn, 404, "")
    end
  end
end
