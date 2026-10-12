import Ecto.Query

alias Babel.Accounts.Account
alias Babel.Errors
alias Babel.Errors.Event
alias Babel.Errors.Issue
alias Babel.Errors.IssueCoalescer
alias Babel.Errors.SentryEvent
alias Babel.GoToMarket
alias Babel.GoToMarket.Prospect
alias Babel.Organizations.Interaction
alias Babel.Organizations.Organization
alias Babel.Operations.WorkItem
alias Babel.Repo

today = Date.utc_today()
now = DateTime.utc_now(:second)

# All people, organizations, research sources, and outreach below are fictional
# development examples. They do not describe real customers or prospects.
accounts = [
  %{email: "alex@example.com", name: "Alex", pomerium_id: "google/alex", last_seen_at: now},
  %{email: "jordan@example.com", name: "Jordan", pomerium_id: "google/jordan", last_seen_at: now},
  %{email: "morgan@example.com", name: "Morgan", pomerium_id: "google/morgan", last_seen_at: now},
  %{email: "taylor@example.com", name: "Taylor", pomerium_id: "google/taylor", last_seen_at: now}
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
    assignee: "Alex",
    due_on: Date.add(today, 2),
    priority: "High",
    status: "In progress",
    summary: "Prepare the Glossia customer adoption review"
  },
  %{
    area: "Finance",
    assignee: "Jordan",
    due_on: Date.add(today, 4),
    priority: "Urgent",
    status: "Blocked",
    summary: "Confirm the renewal scenario for the annual infrastructure contract"
  },
  %{
    area: "Growth",
    assignee: "Morgan",
    due_on: Date.add(today, 6),
    priority: "Normal",
    status: "Open",
    summary: "Publish the customer story approval checklist"
  },
  %{
    area: "Operations",
    assignee: "Taylor",
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
    name: "Cedar Trail",
    website_url: "https://cedar-trail.example.com",
    origin_url: "https://cedar-trail.example.com/stories/localization",
    state: "engaging",
    translation_tool: "Phrase",
    notes: "Sample multilingual content and content-management workflow."
  },
  %{
    name: "Summit Fitness",
    website_url: "https://summit-fitness.example.com",
    origin_url: "https://summit-fitness.example.com/stories/globalization",
    state: "researching",
    translation_tool: "Crowdin",
    notes: "Confirm the sample globalization contact before preparing outreach."
  },
  %{
    name: "Harbor Tickets",
    website_url: "https://harbor-tickets.example.com",
    origin_url: "https://harbor-tickets.example.com/stories/localization",
    state: "qualified",
    translation_tool: "Phrase",
    notes: "Sample small developer team scaling a translation workflow."
  },
  %{
    name: "Juniper Video",
    website_url: "https://juniper-video.example.com",
    origin_url: "https://juniper-video.example.com/stories/localization",
    state: "researching",
    translation_tool: "Lokalise",
    notes: "Sample localization outcome; no contact has been verified."
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
    company: "Cedar Trail",
    website_url: "https://cedar-trail.example.com",
    translation_tool: "Phrase",
    source_title: "Sample: scaling multilingual content at Cedar Trail",
    source_url: "https://cedar-trail.example.com/stories/localization",
    evidence:
      "This fictional case study describes scaling multilingual content and a content-management workflow while expanding into new markets.",
    contact_name: "Casey Morgan",
    contact_role: "Senior Manager, Localization",
    status: "ready",
    outreach_angle:
      "Demonstrate a reviewable voice and glossary check alongside the sample content workflow.",
    intro_email_draft: """
    Hi Casey,

    This is a fictional introduction for the Cedar Trail development example.

    We could demonstrate how voice and glossary guidance stays attached to a small, non-production content change, so a localization contact can inspect the proposed wording before it ships.

    Would a 20-minute working demo be useful?
    """,
    next_step: "Verify the sample localization contact.",
    organization_id: organizations_by_name["Cedar Trail"].id
  },
  %{
    company: "Summit Fitness",
    website_url: "https://summit-fitness.example.com",
    translation_tool: "Crowdin",
    source_title: "Sample: a multilingual fitness product",
    source_url: "https://summit-fitness.example.com/stories/globalization",
    evidence:
      "This fictional case study describes a global accessibility and market-launch localization program at a fitness company.",
    contact_name: "Robin Ellis",
    contact_role: "Globalization Director",
    status: "researching",
    outreach_angle:
      "Demonstrate repository-linked review context as an addition to the sample team's workflow.",
    intro_email_draft: """
    Hi Robin,

    This is a fictional introduction for the Summit Fitness development example.

    We could show how approved glossary and audience guidance stays attached to product changes, without adding another manual handoff.

    Would you like to review a small example together?
    """,
    next_step: "Verify the sample role and contact.",
    organization_id: organizations_by_name["Summit Fitness"].id
  },
  %{
    company: "Harbor Tickets",
    website_url: "https://harbor-tickets.example.com",
    translation_tool: "Phrase",
    source_title: "Sample: localization for a small ticketing team",
    source_url: "https://harbor-tickets.example.com/stories/localization",
    evidence:
      "This fictional case study describes a Rails application moving from translation files to a managed workflow as it adds languages.",
    contact_name: "Jamie Park",
    contact_role: "Chief Executive Officer",
    status: "ready",
    outreach_angle:
      "Demonstrate one pull request that keeps translation guidance beside the sample application files.",
    intro_email_draft: """
    Hi Jamie,

    This is a fictional introduction for the Harbor Tickets development example.

    We could review a small Rails-style pull request that keeps translation context and brand voice versioned with the application, with no migration required.

    Would a 20-minute demo be useful?
    """,
    next_step: "Verify the sample product or engineering contact route.",
    organization_id: organizations_by_name["Harbor Tickets"].id
  },
  %{
    company: "Juniper Video",
    website_url: "https://juniper-video.example.com",
    translation_tool: "Lokalise",
    source_title: "Sample: localization for a video platform",
    source_url: "https://juniper-video.example.com/stories/localization",
    evidence:
      "This fictional case study describes reducing developer time spent on localization, without naming a contact.",
    status: "researching",
    outreach_angle:
      "Demonstrate a repository review that identifies where localization context could be easier to inspect.",
    next_step: "Identify a sample localization contact.",
    organization_id: organizations_by_name["Juniper Video"].id
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
    organization_name: "Cedar Trail",
    kind: "research",
    summary: "Reviewed the fictional multilingual content case study.",
    body: "The sample source describes multilingual content and a content-management workflow.",
    source_url: "https://cedar-trail.example.com/stories/localization",
    occurred_at: DateTime.add(now, -7 * 86_400, :second)
  },
  %{
    organization_name: "Cedar Trail",
    kind: "introduction_draft",
    summary: "Prepared a fictional working-demo introduction for the sample contact.",
    body:
      "The sample draft offers a non-production content change and does not send anything automatically.",
    occurred_at: DateTime.add(now, -2 * 86_400, :second)
  },
  %{
    organization_name: "Summit Fitness",
    kind: "research",
    summary: "Captured the fictional globalization example for review.",
    body: "Confirm the sample role and contact before creating a demonstration introduction.",
    source_url: "https://summit-fitness.example.com/stories/globalization",
    occurred_at: DateTime.add(now, -5 * 86_400, :second)
  },
  %{
    organization_name: "Harbor Tickets",
    kind: "research",
    summary: "Reviewed the fictional Rails localization case study.",
    body: "A sample no-migration pull request demonstration is the next conversation artifact.",
    source_url: "https://harbor-tickets.example.com/stories/localization",
    occurred_at: DateTime.add(now, -4 * 86_400, :second)
  },
  %{
    organization_name: "Juniper Video",
    kind: "note",
    summary: "Identified a fictional localization example with no verified contact.",
    body: "Keep this sample organization in research until a contact and workflow are confirmed.",
    source_url: "https://juniper-video.example.com/stories/localization",
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

# Errors: a default DSN plus a handful of realistic issues so /errors
# renders something on a fresh dev database. Uses the real ingest path
# (SentryEvent.parse -> record_event) so grouping, fingerprinting, and
# status transitions match production behavior.

errors_org = Map.fetch!(organizations_by_name, "Northstar Learning")
:ok = Errors.ensure_default_key(errors_org.id)

errors_seed_payloads = [
  %{
    "event_id" => "0198b3ce6f007b2f9bc7345e34201001",
    "timestamp" => DateTime.to_iso8601(DateTime.add(now, -3600, :second)),
    "platform" => "elixir",
    "level" => "error",
    "environment" => "production",
    "release" => "glossia@2026.09.20",
    "server_name" => "glossia-web-6d8b7f-abc12",
    "transaction" => "GET /projects/:handle/-/translations",
    "exception" => %{
      "values" => [
        %{
          "type" => "Ecto.ConstraintError",
          "value" => "constraint error when attempting to insert struct: translations_project_id_locale_index",
          "stacktrace" => %{
            "frames" => [
              %{
                "filename" => "lib/glossia/translations.ex",
                "function" => "Glossia.Translations.upsert_translation/2",
                "lineno" => 187,
                "in_app" => true
              }
            ]
          }
        }
      ]
    },
    "user" => %{"id" => "u_142", "email" => "pierre@northstarlearning.example.com"},
    "request" => %{"url" => "https://glossia.ai/northstar-learning/tutorials/-/translations"},
    "tags" => %{"locale" => "fr", "runtime" => "otp-27.1"},
    "sdk" => %{"name" => "sentry.elixir", "version" => "10.2.0"}
  },
  %{
    "event_id" => "0198b3ce6f007b2f9bc7345e34201002",
    "timestamp" => DateTime.to_iso8601(DateTime.add(now, -900, :second)),
    "platform" => "javascript",
    "level" => "warning",
    "environment" => "production",
    "release" => "glossia-web@2026.09.20",
    "transaction" => "TranslationsDashboard",
    "exception" => %{
      "values" => [
        %{
          "type" => "TypeError",
          "value" => "Cannot read properties of undefined (reading 'segments')",
          "stacktrace" => %{
            "frames" => [
              %{
                "filename" => "app://dashboard/translations.tsx",
                "function" => "renderSegmentGrid",
                "lineno" => 214,
                "in_app" => true
              }
            ]
          }
        }
      ]
    },
    "user" => %{"id" => "u_318"},
    "request" => %{"url" => "https://glossia.ai/paper-kite-publishing/help/-/translations/es"},
    "tags" => %{"browser" => "chrome/128", "locale" => "es"},
    "sdk" => %{"name" => "sentry.javascript.browser", "version" => "8.31.0"}
  },
  %{
    "event_id" => "0198b3ce6f007b2f9bc7345e34201003",
    "timestamp" => DateTime.to_iso8601(DateTime.add(now, -180, :second)),
    "platform" => "elixir",
    "level" => "fatal",
    "environment" => "production",
    "release" => "glossia@2026.09.20",
    "server_name" => "glossia-flame-runner-72c1a",
    "transaction" => "Glossia.Sandbox.Runner",
    "exception" => %{
      "values" => [
        %{
          "type" => "MuonTrap.TimeoutError",
          "value" => "external command timed out after 60s",
          "stacktrace" => %{
            "frames" => [
              %{
                "filename" => "lib/glossia/sandbox/runner.ex",
                "function" => "Glossia.Sandbox.Runner.run/2",
                "lineno" => 94,
                "in_app" => true
              }
            ]
          }
        }
      ]
    },
    "tags" => %{"runner_pool" => "flame-lg", "job_kind" => "translate"},
    "sdk" => %{"name" => "sentry.elixir", "version" => "10.2.0"}
  },
  %{
    "event_id" => "0198b3ce6f007b2f9bc7345e34201004",
    "timestamp" => DateTime.to_iso8601(DateTime.add(now, -30, :second)),
    "platform" => "elixir",
    "level" => "info",
    "environment" => "production",
    "release" => "glossia@2026.09.20",
    "message" => %{"formatted" => "Cachex miss stampede on translations_settings; capping observed at 42 concurrent resolvers"},
    "tags" => %{"cache" => "translations_settings"},
    "sdk" => %{"name" => "sentry.elixir", "version" => "10.2.0"}
  }
]

# Second occurrence of the constraint error, from a different user +
# timestamp, so the first issue rolls up to event_count = 2.
duplicate_payload =
  errors_seed_payloads
  |> List.first()
  |> Map.merge(%{
    "event_id" => "0198b3ce6f007b2f9bc7345e34201005",
    "timestamp" => DateTime.to_iso8601(DateTime.add(now, -1200, :second)),
    "user" => %{"id" => "u_204", "email" => "mika@paperkite.example.com"}
  })

for payload <- errors_seed_payloads ++ [duplicate_payload] do
  event = SentryEvent.parse(payload)
  event_id = event.event_id |> Base.decode16!(case: :mixed) |> Ecto.UUID.load!()

  # Stable sample event IDs must not be reinserted or counted again on reruns.
  unless Repo.get(Event, event_id) do
    :ok = Errors.record_event(errors_org.id, event)
  end
end

# The coalescer batches rollups on a 5s tick; flush synchronously so
# seeded issues show accurate counts and last_seen the moment the
# server boots against a fresh database.
:ok = IssueCoalescer.flush()

# Demonstrate the resolved and ignored states on two of the issues.
issue_where_title_like = fn prefix ->
  Repo.one(
    from(i in Issue,
      where: i.organization_id == ^errors_org.id and like(i.title, ^"#{prefix}%"),
      limit: 1
    )
  )
end

if constraint_issue = issue_where_title_like.("Ecto.ConstraintError"),
  do: Errors.resolve_issue(constraint_issue)

if cachex_issue = issue_where_title_like.("Cachex miss stampede"),
  do: Errors.ignore_issue(cachex_issue)
