defmodule GlossiaWeb.Plugs.AuthorizeProject do
  @moduledoc "Authorizes an API capability and project visibility without requiring a second token scope."
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias Glossia.{Authz, Projects}

  def init(action), do: GlossiaWeb.Plugs.AuthorizeAccount.init(action)

  def call(conn, action) do
    conn = GlossiaWeb.Plugs.AuthorizeAccount.call(conn, action)

    if conn.halted do
      conn
    else
      account = conn.assigns.account

      if Authz.authorize?(:project_read, conn.assigns.current_user, account) do
        case Projects.get_project(account, conn.params["project"]) do
          nil -> reject(conn, :not_found, "project not found")
          project -> assign(conn, :project, project)
        end
      else
        reject(conn, :forbidden, "not_authorized")
      end
    end
  end

  defp reject(conn, status, error),
    do: conn |> put_status(status) |> json(%{error: error}) |> halt()
end
