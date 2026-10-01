defmodule Glossia.EmailsTest do
  use ExUnit.Case, async: true

  alias Glossia.Accounts.OrganizationInvitation
  alias Glossia.Emails

  test "interest email uses Glossia branding and keeps a plain-text alternative" do
    email = Emails.interest_email("interested@example.com")

    assert email.to == [{"", "pedro@glossia.ai"}]
    assert email.reply_to == {"", "interested@example.com"}
    assert email.html_body =~ "https://glossia.ai/images/logo-rounded.png"
    assert email.html_body =~ "#6d3cc4"
    assert email.html_body =~ "#faf8f5"
    assert email.html_body =~ ~s(href="mailto:interested@example.com")
    assert email.text_body =~ "interested@example.com"
    refute email.html_body =~ "Tuist"
  end

  test "invitation email escapes organization names and uses the shared layout" do
    invitation = %OrganizationInvitation{
      email: "invitee@example.com",
      role: "member",
      token: "test-token"
    }

    email = Emails.invitation_email(invitation, "<script>alert('x')</script>")

    refute email.html_body =~ "<script>"
    assert email.html_body =~ "&lt;script&gt;"
    assert email.html_body =~ "https://glossia.ai/images/logo-rounded.png"
    assert email.html_body =~ "/invitations/test-token"
    assert email.text_body =~ "This invitation expires in 7 days."
  end
end
