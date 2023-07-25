defmodule GlossiaWeb.API.Builder.TranslationController do
  use GlossiaWeb, :controller

  def show(conn, %{"translation_id" => translation_id}) do
    json(conn, %{"hello" => translation_id})
  end
end
