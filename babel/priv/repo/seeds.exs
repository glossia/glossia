alias Babel.Accounts.Account
alias Babel.GoToMarket
alias Babel.GoToMarket.Prospect
alias Babel.Organizations.Interaction
alias Babel.Organizations.Organization
alias Babel.Operations.WorkItem
alias Babel.Repo

today = Date.utc_today()
now = DateTime.utc_now(:second)

accounts = [
  %{email: "marek@glossia.ai", name: "Marek", pomerium_id: "google/marek", last_seen_at: now},
  %{
    email: "paulina@glossia.ai",
    name: "Paulina",
    pomerium_id: "google/paulina",
    last_seen_at: now
  },
  %{email: "nina@glossia.ai", name: "Nina", pomerium_id: "google/nina", last_seen_at: now},
  %{email: "tomas@glossia.ai", name: "Tomas", pomerium_id: "google/tomas", last_seen_at: now}
]

for attributes <- accounts do
  case Repo.get_by(Account, email: attributes.email) do
    nil -> Repo.insert!(Account.registration_changeset(%Account{}, attributes))
    account -> Repo.update!(Account.identity_changeset(account, attributes))
  end
end

work_items = [
  %{
    area: "Customer success",
    assignee: "Marek",
    due_on: Date.add(today, 2),
    priority: "High",
    status: "In progress",
    summary: "Prepare the Glossia customer adoption review"
  },
  %{
    area: "Finance",
    assignee: "Paulina",
    due_on: Date.add(today, 4),
    priority: "Urgent",
    status: "Blocked",
    summary: "Confirm the renewal scenario for the annual infrastructure contract"
  },
  %{
    area: "Growth",
    assignee: "Nina",
    due_on: Date.add(today, 6),
    priority: "Normal",
    status: "Open",
    summary: "Publish the customer story approval checklist"
  },
  %{
    area: "Operations",
    assignee: "Tomas",
    due_on: Date.add(today, -1),
    priority: "Low",
    status: "Done",
    summary: "Archive the completed vendor due diligence packet"
  }
]

for attributes <- work_items do
  case Repo.get_by(WorkItem, summary: attributes.summary) do
    nil -> Repo.insert!(WorkItem.changeset(%WorkItem{}, attributes))
    work_item -> Repo.update!(WorkItem.changeset(work_item, attributes))
  end
end

organizations = [
  %{
    name: "Northstar Learning",
    website_url: "https://northstarlearning.example.com",
    state: "customer",
    translation_tool: "Managed in Glossia",
    notes: "An existing Glossia organization with a working localization program.",
    glossia_organization_id: "0198b3ce-6f00-7b2f-9bc7-345e3420c101",
    glossia_account_handle: "northstar-learning"
  },
  %{
    name: "Paper Kite Publishing",
    website_url: "https://paperkite.example.com",
    state: "customer",
    translation_tool: "Managed in Glossia",
    notes: "An existing Glossia organization whose relationship history is tracked in Babel.",
    glossia_organization_id: "0198b3ce-6f00-7b2f-9bc7-345e3420c102",
    glossia_account_handle: "paper-kite-publishing"
  },
  %{
    name: "Braze",
    website_url: "https://www.braze.com",
    origin_url: "https://phrase.com/customers/braze/",
    state: "engaging",
    translation_tool: "Phrase",
    notes: "Publicly evidenced multilingual content and content-management workflow."
  },
  %{
    name: "Strava",
    website_url: "https://www.strava.com",
    origin_url: "https://crowdin.com/customers",
    state: "researching",
    translation_tool: "Crowdin",
    notes: "Confirm the current public globalization contact before preparing outreach."
  },
  %{
    name: "Tito",
    website_url: "https://ti.to",
    origin_url: "https://phrase.com/customers/tito/",
    state: "qualified",
    translation_tool: "Phrase",
    notes: "Small developer team with a public history of scaling a translation workflow."
  },
  %{
    name: "Dailymotion",
    website_url: "https://www.dailymotion.com",
    origin_url: "https://lokalise.com/case-studies/",
    state: "researching",
    translation_tool: "Lokalise",
    notes: "Public localization outcome is relevant; current contact has not been verified."
  }
]

organizations_by_name =
  for attributes <- organizations, into: %{} do
    organization =
      case Repo.get_by(Organization, name: attributes.name) do
        nil -> Repo.insert!(Organization.changeset(%Organization{}, attributes))
        organization -> Repo.update!(Organization.changeset(organization, attributes))
      end

    {organization.name, organization}
  end

prospects = [
  %{
    company: "Braze",
    website_url: "https://www.braze.com",
    translation_tool: "Phrase",
    source_title: "How Braze Transformed Global Growth and Customer Engagement",
    source_url: "https://phrase.com/customers/braze/",
    evidence:
      "Braze describes scaling multilingual content and its Sanity content-management workflow while expanding into new markets.",
    contact_name: "Liz Lopacki",
    contact_role: "Senior Manager, Localization",
    status: "ready",
    outreach_angle:
      "Offer a working session that keeps product, help, and campaign copy aligned through a reviewable voice and terminology check alongside the existing workflow.",
    intro_email_draft: """
    Hi Liz,

    I read Braze's public story about scaling localized content through Sanity. Growing into new markets while keeping a consistent customer experience stood out.

    We are building Glossia for teams that want their voice and terminology to travel with code and content changes, with reviewable changes instead of another opaque handoff.

    Would you be open to a 20-minute working demo using a small, non-production content change? We could show how a localization contact can inspect the context and proposed wording before it ships.
    """,
    next_step: "Verify the current public localization contact.",
    organization_id: organizations_by_name["Braze"].id
  },
  %{
    company: "Strava",
    website_url: "https://www.strava.com",
    translation_tool: "Crowdin",
    source_title: "Companies and people making their products multilingual with Crowdin",
    source_url: "https://crowdin.com/customers",
    evidence:
      "Crowdin's public customer page attributes a global accessibility and market-launch localization program at Strava to its Globalization Director.",
    contact_name: "Eduardo D'Antonio",
    contact_role: "Globalization Director",
    status: "researching",
    outreach_angle:
      "Lead with an additive quality workflow, not a replacement pitch: show how repository-linked voice guidance makes localization context inspectable for a fast-moving product team.",
    intro_email_draft: """
    Hi Eduardo,

    I saw the public account of Strava's work to make its product more accessible to runners worldwide. It is a good example of localization being a product decision, not a final translation step.

    Glossia is exploring a repository-native way to keep approved terminology, audience guidance, and review context attached to the changes that create them.

    If it is useful, I would love to share a short demo focused on one question: how can a globalization team inspect the context behind a proposed change without adding another manual handoff?
    """,
    next_step: "Verify the current role and public contact.",
    organization_id: organizations_by_name["Strava"].id
  },
  %{
    company: "Tito",
    website_url: "https://ti.to",
    translation_tool: "Phrase",
    source_title: "The Fast and Scalable Localization Solution for Small Teams",
    source_url: "https://phrase.com/customers/tito/",
    evidence:
      "Tito's public case study describes a Ruby on Rails application that moved from difficult-to-maintain translation files to a managed workflow as it added languages.",
    contact_name: "Paul Campbell",
    contact_role: "Chief Executive Officer",
    status: "ready",
    outreach_angle:
      "Offer a no-migration proof of concept: review one pull request that keeps translation guidance and release context beside the existing application files.",
    intro_email_draft: """
    Hi Paul,

    I came across Tito's story about growing from translation files into a workflow that lets a small team add languages without pulling engineers into every handoff.

    We are building Glossia around a complementary idea: keep translation context, terminology, and brand voice versioned with the work that changes the product, so review stays concrete and familiar to developers.

    Would a 20-minute demo be useful? We can use a small Rails-style example and show the output as a pull request, with no migration or account setup required.
    """,
    next_step: "Verify the product or engineering contact route.",
    organization_id: organizations_by_name["Tito"].id
  },
  %{
    company: "Dailymotion",
    website_url: "https://www.dailymotion.com",
    translation_tool: "Lokalise",
    source_title: "Lokalise customer stories",
    source_url: "https://lokalise.com/case-studies/",
    evidence:
      "Lokalise publicly describes Dailymotion as reducing time to market and developer time spent on localization, which is a clear workflow signal but does not name a current contact.",
    status: "researching",
    outreach_angle:
      "Use a developer-led artifact to start the conversation: offer a public repository review that identifies where localization context could be easier to inspect in code.",
    next_step: "Identify a current public localization contact.",
    organization_id: organizations_by_name["Dailymotion"].id
  }
]

for attributes <- prospects do
  case Repo.get_by(Prospect, company: attributes.company, source_url: attributes.source_url) do
    nil ->
      case GoToMarket.create_prospect(attributes) do
        {:ok, _prospect} ->
          :ok

        {:error, changeset} ->
          raise "Could not seed go-to-market prospect: #{inspect(changeset.errors)}"
      end

    prospect ->
      case GoToMarket.update_prospect(prospect, attributes) do
        {:ok, _prospect} ->
          :ok

        {:error, changeset} ->
          raise "Could not update go-to-market prospect: #{inspect(changeset.errors)}"
      end
  end
end

interactions = [
  %{
    organization_name: "Braze",
    kind: "research",
    summary: "Reviewed the public Phrase customer story.",
    body:
      "The source describes multilingual content growth and a Sanity content-management workflow.",
    source_url: "https://phrase.com/customers/braze/",
    occurred_at: DateTime.add(now, -7 * 86_400, :second)
  },
  %{
    organization_name: "Braze",
    kind: "introduction_draft",
    summary: "Prepared a reviewed working-demo introduction for the localization contact.",
    body:
      "The draft offers a small, non-production content change and does not send anything automatically.",
    occurred_at: DateTime.add(now, -2 * 86_400, :second)
  },
  %{
    organization_name: "Strava",
    kind: "research",
    summary: "Captured the public Crowdin globalization signal for review.",
    body: "Confirm the role and current contact before creating a tailored introduction.",
    source_url: "https://crowdin.com/customers",
    occurred_at: DateTime.add(now, -5 * 86_400, :second)
  },
  %{
    organization_name: "Tito",
    kind: "research",
    summary:
      "Reviewed the public Phrase case study about scaling languages in a Rails application.",
    body: "A no-migration pull request demonstration is the proposed next conversation artifact.",
    source_url: "https://phrase.com/customers/tito/",
    occurred_at: DateTime.add(now, -4 * 86_400, :second)
  },
  %{
    organization_name: "Dailymotion",
    kind: "note",
    summary: "Identified a public localization workflow signal; contact remains unverified.",
    body:
      "Keep this organization in research until a current public contact and workflow are confirmed.",
    source_url: "https://lokalise.com/case-studies/",
    occurred_at: DateTime.add(now, -3 * 86_400, :second)
  }
]

for %{organization_name: organization_name} = attributes <- interactions do
  organization = Map.fetch!(organizations_by_name, organization_name)

  attributes =
    attributes |> Map.delete(:organization_name) |> Map.put(:organization_id, organization.id)

  case Repo.get_by(Interaction,
         organization_id: organization.id,
         kind: attributes.kind,
         summary: attributes.summary
       ) do
    nil -> Repo.insert!(Interaction.changeset(%Interaction{}, attributes))
    interaction -> Repo.update!(Interaction.changeset(interaction, attributes))
  end
end
