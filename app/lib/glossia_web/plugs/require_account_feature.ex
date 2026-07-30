defmodule GlossiaWeb.Plugs.RequireAccountFeature do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Glossia.FeatureFlags

  def init(feature) when is_atom(feature), do: feature

  def call(%Plug.Conn{assigns: %{account: account}} = conn, :translation) do
    if FeatureFlags.translation_enabled?(account) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{
        error: %{
          message: "translation is not enabled for this account",
          type: "api_error",
          code: nil
        }
      })
      |> halt()
    end
  end
end
