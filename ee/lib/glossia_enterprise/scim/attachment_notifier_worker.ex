defmodule GlossiaEnterprise.SCIM.AttachmentNotifierWorker do
  @moduledoc "Notifies members when SCIM attaches them to an organization."
  use Oban.Worker, queue: :default, max_attempts: 5
  use GlossiaWeb, :verified_routes
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext
  import Swoosh.Email
  alias Glossia.{Accounts, Mailer, Organizations, Repo}
  alias Glossia.Emails.Layout

  @impl true
  def perform(%Oban.Job{args: %{"user_id" => user_id, "organization_id" => organization_id}}) do
    user = Accounts.get_user(user_id)
    organization = Organizations.get_organization(organization_id)

    if user && organization && Organizations.get_membership(organization, user) do
      organization = Repo.preload(organization, :account)

      Gettext.with_locale(GlossiaEnterpriseWeb.Gettext, user.locale || "en", fn ->
        case Mailer.deliver(email(user, organization)) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end
      end)
    else
      :ok
    end
  end

  def email(user, organization) do
    title =
      gettext("You were added to %{organization} on Glossia", organization: organization.name)

    paragraphs = [
      gettext(
        "Your identity provider added your account to %{organization} through automated user provisioning (SCIM).",
        organization: organization.name
      ),
      gettext(
        "If you expected this, no action is needed. Open the organization and sign in with your work identity."
      )
    ]

    footnote =
      gettext(
        "If this is unexpected, contact your identity provider administrator or an organization administrator to remove this access."
      )

    url =
      GlossiaWeb.Endpoint.url()
      |> URI.merge(~p"/#{organization.account.handle}")
      |> URI.to_string()

    new()
    |> to(user.email)
    |> from({"Glossia", "noreply@glossia.ai"})
    |> subject(title)
    |> html_body(
      Layout.render(%{
        title: title,
        paragraphs: paragraphs,
        action_label: gettext("Open organization"),
        action_url: url,
        footnote: footnote
      })
    )
    |> text_body(Enum.join([title | paragraphs] ++ [url, footnote], "\n\n"))
  end
end
