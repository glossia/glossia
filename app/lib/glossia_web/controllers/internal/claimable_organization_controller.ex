defmodule GlossiaWeb.Internal.ClaimableOrganizationController do
  @moduledoc false

  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.ChangesetErrors
  alias Glossia.Organizations

  def create(
        conn,
        %{
          "handle" => handle,
          "name" => name,
          "requested_by_email" => requested_by_email,
          "requested_by_pomerium_id" => requested_by_pomerium_id
        }
      ) do
    attrs = %{
      "handle" => handle,
      "name" => name
    }

    case Organizations.create_claimable_organization(
           attrs,
           via: :babel,
           requested_by_email: requested_by_email,
           requested_by_pomerium_id: requested_by_pomerium_id
         ) do
      {:ok, %{account: account, organization: organization}} ->
        conn
        |> put_status(:created)
        |> json(organization_response(organization, account))

      {:error, :account, changeset, _changes} ->
        validation_error(conn, changeset)

      {:error, :organization, changeset, _changes} ->
        validation_error(conn, changeset)
    end
  end

  def create(conn, _params), do: invalid_request(conn)

  def transfer(
        conn,
        %{
          "handle" => handle,
          "email" => email,
          "requested_by_email" => requested_by_email,
          "requested_by_pomerium_id" => requested_by_pomerium_id
        }
      ) do
    with account when not is_nil(account) <- Accounts.get_account_by_handle(handle),
         organization when not is_nil(organization) <-
           Organizations.get_organization_for_account(account),
         user when not is_nil(user) <- Accounts.get_user_by_email(email) do
      case Organizations.claim_organization(organization, user,
             actor: nil,
             via: :babel,
             requested_by_email: requested_by_email,
             requested_by_pomerium_id: requested_by_pomerium_id
           ) do
        {:ok, %{organization: claimed_organization}} ->
          json(conn, organization_response(claimed_organization, account, claimed_by: user.email))

        {:error, :not_claimable} ->
          conn |> put_status(:conflict) |> json(%{error: "organization_not_claimable"})

        {:error, %Ecto.Changeset{} = changeset} ->
          validation_error(conn, changeset)
      end
    else
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "organization_or_user_not_found"})
    end
  end

  def transfer(conn, _params), do: invalid_request(conn)

  defp organization_response(organization, account, extra \\ []) do
    %{
      id: organization.id,
      handle: account.handle,
      name: organization.name,
      claimable: organization.claimable,
      visibility: account.visibility
    }
    |> Map.merge(Map.new(extra))
  end

  defp validation_error(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: ChangesetErrors.to_map(changeset)})
  end

  defp invalid_request(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "invalid_claimable_organization_request"})
  end
end
