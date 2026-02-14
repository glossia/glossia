defmodule GlossiaWeb.DashboardController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    handle = conn.assigns.current_user.account.handle
    redirect(conn, to: "/#{handle}")
  end

  def account(conn, %{"handle" => handle}) do
    render(conn, :account,
      current_user: conn.assigns.current_user,
      handle: handle,
      projects: []
    )
  end

  def project(conn, %{"handle" => handle, "project" => project}) do
    render(conn, :project,
      current_user: conn.assigns.current_user,
      handle: handle,
      project_name: project
    )
  end
end
