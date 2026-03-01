defmodule GlossiaWeb.InvitationController do
  use GlossiaWeb, :controller

  alias Glossia.Auditing
  alias Glossia.Organizations

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "invitation_response",
         scale: :timer.hours(1),
         limit: 30,
         by: :user,
         format: :text
       ]
       when action in [:accept, :decline]

  def show(conn, %{"token" => token}) do
    case Organizations.get_invitation_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, gettext("This invitation is not valid or has already been used."))
        |> redirect(to: ~p"/")

      invitation ->
        cond do
          invitation.status != "pending" ->
            conn
            |> put_flash(
              :info,
              gettext("This invitation has already been %{status}.", status: invitation.status)
            )
            |> redirect(to: ~p"/")

          DateTime.compare(DateTime.utc_now(), invitation.expires_at) == :gt ->
            conn
            |> put_flash(:error, gettext("This invitation has expired."))
            |> redirect(to: ~p"/")

          is_nil(conn.assigns[:current_user]) ->
            conn
            |> put_session(:return_to, ~p"/invitations/#{token}")
            |> redirect(to: ~p"/auth/login")

          true ->
            org = Organizations.get_organization(invitation.organization_id)

            render(conn, :show,
              invitation: invitation,
              org_name: org.name,
              token: token,
              page_title: gettext("Invitation to %{org}", org: org.name)
            )
        end
    end
  end

  def accept(conn, %{"token" => token}) do
    user = conn.assigns[:current_user]

    if is_nil(user) do
      conn
      |> put_session(:return_to, ~p"/invitations/#{token}")
      |> redirect(to: ~p"/auth/login")
    else
      case Organizations.get_invitation_by_token(token) do
        nil ->
          conn
          |> put_flash(:error, gettext("This invitation is not valid."))
          |> redirect(to: ~p"/")

        invitation ->
          case Organizations.accept_invitation(invitation, user) do
            {:ok, _result} ->
              org = Organizations.get_organization(invitation.organization_id)
              handle = org.account.handle

              Auditing.record("member.invitation_accepted", org.account, user,
                resource_type: "invitation",
                resource_id: to_string(invitation.id),
                resource_path: "/#{handle}/-/members",
                summary: "#{user.email} accepted invitation as #{invitation.role}"
              )

              conn
              |> put_flash(:info, gettext("You have joined %{org}.", org: org.name))
              |> redirect(to: ~p"/#{handle}")

            {:error, :expired} ->
              conn
              |> put_flash(:error, gettext("This invitation has expired."))
              |> redirect(to: ~p"/")

            {:error, :already_accepted} ->
              conn
              |> put_flash(:info, gettext("This invitation has already been accepted."))
              |> redirect(to: ~p"/")

            {:error, :already_member} ->
              conn
              |> put_flash(:info, gettext("You are already a member of this organization."))
              |> redirect(to: ~p"/")

            {:error, _} ->
              conn
              |> put_flash(:error, gettext("Something went wrong."))
              |> redirect(to: ~p"/")
          end
      end
    end
  end

  def decline(conn, %{"token" => token}) do
    user = conn.assigns[:current_user]

    case Organizations.get_invitation_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, gettext("This invitation is not valid."))
        |> redirect(to: ~p"/")

      invitation ->
        case Organizations.decline_invitation(invitation) do
          {:ok, _} ->
            if org = Organizations.get_organization(invitation.organization_id) do
              Auditing.record("member.invitation_declined", org.account, user,
                resource_type: "invitation",
                resource_id: to_string(invitation.id),
                resource_path: "/#{org.account.handle}/-/members",
                summary: "#{invitation.email} declined invitation as #{invitation.role}"
              )
            end

            conn
            |> put_flash(:info, gettext("Invitation declined."))
            |> redirect(to: ~p"/")

          {:error, _} ->
            conn
            |> put_flash(:error, gettext("Something went wrong."))
            |> redirect(to: ~p"/")
        end
    end
  end
end
