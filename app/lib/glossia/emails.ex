defmodule Glossia.Emails do
  use GlossiaWeb, :verified_routes

  import Swoosh.Email

  alias Glossia.Emails.Layout
  use Gettext, backend: GlossiaWeb.Gettext

  @from {"Glossia", "noreply@glossia.ai"}

  def interest_email(email) do
    new()
    |> to("pedro@glossia.ai")
    |> from(@from)
    |> reply_to(email)
    |> subject("New interest in Glossia")
    |> html_body(
      Layout.render(%{
        title: "New interest in Glossia",
        paragraphs: ["Someone would like help getting started with Glossia.", email],
        action_label: "Get in touch",
        action_url: URI.to_string(%URI{scheme: "mailto", path: email}),
        footnote: "Reply to this email to get in touch and arrange onboarding."
      })
    )
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
    |> html_body(
      Layout.render(%{
        title: gettext("You have been invited to join %{org} on Glossia", org: org_name),
        paragraphs: [
          gettext("You have been invited to join %{org} on Glossia as a %{role}.",
            org: org_name,
            role: invitation.role
          ),
          gettext("This invitation expires in 7 days.")
        ],
        action_label: gettext("Accept or decline the invitation"),
        action_url: url,
        footnote:
          gettext("If you did not expect this invitation, you can safely ignore this email.")
      })
    )
    |> text_body("""
    #{gettext("You have been invited to join %{org} on Glossia as a %{role}.", org: org_name, role: invitation.role)}

    #{gettext("Accept or decline the invitation:")}
    #{url}

    #{gettext("This invitation expires in 7 days.")}

    #{gettext("If you did not expect this invitation, you can safely ignore this email.")}
    """)
  end

  defp invitation_url(token) do
    GlossiaWeb.Endpoint.url() |> URI.merge(~p"/invitations/#{token}") |> URI.to_string()
  end
end
