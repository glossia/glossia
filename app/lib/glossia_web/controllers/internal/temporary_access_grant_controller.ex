defmodule GlossiaWeb.Internal.TemporaryAccessGrantController do
  @moduledoc false

  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Organizations
  alias Glossia.TemporaryAccess

  def create(
        conn,
        %{
          "organization_id" => organization_id,
          "email" => email,
          "requested_by_email" => requested_by_email,
          "requested_by_pomerium_id" => requested_by_pomerium_id,
          "reason" => reason
        } = params
      ) do
    with organization when not is_nil(organization) <-
           Organizations.get_organization(organization_id),
         recipient when not is_nil(recipient) <- Accounts.get_user_by_email(email),
         {:ok, grant} <-
           TemporaryAccess.grant(organization, recipient, %{
             "email" => email,
             "duration_minutes" => params["duration_minutes"],
             "requested_by_email" => requested_by_email,
             "requested_by_pomerium_id" => requested_by_pomerium_id,
             "reason" => reason
           }) do
      conn
      |> put_status(:created)
      |> json(%{
        "account_handle" => organization.account.handle,
        "expires_at" => DateTime.to_iso8601(grant.expires_at),
        "recipient_email" => grant.recipient_email,
        "temporary_access_grant_id" => grant.id
      })
    else
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "recipient_or_organization_not_found"})

      {:error, :invalid_duration} ->
        invalid_request(conn)

      {:error, :invalid_grant} ->
        invalid_request(conn)

      {:error, %Ecto.Changeset{}} ->
        invalid_request(conn)
    end
  end

  def create(conn, _params), do: invalid_request(conn)

  defp invalid_request(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "invalid_temporary_access_request"})
  end
end
