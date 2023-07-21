defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  def github(conn, _params) do
    json(conn, nil)
  end
end
