defmodule GlossiaWeb.DashboardController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts

  def index(conn, _params) do
    user = conn.assigns.current_user

    if user.account.has_access do
      redirect(conn, to: "/#{user.account.handle}")
    else
      redirect(conn, to: ~p"/billing")
    end
  end

  def account(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    render(conn, :account,
      current_user: user,
      handle: handle,
      accounts: Accounts.list_user_accounts(user),
      projects: []
    )
  end

  def project(conn, %{"handle" => handle, "project" => project}) do
    user = conn.assigns.current_user

    render(conn, :project,
      current_user: user,
      handle: handle,
      accounts: Accounts.list_user_accounts(user),
      project_name: project
    )
  end
end
