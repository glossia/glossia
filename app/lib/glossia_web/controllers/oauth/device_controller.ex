defmodule GlossiaWeb.OAuth.DeviceController do
  use GlossiaWeb, :controller

  alias Boruta.ClientsAdapter
  alias Boruta.Oauth.Client
  alias Glossia.OAuth.DeviceAuthorization
  alias Glossia.OAuth.DeviceFlow

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "oauth_device_authorization",
         scale: :timer.minutes(1),
         limit: 20,
         by: [:ip, :client_id]
       ]
       when action in [:device_authorization]

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "oauth_device_verify",
         scale: :timer.minutes(1),
         limit: 60,
         by: :ip,
         format: :text
       ]
       when action in [:verify, :submit_code]

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "oauth_device_confirm",
         scale: :timer.minutes(1),
         limit: 30,
         by: :user,
         format: :text
       ]
       when action in [:confirm]

  def device_authorization(conn, params) do
    scope = Map.get(params, "scope", "")

    with {:ok, client} <- authenticate_client(params),
         :ok <- DeviceFlow.ensure_first_party_device_client(client),
         {:ok, result} <- DeviceFlow.start_authorization(client, scope) do
      verification_uri = "#{Boruta.Config.issuer()}/oauth/device"
      verification_uri_complete = "#{verification_uri}?user_code=#{result.user_code}"

      conn
      |> put_status(:ok)
      |> json(%{
        device_code: result.device_code,
        user_code: result.user_code,
        verification_uri: verification_uri,
        verification_uri_complete: verification_uri_complete,
        expires_in: result.expires_in,
        interval: result.interval
      })
    else
      {:error, :invalid_client} ->
        oauth_error(conn, :unauthorized, "invalid_client", "Client authentication failed.")

      {:error, :unauthorized_client} ->
        oauth_error(
          conn,
          :bad_request,
          "unauthorized_client",
          "Client is not allowed to use the device flow."
        )

      {:error, :invalid_scope} ->
        oauth_error(conn, :bad_request, "invalid_scope", "Requested scope is invalid.")

      {:error, :code_generation_failed} ->
        oauth_error(conn, :internal_server_error, "server_error", "Could not create device code.")

      {:error, {:validation, _changeset}} ->
        oauth_error(conn, :internal_server_error, "server_error", "Could not store device code.")
    end
  end

  def verify(conn, params) do
    verification = verification_from_params(params)

    conn
    |> put_view(GlossiaWeb.OAuth.DeviceHTML)
    |> render(:verify, verification: verification)
  end

  def submit_code(conn, %{"user_code" => raw_user_code}) do
    case DeviceFlow.normalize_user_code(raw_user_code) do
      {:ok, normalized_user_code} ->
        redirect(conn, to: ~p"/oauth/device?user_code=#{normalized_user_code}")

      {:error, :invalid_user_code} ->
        conn
        |> put_flash(:error, gettext("Invalid user code."))
        |> redirect(to: ~p"/oauth/device")
    end
  end

  def confirm(conn, %{"user_code" => raw_user_code, "decision" => decision}) do
    user = conn.assigns.current_user

    case DeviceFlow.get_by_user_code(raw_user_code) do
      {:ok, %DeviceAuthorization{} = authorization} ->
        case authorization_state(authorization) do
          :pending ->
            case decision do
              "approve" ->
                case DeviceFlow.approve(authorization, user.id) do
                  {:ok, _authorization} ->
                    conn
                    |> put_flash(:info, gettext("Device authorized. You can return to the app."))
                    |> redirect(to: ~p"/oauth/device?user_code=#{authorization.user_code}")

                  {:error, _changeset} ->
                    conn
                    |> put_flash(:error, gettext("Could not authorize the device."))
                    |> redirect(to: ~p"/oauth/device")
                end

              "deny" ->
                case DeviceFlow.deny(authorization, user.id) do
                  {:ok, _authorization} ->
                    conn
                    |> put_flash(:info, gettext("Authorization denied."))
                    |> redirect(to: ~p"/oauth/device?user_code=#{authorization.user_code}")

                  {:error, _changeset} ->
                    conn
                    |> put_flash(:error, gettext("Could not deny the device request."))
                    |> redirect(to: ~p"/oauth/device")
                end

              _ ->
                conn
                |> put_flash(:error, gettext("Invalid decision."))
                |> redirect(to: ~p"/oauth/device?user_code=#{authorization.user_code}")
            end

          _ ->
            conn
            |> put_flash(:error, gettext("This device code is no longer active."))
            |> redirect(to: ~p"/oauth/device")
        end

      {:error, :invalid_user_code} ->
        conn
        |> put_flash(:error, gettext("Invalid user code."))
        |> redirect(to: ~p"/oauth/device")
    end
  end

  defp verification_from_params(%{"user_code" => raw_user_code}) do
    case DeviceFlow.get_by_user_code(raw_user_code) do
      {:ok, %DeviceAuthorization{} = authorization} ->
        client = ClientsAdapter.get_client(authorization.client_id)

        %{
          user_code: authorization.user_code,
          client_name: client && client.name,
          status: authorization_state(authorization),
          scopes: String.split(authorization.scope || "", " ", trim: true)
        }

      {:error, :invalid_user_code} ->
        %{status: :invalid_user_code}
    end
  end

  defp verification_from_params(_params), do: nil

  defp authorization_state(%DeviceAuthorization{expires_at: expires_at, status: status}) do
    if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
      :expired
    else
      case status do
        "pending" -> :pending
        "approved" -> :approved
        "denied" -> :denied
        "consumed" -> :consumed
        _ -> :unknown
      end
    end
  end

  defp authorization_state(_), do: :unknown

  defp authenticate_client(%{"client_id" => client_id} = params) when is_binary(client_id) do
    client = ClientsAdapter.get_client(client_id)
    client_secret = Map.get(params, "client_secret")

    case client do
      %Client{} = client ->
        if client.confidential do
          case client_secret do
            secret when is_binary(secret) and secret != "" ->
              case Client.check_secret(client, secret) do
                :ok -> {:ok, client}
                _ -> {:error, :invalid_client}
              end

            _ ->
              {:error, :invalid_client}
          end
        else
          {:ok, client}
        end

      _ ->
        {:error, :invalid_client}
    end
  end

  defp authenticate_client(_params), do: {:error, :invalid_client}

  defp oauth_error(conn, status, error, description) do
    conn
    |> put_status(status)
    |> json(%{error: error, error_description: description})
  end
end
