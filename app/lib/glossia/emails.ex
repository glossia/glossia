defmodule Glossia.Emails do
  import Swoosh.Email
  use Gettext, backend: GlossiaWeb.Gettext

  @from {"Glossia", "noreply@glossia.ai"}

  def invitation_email(%Glossia.Accounts.OrganizationInvitation{} = invitation, org_name) do
    url = invitation_url(invitation.token)

    new()
    |> to(invitation.email)
    |> from(@from)
    |> subject(gettext("You have been invited to join %{org} on Glossia", org: org_name))
    |> text_body("""
    #{gettext("You have been invited to join %{org} on Glossia as a %{role}.", org: org_name, role: invitation.role)}

    #{gettext("Accept or decline the invitation:")}
    #{url}

    #{gettext("This invitation expires in 7 days.")}

    #{gettext("If you did not expect this invitation, you can safely ignore this email.")}
    """)
  end

  defp invitation_url(token) do
    GlossiaWeb.Endpoint.url() <> "/invitations/" <> token
  end
end
