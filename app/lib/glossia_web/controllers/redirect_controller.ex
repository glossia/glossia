defmodule GlossiaWeb.RedirectController do
  use GlossiaWeb, :controller

  def project_activity(conn, %{"handle" => handle, "project" => project}) do
    redirect(conn, to: "/#{handle}/#{project}")
  end

  def project_overview(conn, %{"handle" => handle, "project" => project}) do
    redirect(conn, to: "/#{handle}/#{project}")
  end

  def account(conn, %{"handle" => handle}) do
    redirect(conn, to: "/#{handle}")
  end
end
