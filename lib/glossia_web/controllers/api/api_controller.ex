defmodule GlossiaWeb.API.APIController do
  # Modules
  use GlossiaWeb, :controller

  def not_found(%{ request_path: request_path, method: method } = conn, _params) do
    conn |> put_status(:not_found) |> json(%{errors: [%{detail: "#{method} #{request_path} is an invalid resource"}]})
  end
end
