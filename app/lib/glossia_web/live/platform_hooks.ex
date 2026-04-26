defmodule GlossiaWeb.PlatformHooks do
  @moduledoc """
  LiveView on_mount hooks for the platform layout.

  Evolution of DashboardHooks that supports both authenticated and
  anonymous users viewing public accounts.

  Hooks:
    - `:load_user` - loads current_user from session (nil for anonymous)
    - `:load_account` - loads account from handle param, checks read access
    - `:check_write` - checks write/admin access, assigns can_write/is_admin
    - `:require_auth` - halts with redirect to login if no current_user
  """

  use GlossiaWeb, :verified_routes

  import Phoenix.Component, only: [assign: 3]

  alias Glossia.Accounts
  alias Glossia.Accounts.Scope
  alias Glossia.OgImage

  def on_mount(:load_user, _params, session, socket) do
    user =
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user(user_id)
      end

    {:cont,
     socket
     |> assign(:current_scope, Scope.for_user(user))
     |> assign(:current_user, user)
     |> assign(:impersonating_from, session["impersonating_from"])}
  end

  def on_mount(:load_account, params, _session, socket) do
    handle = params["handle"]
    user = socket.assigns[:current_user]

    case Accounts.get_account_by_handle(handle) do
      nil ->
        raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account

      account ->
        if Glossia.Authz.authorize?(:project_read, user, account) do
          accounts =
            if user do
              {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)
              accounts
            else
              []
            end

          og_image_url =
            if account.visibility == "public" do
              og_attrs = %{
                title: account.handle,
                description: account.handle,
                category: "account"
              }

              OgImage.account_url(handle, og_attrs)
            end

          {:cont,
           socket
           |> assign(:account, account)
           |> assign(:handle, handle)
           |> assign(:accounts, accounts)
           |> assign(:og_image_url, og_image_url)}
        else
          # For anonymous users on private accounts, show 404 (not login redirect).
          # Authenticated users who lack access also get 404.
          raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
        end
    end
  end

  def on_mount(:check_write, _params, _session, socket) do
    user = socket.assigns[:current_user]
    account = socket.assigns[:account]
    can_write = Glossia.Authz.authorize?(:project_write, user, account)
    is_admin = Glossia.Authz.authorize?(:project_admin, user, account)
    can_voice_read = Glossia.Authz.authorize?(:voice_read, user, account)
    can_voice_write = Glossia.Authz.authorize?(:voice_write, user, account)
    can_glossary_read = Glossia.Authz.authorize?(:glossary_read, user, account)
    can_glossary_write = Glossia.Authz.authorize?(:glossary_write, user, account)
    can_discussion_write = Glossia.Authz.authorize?(:discussion_write, user, account)

    can_voice_propose = can_discussion_write
    can_glossary_propose = can_discussion_write

    show_sidebar = user != nil

    {:cont,
     socket
     |> assign(:can_write, can_write)
     |> assign(:is_admin, is_admin)
     |> assign(:can_voice_read, can_voice_read)
     |> assign(:can_voice_write, can_voice_write)
     |> assign(:can_voice_propose, can_voice_propose)
     |> assign(:can_glossary_read, can_glossary_read)
     |> assign(:can_glossary_write, can_glossary_write)
     |> assign(:can_glossary_propose, can_glossary_propose)
     |> assign(:show_sidebar, show_sidebar)
     |> assign(:sidebar_context, :account)
     |> assign(:sidebar_project, nil)}
  end

  def on_mount(:require_auth, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
    end
  end
end
