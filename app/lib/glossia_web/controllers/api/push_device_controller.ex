defmodule GlossiaWeb.Api.PushDeviceController do
  use GlossiaWeb, :controller
  alias Glossia.Push
  alias Glossia.Push.Grants

  plug :native_client

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "push_devices",
    scale: :timer.hours(1),
    limit: 120,
    by: :user

  def capabilities(conn, _params), do: json(conn, Push.capabilities())

  def update(conn, %{"installation_id" => id}) do
    case Push.register(
           conn.assigns.current_user,
           conn.assigns.push_client_id,
           id,
           conn.body_params
         ) do
      {:ok, installation} -> json(conn, %{registered: true, registration_id: installation.id})
      {:error, reason} -> error(conn, reason)
    end
  end

  def delete(conn, %{"installation_id" => id}) do
    case Push.unregister(conn.assigns.current_user, conn.assigns.push_client_id, id) do
      :ok -> json(conn, %{deleted: true})
      {:error, reason} -> error(conn, reason)
    end
  end

  defp native_client(conn, _opts) do
    conn = put_resp_header(conn, "cache-control", "no-store")

    with %{id: user_id} <- conn.assigns[:current_user],
         {:ok, client_id} <- Grants.client_for_token(conn.assigns[:current_token], user_id) do
      assign(conn, :push_client_id, client_id)
    else
      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "native_client_required"})
        |> halt()
    end
  end

  defp error(conn, reason) do
    {status, error} =
      case reason do
        :invalid -> {:bad_request, "invalid_push_device"}
        :unavailable -> {:service_unavailable, "push_unavailable"}
        :retired -> {:conflict, "installation_retired"}
        :conflict -> {:conflict, "installation_conflict"}
      end

    conn |> put_status(status) |> json(%{error: error})
  end
end
