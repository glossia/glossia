defmodule GlossiaWeb.OpsRedirectController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: ~p"/ops/dashboard")
  end
end
