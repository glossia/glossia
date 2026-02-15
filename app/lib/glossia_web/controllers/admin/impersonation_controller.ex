defmodule GlossiaWeb.Admin.ImpersonationController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts

  def create(conn, %{"user_id" => user_id} = params) do
    reason = String.trim(params["reason"] || "")
    admin = conn.assigns.current_user

    if reason == "" do
      conn
      |> put_flash(:error, gettext("A reason is required to impersonate a user."))
      |> redirect(to: ~p"/admin/users")
    else
      target = Accounts.get_user(user_id)

      if target do
        Glossia.Auditing.record("admin.impersonation_started", admin.account, admin,
          resource_type: "user",
          resource_id: to_string(target.id),
          summary: "#{admin.email} started impersonating #{target.email}",
          metadata:
            JSON.encode!(%{
              admin_id: to_string(admin.id),
              admin_email: admin.email,
              target_id: to_string(target.id),
              target_email: target.email,
              reason: reason
            })
        )

        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, target.id)
        |> put_session(:impersonating_from, admin.id)
        |> put_session(:impersonation_reason, reason)
        |> put_flash(:info, gettext("You are now impersonating %{email}.", email: target.email))
        |> redirect(to: ~p"/dashboard")
      else
        conn
        |> put_flash(:error, gettext("User not found."))
        |> redirect(to: ~p"/admin/users")
      end
    end
  end

  def delete(conn, _params) do
    admin_id = get_session(conn, :impersonating_from)

    if admin_id do
      admin = Accounts.get_user(admin_id)

      if admin do
        target = conn.assigns.current_user

        Glossia.Auditing.record("admin.impersonation_ended", admin.account, admin,
          resource_type: "user",
          resource_id: if(target, do: to_string(target.id), else: ""),
          summary:
            "#{admin.email} stopped impersonating #{if target, do: target.email, else: "unknown"}",
          metadata:
            JSON.encode!(%{
              admin_id: to_string(admin.id),
              admin_email: admin.email,
              target_id: if(target, do: to_string(target.id), else: ""),
              target_email: if(target, do: target.email, else: "")
            })
        )

        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, admin_id)
        |> delete_session(:impersonating_from)
        |> delete_session(:impersonation_reason)
        |> put_flash(:info, gettext("Impersonation ended. You are back to your admin account."))
        |> redirect(to: ~p"/admin/users")
      else
        conn
        |> configure_session(drop: true)
        |> redirect(to: ~p"/auth/login")
      end
    else
      conn
      |> redirect(to: ~p"/admin")
    end
  end
end
