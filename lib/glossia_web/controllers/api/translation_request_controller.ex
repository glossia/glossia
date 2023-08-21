defmodule GlossiaWeb.API.TranslationRequestController do
  use GlossiaWeb, :controller

  def create(conn, _params) do
    json(conn, %{"hello" => "yay"})
  end
end
