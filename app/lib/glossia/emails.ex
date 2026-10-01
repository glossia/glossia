defmodule Glossia.Emails do
  import Swoosh.Email
  use Gettext, backend: GlossiaWeb.Gettext

  @from {"Glossia", "noreply@glossia.ai"}

  def interest_email(email) do
    new()
    |> to("pedro@glossia.ai")
    |> from(@from)
    |> reply_to(email)
    |> subject("New interest in Glossia")
    |> text_body("""
    Someone has expressed interest in Glossia and would like help getting started.

    Email: #{email}

    Reply to this email to get in touch and arrange onboarding.
    """)
  end

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
