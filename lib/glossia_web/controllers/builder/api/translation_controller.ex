defmodule GlossiaWeb.Builder.API.TranslationController do
  use GlossiaWeb, :controller

  def create(conn, _params) do
    json(conn, %{"hello" => "yay"})
  end
end
