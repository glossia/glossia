defmodule GlossiaWeb.RedirectController do
  use GlossiaWeb, :controller

  def project_activity(conn, %{"handle" => handle, "project" => project}) do
    redirect(conn, to: "/#{handle}/#{project}/-/activity")
  end
end
