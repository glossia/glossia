defmodule GlossiaWeb.ClaimableOrganizationController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Organizations

  def create(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    with account when not is_nil(account) <- Accounts.get_account_by_handle(handle),
         organization when not is_nil(organization) <-
           Organizations.get_organization_for_account(account),
         :ok <- Glossia.Authz.authorize(:organization_claim, user, account) do
      case Organizations.claim_organization(organization, user, via: :dashboard) do
        {:ok, _result} ->
          conn
          |> put_flash(:info, gettext("You now own this organization."))
          |> redirect(to: ~p"/#{account.handle}")

        {:error, :not_claimable} ->
          conn
          |> put_flash(:error, gettext("This organization is no longer available to claim."))
          |> redirect(to: ~p"/#{account.handle}")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, gettext("This organization could not be claimed."))
          |> redirect(to: ~p"/#{account.handle}")
      end
    else
      _error ->
        conn
        |> put_status(:not_found)
        |> put_view(GlossiaWeb.ErrorHTML)
        |> render(:"404")
    end
  end
end
