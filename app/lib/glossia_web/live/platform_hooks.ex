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
  alias Glossia.TemporaryAccess

  def on_mount(:load_user, _params, session, socket) do
    user =
      case session["user_id"] do
        nil ->
          nil

        user_id ->
          user_id
          |> Accounts.get_user()
          |> TemporaryAccess.attach_pomerium_access(session["pomerium_access"])
      end

    {:cont,
     socket
     |> assign(:current_scope, Scope.for_user(user))
     |> assign(:current_user, user)
     |> assign(:organization_sso, session["organization_sso"])
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
          account = Glossia.Repo.preload(account, [:user, :organization])

          accounts =
            if user do
              {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)
              accounts
            else
              []
            end

          socket =
            socket
            |> assign(:account, account)
            |> assign(:handle, handle)
            |> assign(:accounts, accounts)
            |> Phoenix.LiveView.attach_hook(:organization_sso_events, :handle_event, fn _,
                                                                                        _,
                                                                                        socket ->
              require_organization_session(socket)
            end)
            |> Phoenix.LiveView.attach_hook(:organization_sso_navigation, :handle_params, fn _,
                                                                                             _,
                                                                                             socket ->
              require_organization_session(socket)
            end)
            |> Phoenix.LiveView.attach_hook(:organization_sso_messages, :handle_info, fn _,
                                                                                         socket ->
              require_organization_session(socket)
            end)
            |> Phoenix.LiveView.attach_hook(:organization_sso_async, :handle_async, fn _,
                                                                                       _,
                                                                                       socket ->
              require_organization_session(socket)
            end)

          require_organization_session(socket)
        else
          # For anonymous users on private accounts, show 404 (not login redirect).
          # Authenticated users who lack access also get 404.
          raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
        end
    end
  end

  def on_mount(:check_write, _params, _session, socket) do
    {:cont,
     socket
     |> assign_permissions()
     |> Phoenix.LiveView.attach_hook(:refresh_member_permissions, :handle_event, fn _event,
                                                                                    _params,
                                                                                    socket ->
       {:cont, assign_permissions(socket)}
     end)}
  end

  def on_mount(:require_auth, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
    end
  end

  defp require_organization_session(socket) do
    if Glossia.OrganizationAuthentication.session_authorized?(
         socket.assigns.account,
         socket.assigns.current_user,
         socket.assigns.organization_sso
       ) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
    end
  end

  defp assign_permissions(socket) do
    user = socket.assigns[:current_user]
    account = socket.assigns[:account]
    context = Glossia.MemberPermissions.context(user, account)

    authorize = fn action ->
      Glossia.Authz.authorize?(action, user, account, membership_context: context)
    end

    can_write = authorize.(:project_write)
    is_admin = authorize.(:organization_admin)
    can_voice_read = authorize.(:voice_read)
    can_voice_write = authorize.(:voice_write)
    can_glossary_read = authorize.(:glossary_read)
    can_glossary_write = authorize.(:glossary_write)
    can_discussion_write = authorize.(:discussion_write)

    can_manage_members = authorize.(:members_write)
    can_manage_credentials = authorize.(:api_credentials_read)
    can_manage_models = authorize.(:llm_model_read)

    can_voice_propose = can_discussion_write
    can_glossary_propose = can_discussion_write

    show_sidebar = user != nil

    socket
    |> assign(:can_write, can_write)
    |> assign(:is_admin, is_admin)
    |> assign(:can_manage_members, can_manage_members)
    |> assign(:can_manage_credentials, can_manage_credentials)
    |> assign(:can_manage_models, can_manage_models)
    |> assign(:can_voice_read, can_voice_read)
    |> assign(:can_voice_write, can_voice_write)
    |> assign(:can_voice_propose, can_voice_propose)
    |> assign(:can_glossary_read, can_glossary_read)
    |> assign(:can_glossary_write, can_glossary_write)
    |> assign(:can_glossary_propose, can_glossary_propose)
    |> assign(:show_sidebar, show_sidebar)
    |> assign(:sidebar_context, Map.get(socket.assigns, :sidebar_context, :account))
    |> assign(:sidebar_project, socket.assigns[:sidebar_project])
  end
end
