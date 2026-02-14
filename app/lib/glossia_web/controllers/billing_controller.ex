defmodule GlossiaWeb.BillingController do
  use GlossiaWeb, :controller

  alias Glossia.Stripe

  def show(conn, _params) do
    user = conn.assigns.current_user
    account = user.account

    render(conn, :show,
      current_user: user,
      account: account,
      stripe_enabled: Stripe.enabled?(),
      page_title: gettext("Billing")
    )
  end

  def checkout(conn, _params) do
    user = conn.assigns.current_user
    account = user.account

    if Stripe.enabled?() do
      base_url = GlossiaWeb.Endpoint.url()
      success_url = base_url <> "/billing/return?session_id={CHECKOUT_SESSION_ID}"
      cancel_url = base_url <> "/billing"

      case Stripe.create_checkout_session(account, user, success_url, cancel_url) do
        {:ok, %{url: url}} ->
          redirect(conn, external: url)

        {:error, _reason} ->
          conn
          |> put_flash(:error, gettext("Couldn't start checkout. Please try again."))
          |> redirect(to: ~p"/billing")
      end
    else
      conn
      |> put_flash(:error, gettext("Billing isn't configured yet."))
      |> redirect(to: ~p"/billing")
    end
  end

  def return(conn, params) do
    user = conn.assigns.current_user
    account = user.account
    session_id = params["session_id"]

    if is_binary(session_id) and session_id != "" do
      case Stripe.sync_checkout_session_to_account(account, session_id) do
        {:ok, account} ->
          if account.has_access do
            conn
            |> put_flash(:info, gettext("You're subscribed. Welcome aboard."))
            |> redirect(to: ~p"/dashboard")
          else
            conn
            |> put_flash(:error, gettext("Checkout wasn't completed. Please try again."))
            |> redirect(to: ~p"/billing")
          end

        {:error, _reason} ->
          conn
          |> put_flash(:error, gettext("Couldn't verify checkout. Please try again."))
          |> redirect(to: ~p"/billing")
      end
    else
      conn
      |> put_flash(:error, gettext("Missing checkout information. Please try again."))
      |> redirect(to: ~p"/billing")
    end
  end

  def portal(conn, _params) do
    user = conn.assigns.current_user
    account = user.account

    case Stripe.customer_portal_url(account, GlossiaWeb.Endpoint.url() <> "/billing") do
      {:ok, url} ->
        redirect(conn, external: url)

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Couldn't open the customer portal. Please try again."))
        |> redirect(to: ~p"/billing")
    end
  end
end
