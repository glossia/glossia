# Script for populating the database with realistic development data.
#
# Run with:
#
#     mix run priv/repo/seeds.exs
#
# This script is intended to be idempotent: it should be safe to run multiple
# times without creating a pile of duplicate records.

defmodule Glossia.Seeds do
  alias Boruta.Ecto.Client, as: BorutaClient

  alias Glossia.Repo

  alias Glossia.Accounts.{
    Account,
    GithubInstallation,
    Glossary,
    Identity,
    AccountToken,
    Project,
    User,
    Voice
  }

  alias Glossia.AccountTokens
  alias Glossia.Ingestion
  alias Glossia.LLMModels
  alias Glossia.TranslationRouting
  alias Glossia.Github.Installations
  alias Glossia.Glossaries
  alias Glossia.LinguisticReviews.Review
  alias Glossia.OAuth.FirstPartyClient
  alias Glossia.Organizations
  alias Glossia.Projects
  alias Glossia.Discussions
  alias Glossia.Discussions.{Discussion, DiscussionComment}
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession
  alias Glossia.Translations.TokenUsage
  alias Glossia.Translations.Context
  alias Glossia.Translations.Locks
  alias Glossia.Voices

  import Ecto.Query

  def run do
    dev =
      ensure_user!(
        handle: "dev",
        email: "dev@glossia.ai",
        name: "Dev User",
        super_admin: true,
        identity: %{provider: "dev", provider_uid: "dev-001"}
      )

    alex =
      ensure_user!(
        handle: "alex",
        email: "alex.chen@glossia.test",
        name: "Alex Chen"
      )

    maria =
      ensure_user!(
        handle: "maria",
        email: "maria.rossi@glossia.test",
        name: "Maria Rossi"
      )

    for {user, languages} <- [
          {dev, ["en", "es"]},
          {alex, ["en", "zh-Hant"]},
          {maria, ["it", "es"]}
        ],
        user.fluent_languages == [] do
      {:ok, _} = Glossia.Accounts.update_user_fluent_languages(user, languages)
    end

    ensure_visibility!(dev.account, "public")

    acme =
      ensure_organization!(
        dev,
        handle: "acme",
        name: "Acme Industries",
        visibility: "public"
      )

    northwind =
      ensure_organization!(
        alex,
        handle: "northwind",
        name: "Northwind Traders",
        visibility: "private"
      )

    omarchy =
      ensure_claimable_organization!(
        handle: "omarchy",
        name: "Omarchy",
        visibility: "public"
      )

    # Membership mix: admin + member + linguist
    ensure_member!(acme, alex, "member")
    ensure_member!(acme, maria, "linguist")
    ensure_member!(northwind, dev, "member")

    # A separate, non-login fixture demonstrates enrollment in Members without
    # changing the developer's test login or enforcing policy on seed accounts.
    mfa_demo = ensure_user!(handle: "mfa-demo", email: "mfa-demo@glossia.test", name: "MFA Demo")
    ensure_member!(acme, mfa_demo, "member")

    unless Glossia.Accounts.MFA.enabled?(mfa_demo) do
      {"session", token} = Glossia.Accounts.MFA.sign_in(mfa_demo)
      {:ok, factor} = Glossia.Accounts.MFA.begin_enrollment(mfa_demo, token)

      {:ok, _codes, verified} =
        Glossia.Accounts.MFA.confirm(mfa_demo, token, NimbleTOTP.verification_code(factor.secret))

      Glossia.Accounts.MFA.revoke(verified)
    end

    {:ok, _} =
      Glossia.MemberPermissions.update(
        acme,
        dev,
        maria,
        Glossia.MemberPermissions.basic_scopes() ++
          ~w(translation:write glossary:write discussion:write)
      )

    # Enterprise adds a pending Workspace domain. Normal seed mutations also
    # populate its audit log without synthesizing historical account changes.
    if authentication = Glossia.Extensions.organization_authentication() do
      if is_nil(acme.auth_provider) and is_nil(acme.auth_domain) do
        {:ok, _} =
          authentication.save(acme, dev, %{
            "auth_provider" => "google",
            "auth_domain" => "acme.test"
          })
      end

      authentication.seed_provisioning(acme, dev)
      authentication.seed_custom_provider(northwind, alex)
    end

    # Pending invitations for testing the acceptance flow.
    ensure_invitation!(acme, dev, email: "prospect@acme.test", role: "member")
    ensure_invitation!(northwind, alex, email: "vendor@northwind.test", role: "member")

    # Personal projects (dev is intentionally public for the guest experience).
    ensure_project!(dev.account, "marketing-site", "Marketing site")
    ensure_project!(dev.account, "docs", "Documentation")
    ensure_project!(dev.account, "cli", "CLI")

    # Organization projects.
    ensure_project!(acme.account, "platform", "Platform")
    ensure_project!(acme.account, "mobile", "Mobile app")
    ensure_project!(northwind.account, "catalog", "Product catalog")
    ensure_project!(omarchy.account, "omarchy", "Omarchy distribution")

    # GitHub installations
    dev_gh =
      ensure_github_installation!(dev.account,
        github_installation_id: 12_345_678,
        github_account_login: "dev-user",
        github_account_type: "User",
        github_account_id: 98_765_432
      )

    acme_gh =
      ensure_github_installation!(acme.account,
        github_installation_id: 87_654_321,
        github_account_login: "acme-industries",
        github_account_type: "Organization",
        github_account_id: 11_223_344
      )

    # GitHub-linked projects
    ensure_github_project!(dev.account, dev_gh, "blog",
      name: "Blog",
      github_repo_id: 100_001,
      github_repo_full_name: "dev-user/blog",
      github_repo_default_branch: "main",
      setup_status: "completed",
      setup_target_languages: ["es", "fr"]
    )

    ensure_github_project!(dev.account, dev_gh, "landing-page",
      name: "Landing page",
      github_repo_id: 100_002,
      github_repo_full_name: "dev-user/landing-page",
      github_repo_default_branch: "main",
      setup_status: "completed",
      setup_target_languages: ["de", "ja", "pt-BR"]
    )

    # Setup automation has finished, but the repository change still needs to
    # be merged. This uses a real pull request so the development notice has a
    # useful destination when its action is opened.
    ensure_github_project!(dev.account, dev_gh, "glossia",
      name: "Glossia",
      github_repo_id: 1_124_240_014,
      github_repo_full_name: "glossia/glossia",
      github_repo_default_branch: "main",
      setup_status: "completed",
      setup_target_languages: ["es", "fr", "de", "ja", "zh-Hans", "ko", "pt-BR"],
      setup_pull_request_number: 92,
      setup_pull_request_url: "https://github.com/glossia/glossia/pull/92",
      setup_pull_request_state: "open"
    )

    ensure_github_project!(acme.account, acme_gh, "acme-docs",
      name: "Acme docs",
      github_repo_id: 200_001,
      github_repo_full_name: "acme-industries/docs",
      github_repo_default_branch: "main",
      setup_status: "completed",
      setup_target_languages: ["es", "fr", "de"]
    )

    # Exercise branded social images when a local object store is configured.
    ensure_project_logo!(dev.account, "glossia")

    blog_project = Projects.get_project(dev.account, "blog")

    # Analytics domain for the "blog" project, used to dogfood the @glossia/web
    # SDK on the dev site (see :web_analytics in config/dev.exs). We mark it
    # verified so the analytics page lights up in development without having
    # to run the DNS / meta-tag dance against a fake domain.
    if blog_project, do: ensure_analytics_settings!(blog_project, domain: "localhost")
    if blog_project, do: ensure_analytics_events!(blog_project)

    # Translation sessions for the "blog" project to exercise the activity timeline
    if blog_project, do: ensure_translation_sessions!(blog_project, dev)

    # Private companion history, intentionally unanswered rather than pretending
    # that seed data came from a model. No inference jobs run from the seeds.
    if blog_project do
      ensure_toki_conversation!(
        blog_project,
        dev,
        "Which blog translations should I review first?"
      )

      ensure_toki_conversation!(blog_project, alex, "How can I prioritize the next blog locale?")

      source = Repo.get_by(TranslationSession, project_id: blog_project.id, commit_sha: "a1b2c3d")

      if source do
        ensure_toki_conversation!(
          blog_project,
          dev,
          "Explain the Spanish and French run from its session summary.",
          source.id
        )
      end
    end

    # A local git remote that stands in for the blog project's GitHub repo, so the
    # full clone → translate → PR flow can run end-to-end locally (dev only).
    seed_local_remote!("dev-user/blog",
      files:
        [
          {"L10N.md",
           """
           ---
           source_language: en
           model: local-codex
           targets:
             es: Spanish
             fr: French
           sources:
             "docs/*.md": "docs/i18n/{locale}/*.md"
             "content/en/*": "content/{locale}/*"
           ---
           Blog project context: keep a friendly, concise tone.
           """},
          {"L10N/fr.md",
           """
           ---
           locale: fr
           model: local-claude
           ---
           French translations should feel natural and editorial, rather than literal.
           """},
          {"docs/getting-started.md",
           "# Getting started\n\nWelcome to the blog. This short guide helps you publish your first post.\n"}
        ] ++ editor_sample_files()
    )

    if blog_project, do: seed_editor!(blog_project)

    seed_local_remote!("dev-user/localization-demo",
      files: [
        {"README.md",
         "# Localization demo\n\nA small repository for exercising project setup.\n"},
        {"content/welcome.md",
         "# Welcome\n\nGlossia helps product teams publish consistent content in every language.\n"}
      ]
    )

    seed_local_remote!("dev-user/sandbox-smoke",
      files: [
        {"README.md",
         "# Sandbox smoke test\n\nA disposable repository for automated setup checks.\n"},
        {"docs/guide.md", "# Guide\n\nUse this guide to verify isolated localization setup.\n"}
      ]
    )

    # Voice configs: create a couple of versions to exercise history and diff UX.
    ensure_voice_versions!(
      dev.account,
      dev,
      [
        %{
          tone: "casual",
          formality: "neutral",
          target_audience: "Developers evaluating Glossia",
          guidelines: """
          ## Style

          - Write in short, concrete sentences.
          - Prefer active voice.
          - Use American English.

          ## Product language

          - Use \"projects\" for repos and apps.
          - Use \"voice\" for brand guidelines.
          """
        },
        %{
          tone: "authoritative",
          formality: "formal",
          target_audience: "Engineering leaders and localization managers",
          description:
            "Glossia is a platform that helps teams manage multilingual content with AI-powered translation and voice consistency.",
          target_countries: ["US", "DE", "JP", "ES"],
          cultural_notes: %{
            "US" =>
              "American audiences value directness and clarity. Use active voice, short sentences, and concrete examples.",
            "DE" =>
              "German audiences expect precision and thoroughness. Be formal but not stiff, and provide detailed explanations.",
            "JP" =>
              "Japanese communication style values politeness and indirectness. Avoid overly casual language and respect hierarchy.",
            "ES" =>
              "Spanish-speaking audiences appreciate warmth and personal connection. Use inclusive language and a friendly tone."
          },
          guidelines: """
          ## Style

          - Be precise and unambiguous.
          - Avoid hype and filler.
          - Prefer glossary that maps to UI labels.

          ## Formatting

          - Use code fences for commands.
          - Use tables for structured reference data.
          """
        }
      ]
    )

    ensure_voice_versions!(
      acme.account,
      dev,
      [
        %{
          tone: "authoritative",
          formality: "formal",
          target_audience: "Enterprise customers and partner engineers",
          guidelines: """
          ## Voice

          - Confident, direct, and calm.
          - Avoid slang and sarcasm.
          - Use plain language over legalese.

          ## Glossary

          - Prefer \"organization\" over \"org\" in user-facing text.
          - Prefer \"members\" for access control.
          """,
          overrides: [
            %{
              locale: "es-MX",
              tone: "authoritative",
              formality: "formal",
              guidelines: "Usa un tono formal y directo. Evita anglicismos innecesarios."
            }
          ]
        }
      ]
    )

    # Glossary: seed entries with per-language translations.
    ensure_glossary_versions!(
      dev.account,
      dev,
      [
        %{
          entries: [
            %{
              term: "project",
              definition: "A repository or application tracked by Glossia.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "proyecto"},
                %{locale: "ja", translation: "\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8"},
                %{locale: "de", translation: "Projekt"}
              ]
            },
            %{
              term: "voice",
              definition: "The brand tone and writing guidelines for content generation.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "voz"},
                %{locale: "ja", translation: "\u30DC\u30A4\u30B9"},
                %{locale: "de", translation: "Stimme"}
              ]
            },
            %{
              term: "glossary",
              definition: "A curated list of terms with approved translations per language.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "terminologia"},
                %{locale: "ja", translation: "\u7528\u8A9E"},
                %{locale: "de", translation: "Terminologie"}
              ]
            },
            %{
              term: "API",
              definition: "Application Programming Interface. Always uppercase.",
              case_sensitive: true,
              translations: [
                %{locale: "es", translation: "API"},
                %{locale: "ja", translation: "API"},
                %{locale: "de", translation: "API"}
              ]
            }
          ],
          change_note: "Initial glossary"
        },
        %{
          entries: [
            %{
              term: "project",
              definition: "A repository or application tracked by Glossia.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "proyecto"},
                %{locale: "ja", translation: "\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8"},
                %{locale: "de", translation: "Projekt"},
                %{locale: "fr", translation: "projet"}
              ]
            },
            %{
              term: "voice",
              definition: "The brand tone and writing guidelines for content generation.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "voz"},
                %{locale: "ja", translation: "\u30DC\u30A4\u30B9"},
                %{locale: "de", translation: "Stimme"},
                %{locale: "fr", translation: "voix"}
              ]
            },
            %{
              term: "glossary",
              definition: "A curated list of terms with approved translations per language.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "terminologia"},
                %{locale: "ja", translation: "\u7528\u8A9E"},
                %{locale: "de", translation: "Terminologie"},
                %{locale: "fr", translation: "terminologie"}
              ]
            },
            %{
              term: "API",
              definition: "Application Programming Interface. Always uppercase.",
              case_sensitive: true,
              translations: [
                %{locale: "es", translation: "API"},
                %{locale: "ja", translation: "API"},
                %{locale: "de", translation: "API"},
                %{locale: "fr", translation: "API"}
              ]
            },
            %{
              term: "account",
              definition: "A user or organization identity in Glossia.",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "cuenta"},
                %{locale: "ja", translation: "\u30A2\u30AB\u30A6\u30F3\u30C8"},
                %{locale: "de", translation: "Konto"},
                %{locale: "fr", translation: "compte"}
              ]
            }
          ],
          change_note: "Add French translations and account term"
        }
      ]
    )

    ensure_glossary_versions!(
      acme.account,
      dev,
      [
        %{
          entries: [
            %{
              term: "platform",
              definition: "The Acme Industries cloud platform product.",
              case_sensitive: false,
              translations: [
                %{locale: "es-MX", translation: "plataforma"},
                %{locale: "pt-BR", translation: "plataforma"}
              ]
            },
            %{
              term: "workspace",
              definition: "A logical container for projects within the platform.",
              case_sensitive: false,
              translations: [
                %{locale: "es-MX", translation: "espacio de trabajo"},
                %{locale: "pt-BR", translation: "espa\u00E7o de trabalho"}
              ]
            }
          ],
          change_note: "Initial org glossary"
        }
      ]
    )

    # ── API tokens ──
    ensure_account_token!(dev.account, dev,
      name: "CI Pipeline Token",
      description: "Used by GitHub Actions to push translations",
      scope: "voice:read voice:write glossary:read glossary:write"
    )

    # ── First-party mobile OAuth client ──
    ensure_first_party_mobile_client!()

    # ── Tickets ──
    ticket1 =
      ensure_discussion!(dev.account, dev,
        title: "Voice settings not saving",
        body:
          "When I change the tone to 'playful' and click save, the page reloads but the tone reverts to 'casual'. Tried in Chrome and Firefox.",
        status: "open"
      )

    ensure_discussion_comment!(ticket1, dev,
      body: "I can reproduce this every time. Attaching a screen recording would help."
    )

    ensure_discussion_comment!(ticket1, dev,
      body: "Thanks! I recorded it. The save button shows a spinner but the value snaps back."
    )

    _ticket2 =
      ensure_discussion!(alex.account, alex,
        title: "Add support for Portuguese (Brazil) glossary",
        body:
          "We need pt-BR as a supported language in the glossary section. Right now only pt-PT is available.",
        status: "open"
      )

    _voice_request =
      ensure_discussion!(acme.account, maria,
        title: "Voice suggestion: Simplify launch messaging",
        body:
          "Please review this proposed voice update to simplify launch messaging for external contributors.",
        status: "open",
        kind: "voice_suggestion",
        metadata: %{
          "resource" => "voice",
          "base_version" => 1,
          "payload" => %{
            "tone" => "authoritative",
            "formality" => "neutral",
            "target_audience" => "Enterprise users evaluating the launch docs",
            "guidelines" =>
              "Use shorter sentences, preserve technical precision, and avoid internal jargon.",
            "target_countries" => ["US", "MX"],
            "cultural_notes" => %{
              "US" => "Lead with outcomes and direct language.",
              "MX" => "Prefer clear, respectful language and explicit next steps."
            },
            "overrides" => [
              %{
                "locale" => "es-MX",
                "tone" => "authoritative",
                "formality" => "formal",
                "guidelines" => "Evita frases largas y mantiene terminologia consistente."
              }
            ]
          }
        }
      )

    _glossary_request =
      ensure_discussion!(acme.account, maria,
        title: "Glossary suggestion: Add billing terms",
        body:
          "Proposed glossary update with billing glossary for support and onboarding content.",
        status: "open",
        kind: "glossary_suggestion",
        metadata: %{
          "resource" => "glossary",
          "change_note" => "Add billing and invoice glossary",
          "base_version" => 1,
          "payload" => %{
            "entries" => [
              %{
                "term" => "invoice",
                "definition" => "A billing document sent to customers.",
                "case_sensitive" => false,
                "translations" => [
                  %{"locale" => "es-MX", "translation" => "factura"},
                  %{"locale" => "pt-BR", "translation" => "fatura"}
                ]
              },
              %{
                "term" => "billing cycle",
                "definition" => "Recurring period used for subscription charges.",
                "case_sensitive" => false,
                "translations" => [
                  %{"locale" => "es-MX", "translation" => "ciclo de facturacion"},
                  %{"locale" => "pt-BR", "translation" => "ciclo de cobranca"}
                ]
              }
            ]
          }
        }
      )

    ticket3 =
      ensure_discussion!(dev.account, dev,
        title: "OAuth redirect URI validation too strict",
        body:
          "When I enter http://localhost:3000/callback as a redirect URI it gets rejected. Local development URIs should be allowed.",
        status: "closed"
      )

    ensure_discussion_comment!(ticket3, dev,
      body:
        "We have relaxed the URI validation for localhost addresses. This should work now. Let us know if you still see tickets."
    )

    # LLM model configurations
    ensure_llm_model!(dev.account, dev,
      handle: "claude-sonnet",
      model: "anthropic/claude-sonnet-5",
      api_key: "sk-ant-dev-placeholder-key"
    )

    ensure_llm_model!(dev.account, dev,
      handle: "gpt-4o",
      model: "openai/gpt-4o",
      api_key: "sk-dev-placeholder-key"
    )

    ensure_llm_model!(dev.account, dev,
      handle: "local-codex",
      model: "openai/gpt-5.4",
      api_key: Glossia.Translations.Credentials.development_session_api_key(:codex),
      default: true,
      # Local Codex sessions have no per-model quota — leave the cap
      # unset so a run fans out as wide as the repository plan.
      translation_concurrency: nil
    )

    ensure_llm_model!(dev.account, dev,
      handle: "local-pi",
      model: "openrouter/anthropic/claude-sonnet-4.6",
      api_key: Glossia.Translations.Credentials.development_session_api_key(:pi)
    )

    ensure_llm_model!(dev.account, dev,
      handle: "local-claude",
      model: "anthropic/claude-sonnet-5",
      api_key: Glossia.Translations.Credentials.development_session_api_key(:claude),
      default: false
    )

    ensure_llm_model!(dev.account, dev,
      handle: "fast-drafts",
      model: "fireworks_ai/accounts/fireworks/models/glm-4p5-air",
      api_key: "fw-dev-placeholder-key",
      default: false,
      # Fireworks' serverless models rate-limit around a handful of
      # concurrent requests per model. Cap the run so a repository plan
      # cannot walk into a wall of 429s the moment it fans out.
      translation_concurrency: 5
    )

    ensure_llm_model!(dev.account, dev,
      handle: "long-form-guides",
      model: "fireworks_ai/accounts/fireworks/models/kimi-k2p5",
      api_key: "fw-dev-placeholder-key",
      default: false,
      # Larger reasoning models are typically metered more tightly by the
      # provider than the smaller drafts model above — a lower cap gives
      # every planned locale a fair chance to progress.
      translation_concurrency: 3
    )

    ensure_llm_model!(acme.account, dev,
      handle: "acme-claude",
      model: "anthropic/claude-sonnet-5",
      api_key: "sk-ant-acme-placeholder-key",
      default: true
    )

    ensure_llm_model!(acme.account, dev,
      handle: "acme-fast-drafts",
      model: "fireworks_ai/accounts/fireworks/models/glm-4p5-air",
      api_key: "fw-acme-placeholder-key",
      default: false
    )

    # A separate demo account keeps placeholder evaluation credentials out of
    # the default developer's translation runs.
    quality_demo =
      ensure_user!(
        handle: "quality-demo",
        email: "quality-demo@glossia.ai",
        name: "Translation Quality Demo",
        identity: %{provider: "dev", provider_uid: "quality-demo-001"}
      )

    ensure_llm_model!(quality_demo.account, quality_demo,
      handle: "translator",
      model: "anthropic/claude-sonnet-5",
      api_key: "sk-ant-quality-demo-placeholder-key"
    )

    ensure_llm_model!(quality_demo.account, quality_demo,
      handle: "translation-quality",
      category: "decision",
      model: "typesafe/jev-latest",
      api_key: "quality-demo-placeholder-key",
      decision_min_score: 7.0
    )

    ensure_token_usage!(dev.account, blog_project)
    ensure_token_usage!(dev.account, Projects.get_project(dev.account, "landing-page"))

    # Translation routing rules: pick a model per target locale, first match
    # wins, fallback to the account default when no rule matches.
    reset_routing_rules!(dev.account)

    ensure_routing_rule!(dev.account, dev, "ja", "long-form-guides")
    ensure_routing_rule!(dev.account, dev, "ko", "long-form-guides")
    ensure_routing_rule!(dev.account, dev, "zh-Hans", "long-form-guides")
    ensure_routing_rule!(dev.account, dev, "es", "gpt-4o")
    ensure_routing_rule!(dev.account, dev, nil, "fast-drafts")

    reset_routing_rules!(acme.account)
    ensure_routing_rule!(acme.account, dev, "es", "acme-fast-drafts")

    :ok
  end

  defp ensure_token_usage!(_account, nil), do: :ok

  defp ensure_token_usage!(account, project) do
    for day <- 0..13,
        {locale, factor} <- [{"es", 1}, {"ja", 2}, {"de", 1}],
        {path, size} <- [
          {"content/getting-started.md", 1800},
          {"content/translation-workflows.md", 4200}
        ] do
      date = Date.add(Date.utc_today(), -day)

      id =
        :crypto.hash(
          :sha256,
          "token-usage-seed:#{account.id}:#{project.id}:#{date}:#{locale}:#{path}"
        )
        |> binary_part(0, 16)
        |> Ecto.UUID.load!()

      Repo.insert_all(
        TokenUsage,
        [
          %{
            id: id,
            account_id: account.id,
            project_id: project.id,
            model: "openai/gpt-4o",
            model_handle: "gpt-4o",
            locale: locale,
            source_path: path,
            input_tokens: size + day * 30,
            output_tokens: div(size * factor, 2),
            cached_tokens: div(size, 4),
            inserted_at: DateTime.new!(date, ~T[12:00:00.000000], "Etc/UTC")
          }
        ],
        on_conflict: :nothing,
        conflict_target: [:id]
      )
    end
  end

  # ----------------------------------------------------------------------------
  # Users
  # ----------------------------------------------------------------------------

  defp ensure_user!(opts) do
    handle = Keyword.fetch!(opts, :handle)
    email = Keyword.fetch!(opts, :email)
    name = Keyword.get(opts, :name)
    super_admin = Keyword.get(opts, :super_admin, false)

    account =
      case Repo.get_by(Account, handle: handle) do
        nil ->
          Repo.insert!(%Account{handle: handle})

        %Account{} = account ->
          case Repo.get_by(User, account_id: account.id) do
            %User{} -> account
            nil -> raise "Organization handle '#{handle}' is already taken"
          end
      end

    user =
      case Repo.get_by(User, account_id: account.id) do
        nil ->
          Repo.insert!(%User{
            account_id: account.id,
            email: email,
            name: name,
            super_admin: super_admin
          })

        %User{} = user ->
          user
      end

    user =
      if user.email != email or user.name != name or user.super_admin != super_admin do
        {:ok, user} =
          user
          |> User.changeset(%{email: email, name: name})
          |> Ecto.Changeset.change(super_admin: super_admin)
          |> Repo.update()

        user
      else
        user
      end

    maybe_ensure_identity!(user, Keyword.get(opts, :identity))

    user = %{user | account: account}
    Glossia.Accounts.ensure_personal_organization!(user)
    {:ok, _} = Glossia.Accounts.set_super_admin(user.id, super_admin)

    user
  end

  defp maybe_ensure_identity!(_user, nil), do: :ok

  defp maybe_ensure_identity!(%User{} = user, %{provider: provider, provider_uid: provider_uid}) do
    case Repo.get_by(Identity, provider: provider, provider_uid: provider_uid) do
      nil ->
        Repo.insert!(%Identity{
          user_id: user.id,
          provider: provider,
          provider_uid: provider_uid
        })

      %Identity{} ->
        :ok
    end
  end

  # ----------------------------------------------------------------------------
  # Organizations
  # ----------------------------------------------------------------------------

  defp ensure_organization!(%User{} = admin, opts) do
    handle = Keyword.fetch!(opts, :handle)
    name = Keyword.fetch!(opts, :name)
    visibility = Keyword.get(opts, :visibility, "private")

    account = Repo.get_by(Account, handle: handle)

    org =
      case account do
        nil ->
          {:ok, %{organization: org}} =
            Organizations.create_organization(admin, %{
              handle: handle,
              name: name
            })

          org

        %Account{} = account ->
          case Repo.get_by(User, account_id: account.id) do
            nil -> Organizations.get_organization_for_account(account)
            %User{} -> raise "Organization handle '#{handle}' is already taken"
          end
      end

    {:ok, org} = Organizations.update_organization(org, %{visibility: visibility, name: name})
    org
  end

  defp ensure_claimable_organization!(opts) do
    handle = Keyword.fetch!(opts, :handle)
    name = Keyword.fetch!(opts, :name)
    visibility = Keyword.get(opts, :visibility, "public")

    account = Repo.get_by(Account, handle: handle)

    org =
      case account do
        nil ->
          {:ok, %{organization: org}} =
            Organizations.create_claimable_organization(%{
              handle: handle,
              name: name,
              visibility: visibility
            })

          org

        %Account{} = account ->
          case Repo.get_by(User, account_id: account.id) do
            nil -> Organizations.get_organization_for_account(account)
            %User{} -> raise "Organization handle '#{handle}' is already taken"
          end
      end

    {:ok, org} = Organizations.update_organization(org, %{visibility: visibility, name: name})
    Repo.preload(org, :account)
  end

  defp ensure_member!(org, %User{} = user, role) do
    case Organizations.get_membership(org, user) do
      nil ->
        {:ok, _} = Organizations.add_member(org, user, role)

      _ ->
        :ok
    end
  end

  defp ensure_invitation!(org, %User{} = invited_by, opts) do
    email = Keyword.fetch!(opts, :email)
    role = Keyword.get(opts, :role, "member")

    case Organizations.create_invitation(org, invited_by, %{"email" => email, "role" => role}) do
      {:ok, _invitation} -> :ok
      {:error, :already_invited} -> :ok
      {:error, :already_member} -> :ok
      {:error, _} -> :ok
    end
  end

  # ----------------------------------------------------------------------------
  # Projects
  # ----------------------------------------------------------------------------

  def editor_sample_files do
    [
      {"content/en/home.json",
       Jason.encode!(
         %{
           "hero" => %{
             "title" => "A world of stories, in every language",
             "description" =>
               "Bring your ideas to new audiences without losing what makes them yours.",
             "action" => "Explore the stories"
           },
           "featured_count" => 3,
           "published" => true
         },
         pretty: true
       ) <> "\n"},
      {"content/es/home.json",
       Jason.encode!(
         %{
           "hero" => %{
             "title" => "Un mundo de historias, en cada idioma",
             "description" =>
               "Comparte tus ideas con nuevas audiencias sin perder lo que las hace tuyas.",
             "action" => "Explora las historias"
           },
           "featured_count" => 3,
           "published" => true
         },
         pretty: true
       ) <> "\n"},
      {"content/en/navigation.yaml",
       "# Website navigation\nmenu:\n  stories: Stories\n  about: About us\n  newsletter: Join the newsletter\nshow_search: true\n"},
      {"content/es/navigation.yaml",
       "# Website navigation\nmenu:\n  stories: Historias\n  about: Sobre nosotros\n  newsletter: Suscríbete al boletín\nshow_search: true\n"},
      {"content/en/welcome.md",
       "---\ntitle: A place for good stories\npublished: true\n---\n# A place for good stories\n\nEvery story starts with an idea worth sharing. This is where we collect ours.\n\n## Find your next read\n\n- Discover stories from our community\n- Meet the people behind the words\n- Share something that inspires you\n\n**Make yourself at home.** There is always another story to discover.\n"},
      {"content/es/welcome.md",
       "---\ntitle: Un lugar para las buenas historias\npublished: true\n---\n# Un lugar para las buenas historias\n\nCada historia comienza con una idea que merece compartirse. Aquí reunimos las nuestras.\n\n## Encuentra tu próxima lectura\n\n- Descubre historias de nuestra comunidad\n- Conoce a las personas detrás de las palabras\n- Comparte algo que te inspire\n\n**Siéntete como en casa.** Siempre hay otra historia por descubrir.\n"}
    ]
  end

  def seed_editor!(project) do
    for {path, content} <- editor_sample_files() do
      ["content", locale, name] = Path.split(path)
      source_path = Path.join(["content", "en", name])

      sha =
        Base.encode16(:crypto.hash(:sha, "blob #{byte_size(content)}\0#{content}"), case: :lower)

      %Glossia.Editor.File{
        project_id: project.id,
        path: path,
        source_path: source_path,
        locale: locale,
        format: Glossia.Translations.Format.detect(path),
        content: content,
        blob_sha: sha
      }
      |> Repo.insert!(on_conflict: :nothing, conflict_target: [:project_id, :path])
    end
  end

  # Seeds a local git repository under the configured `local_remotes_dir` to stand
  # in for a GitHub remote, so `Glossia.Translations.RepositoryRun` clones it
  # locally. No-op when `local_remotes_dir` is not configured (e.g. production).
  defp seed_local_remote!(full_name, opts) do
    case Application.get_env(:glossia, Glossia.Translations, [])[:local_remotes_dir] do
      dir when is_binary(dir) and dir != "" ->
        path = Path.join(Path.expand(dir), full_name)
        File.rm_rf!(path)
        File.mkdir_p!(path)

        git = fn args ->
          {_out, 0} = MuonTrap.cmd("git", ["-C", path | args], stderr_to_stdout: true, into: "")
        end

        git.(["init", "-q", "-b", Keyword.get(opts, :branch, "main")])
        git.(["config", "user.email", "seeds@glossia.dev"])
        git.(["config", "user.name", "Glossia Seeds"])

        for {relative, content} <- Keyword.fetch!(opts, :files) do
          target = Path.join(path, relative)
          File.mkdir_p!(Path.dirname(target))
          File.write!(target, content)
        end

        git.(["add", "."])
        git.(["commit", "-q", "-m", "Seed content"])
        IO.puts("  Seeded local remote #{full_name} at #{path}")

      _ ->
        :ok
    end
  end

  defp ensure_project!(%Account{} = account, handle, name) do
    case Projects.get_project(account, handle) do
      nil ->
        {:ok, _project} = Projects.create_project(account, %{handle: handle, name: name})
        :ok

      %Project{} = project ->
        if project.name != name do
          {:ok, _} =
            project
            |> Project.changeset(%{name: name})
            |> Repo.update()
        end

        :ok
    end
  end

  defp ensure_project_logo!(account, handle) do
    project = Projects.get_project(account, handle)
    bucket = Application.get_env(:glossia, Glossia.Storage, [])[:bucket]

    if project && is_nil(project.avatar_url) && is_binary(bucket) do
      key = "avatars/#{account.handle}/projects/#{handle}.png"
      bytes = File.read!(Path.join(:code.priv_dir(:glossia), "static/images/logo-rounded.png"))

      try do
        case Glossia.Storage.upload(key, bytes, content_type: "image/png") do
          {:ok, _} -> Projects.update_project(project, %{avatar_url: key})
          {:error, _} -> IO.puts("Skipping seed project logo: object storage is unavailable.")
        end
      rescue
        _ -> IO.puts("Skipping seed project logo: object storage is unavailable.")
      catch
        _, _ -> IO.puts("Skipping seed project logo: object storage is unavailable.")
      end
    end
  end

  defp ensure_toki_conversation!(%Project{} = project, %User{} = user, content, origin_id \\ nil) do
    title = String.slice(content, 0, 80)

    conversation =
      Repo.get_by(Glossia.Toki.Conversation,
        user_id: user.id,
        project_id: project.id,
        title: title
      ) ||
        Repo.insert!(%Glossia.Toki.Conversation{
          user_id: user.id,
          project_id: project.id,
          translation_session_id: origin_id,
          title: title,
          status: "failed",
          error: "provider_unavailable"
        })

    unless Repo.exists?(
             from m in Glossia.Toki.Message, where: m.conversation_id == ^conversation.id
           ) do
      Repo.insert!(%Glossia.Toki.Message{
        conversation_id: conversation.id,
        user_id: user.id,
        role: "user",
        content: content,
        status: "failed"
      })
    end
  end

  defp ensure_analytics_settings!(%Project{} = project, opts) do
    domain = Keyword.fetch!(opts, :domain)

    {:ok, _settings} =
      Glossia.Analytics.Settings.upsert_for_project(project.id, %{
        domain: domain,
        enabled: true
      })

    # Mark the row verified so the dashboard's analytics view is live in
    # development without forcing the operator to run a real DNS / meta-tag
    # check against `localhost`. The verification module is still available
    # for the real flow on non-localhost domains.
    verified_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    settings =
      Glossia.Analytics.ProjectSettings
      |> Repo.get_by!(project_id: project.id)
      |> Ecto.Changeset.change(%{verified_at: verified_at})
      |> Repo.update!()

    Glossia.Analytics.SettingsCache.delete(settings.domain)
    :ok
  end

  defp ensure_analytics_events!(%Project{} = project) do
    existing =
      from(e in "analytics_events",
        where: e.project_id == ^to_string(project.id),
        select: count(e.id)
      )
      |> Glossia.IngestRepo.one!()

    if existing > 0 do
      :ok
    else
      seed_analytics_events!(project)
    end
  end

  # Builds ~14 days of plausible traffic for the dev analytics dashboard.
  # The numbers are hand-picked to exercise every section of the page:
  #
  #   * several distinct countries (so the priority map lights up)
  #   * both served and unserved browser languages (so the gap list works)
  #   * repeat visitors (so the uniqExact aggregate is not 1:1 with events)
  #   * a handful of custom events (so `name != "pageview"` is exercised)
  #   * a referrer (so the referrer breakdown shows something)
  #   * explicit language choices kept separate from browser preferences
  defp seed_analytics_events!(%Project{} = project) do
    project_id_str = to_string(project.id)
    target_languages = project.setup_target_languages || []
    now = DateTime.utc_now()

    # [country, browser_language, served_locale (or ""), has_gap, count, days_ago, hour_offset]
    visitors = [
      ["US", "en", "en", 0, 42, 0, 0],
      ["US", "en", "en", 0, 28, 1, 2],
      ["US", "en", "en", 0, 35, 2, 1],
      ["US", "en", "en", 0, 19, 4, 0],
      ["US", "en", "en", 0, 31, 7, 3],
      ["US", "en", "en", 0, 26, 10, 2],
      ["GB", "en", "en", 0, 18, 0, 1],
      ["GB", "en", "en", 0, 12, 3, 0],
      ["GB", "en", "en", 0, 9, 8, 2],
      ["DE", "de", "", 1, 22, 0, 0],
      ["DE", "de", "", 1, 17, 1, 2],
      ["DE", "de", "", 1, 14, 5, 1],
      ["DE", "de", "", 1, 11, 9, 0],
      ["FR", "fr", "", 1, 19, 0, 3],
      ["FR", "fr", "", 1, 15, 2, 1],
      ["FR", "fr", "", 1, 12, 6, 0],
      ["FR", "fr", "", 1, 8, 12, 2],
      ["ES", "es", "", 1, 14, 1, 1],
      ["ES", "es", "", 1, 10, 4, 0],
      ["ES", "es", "", 1, 7, 8, 3],
      ["BR", "pt-br", "", 1, 16, 0, 0],
      ["BR", "pt-br", "", 1, 12, 2, 2],
      ["BR", "pt-br", "", 1, 9, 5, 1],
      ["BR", "pt-br", "", 1, 6, 11, 0],
      ["JP", "ja", "", 1, 13, 0, 1],
      ["JP", "ja", "", 1, 8, 3, 0],
      ["JP", "ja", "", 1, 5, 9, 2],
      ["CN", "zh", "", 1, 11, 1, 1],
      ["CN", "zh", "", 1, 7, 6, 0],
      ["KR", "ko", "", 1, 6, 2, 2],
      ["KR", "ko", "", 1, 4, 8, 0],
      ["MX", "es", "", 1, 9, 0, 0],
      ["MX", "es", "", 1, 6, 4, 1],
      ["MX", "es", "", 1, 4, 10, 0],
      ["AR", "es", "", 1, 5, 3, 1],
      ["AR", "es", "", 1, 3, 9, 0],
      ["NL", "en", "en", 0, 7, 0, 1],
      ["NL", "nl", "en", 1, 3, 5, 0],
      ["SE", "en", "en", 0, 5, 1, 0],
      ["SE", "sv", "en", 1, 2, 7, 1],
      ["PL", "pl", "", 1, 4, 2, 0],
      ["PL", "pl", "", 1, 3, 8, 1],
      ["TR", "tr", "", 1, 4, 1, 0],
      ["TR", "tr", "", 1, 2, 6, 1],
      ["IN", "hi", "", 1, 5, 0, 0],
      ["IN", "en", "en", 0, 3, 4, 1],
      ["ID", "id", "", 1, 3, 3, 0],
      ["VN", "vi", "", 1, 3, 5, 1],
      ["TH", "th", "", 1, 2, 7, 0],
      ["RU", "ru", "", 1, 4, 1, 1],
      ["RU", "ru", "", 1, 2, 9, 0],
      ["ZA", "en", "en", 0, 3, 2, 0],
      ["NG", "en", "en", 0, 2, 6, 1],
      ["AU", "en", "en", 0, 4, 0, 0],
      ["NZ", "en", "en", 0, 2, 4, 1]
    ]

    paths = [
      "/",
      "/blog/getting-started-with-glossia",
      "/blog/getting-started-with-glossia",
      "/docs",
      "/docs/quickstart",
      "/pricing",
      "/blog/advanced-localization",
      "/",
      "/blog"
    ]

    devices = ["desktop", "mobile", "tablet", "desktop", "desktop", "mobile"]
    browsers = ["chrome", "safari", "firefox", "edge", "chrome", "chrome"]
    oses = ["macos", "ios", "windows", "android", "linux", "macos"]

    timezones = [
      "America/New_York",
      "Europe/London",
      "Europe/Berlin",
      "Asia/Tokyo",
      "America/Sao_Paulo"
    ]

    referrers = [
      {"https://google.com/search", "google.com"},
      {"https://twitter.com/", "twitter.com"},
      {"", ""},
      {"", ""},
      {"https://github.com/glossia", "github.com"}
    ]

    rows =
      for [country, browser_lang, served_locale, has_gap, count, days_ago, hour_offset] <-
            visitors,
          _ <- 1..count do
        ua = "Mozilla/5.0 (SeedBrowser/1.0) #{country}-#{days_ago}"
        session_id = "seed-sess-#{country}-#{:rand.uniform(1000)}"
        screen_width = Enum.random([1280, 1440, 1920, 390, 414, 768])
        device = Enum.random(devices)
        browser = Enum.random(browsers)
        os = Enum.random(oses)
        timezone = Enum.random(timezones)
        {ref, ref_source} = Enum.random(referrers)
        path = Enum.random(paths)
        # Some visitors explicitly chose English despite a different browser
        # preference. Most visits have no observed choice, not an inferred one.
        selected_locale = if browser_lang in ["nl", "sv"], do: served_locale, else: ""

        name =
          cond do
            selected_locale != "" and :rand.uniform(5) == 1 -> "language_selection"
            :rand.uniform(20) == 1 -> "signup"
            true -> "pageview"
          end

        # Scatter timestamps across the last 14 days.
        seconds_ago =
          days_ago * 86_400 +
            hour_offset * 3_600 +
            :rand.uniform(3_500)

        inserted_at =
          now
          |> DateTime.add(-seconds_ago, :second)
          |> DateTime.truncate(:second)

        # Use a stable visitor id per country so repeats are not double-counted
        # by `uniqExact`. A per-country seed gives us ~50 unique visitors,
        # which is enough to make the number meaningful without being
        # unrealistic for a dev dashboard.
        visitor_id =
          :erlang.phash2({project_id_str, country, browser_lang}) |> rem(0xFFFFFFFFFFFFFFFF)

        %{
          id: Uniq.UUID.uuid7(),
          project_id: project_id_str,
          visitor_id: visitor_id,
          session_id: session_id,
          name: name,
          hostname: "localhost",
          pathname: path,
          referrer: ref,
          referrer_source: ref_source,
          country_code: country,
          browser_language: browser_lang,
          served_locale: served_locale,
          selected_locale: selected_locale,
          has_locale_gap: has_gap,
          device: device,
          browser: browser,
          os: os,
          screen_width: screen_width,
          timezone: timezone,
          inserted_at: inserted_at
        }
      end

    # `insert_all` with `returning: false` is the cheapest way to bulk-load
    # ClickHouse from seeds. The `inserted_at` column is populated by the
    # table default if omitted, but we set it explicitly so the hourly
    # buckets line up with the last 14 days of activity.
    opts = Glossia.Analytics.Event.buffer_opts()

    # The ClickHouse adapter expects a type for every column in the row, so we
    # add `inserted_at` (which the schema does not declare — it is populated
    # by the table default) to the type list alongside the declared fields.
    types_kw = Enum.zip(opts.fields, opts.types) ++ [inserted_at: :datetime]

    IO.puts("  Seeding #{length(rows)} analytics events for project #{project.handle}")
    {count, _} = Glossia.IngestRepo.insert_all("analytics_events", rows, types: types_kw)
    IO.puts("  Inserted #{count} analytics events")

    _ = target_languages
    :ok
  end

  # ----------------------------------------------------------------------------
  # Voice
  # ----------------------------------------------------------------------------

  defp ensure_voice_versions!(%Account{} = account, %User{} = user, versions)
       when is_list(versions) do
    existing =
      Voice
      |> where(account_id: ^account.id)
      |> Repo.aggregate(:count, :id)

    versions
    |> Enum.drop(existing)
    |> Enum.each(fn attrs ->
      _ = Voices.create_voice(account, attrs, user)
    end)
  end

  # ----------------------------------------------------------------------------
  # Glossary
  # ----------------------------------------------------------------------------

  defp ensure_glossary_versions!(%Account{} = account, %User{} = user, versions)
       when is_list(versions) do
    existing =
      Glossary
      |> where(account_id: ^account.id)
      |> Repo.aggregate(:count, :id)

    versions
    |> Enum.drop(existing)
    |> Enum.each(fn attrs ->
      _ = Glossaries.create_glossary(account, attrs, user)
    end)
  end

  defp ensure_visibility!(%Account{} = account, visibility) do
    if account.visibility == visibility do
      :ok
    else
      {:ok, _} =
        account
        |> Account.changeset(%{visibility: visibility})
        |> Repo.update()

      :ok
    end
  end

  defp ensure_account_token!(account, user, opts) do
    name = Keyword.fetch!(opts, :name)

    existing =
      Repo.one(
        from t in AccountToken,
          where: t.account_id == ^account.id and t.name == ^name and is_nil(t.revoked_at)
      )

    if existing do
      existing
    else
      {:ok, %{token: token}} =
        AccountTokens.create_account_token(account, user, %{
          "name" => name,
          "description" => Keyword.get(opts, :description, ""),
          "scope" => Keyword.get(opts, :scope, ""),
          "expires_at" => DateTime.add(DateTime.utc_now(), 90, :day)
        })

      token
    end
  end

  defp ensure_first_party_mobile_client! do
    client_attrs = FirstPartyClient.mobile_client_attrs()
    client_id = FirstPartyClient.mobile_client_id()

    case Repo.get(BorutaClient, client_id) do
      nil ->
        {:ok, _client} = Boruta.Ecto.Admin.create_client(client_attrs)
        :ok

      %BorutaClient{} = client ->
        {:ok, _client} = Boruta.Ecto.Admin.update_client(client, client_attrs)
        :ok
    end
  end

  # ----------------------------------------------------------------------------
  # Tickets
  # ----------------------------------------------------------------------------

  defp ensure_discussion!(account, user, opts) do
    title = Keyword.fetch!(opts, :title)
    kind = Keyword.get(opts, :kind, "general")
    metadata = Keyword.get(opts, :metadata, %{})

    import Ecto.Query

    existing =
      Repo.one(
        from t in Discussion,
          where: t.account_id == ^account.id and t.title == ^title and t.kind == ^kind
      )

    if existing do
      existing
    else
      {:ok, ticket} =
        Discussions.create_discussion(account, user, %{
          "title" => title,
          "body" => Keyword.fetch!(opts, :body),
          "kind" => kind,
          "metadata" => metadata
        })

      status = Keyword.get(opts, :status, "open")

      if status == "closed" do
        {:ok, ticket} = Discussions.close_discussion(ticket, user)
        ticket
      else
        ticket
      end
    end
  end

  # ----------------------------------------------------------------------------
  # GitHub installations
  # ----------------------------------------------------------------------------

  defp ensure_github_installation!(%Account{} = account, opts) do
    github_installation_id = Keyword.fetch!(opts, :github_installation_id)

    case Installations.get_installation_by_github_id(github_installation_id) do
      nil ->
        {:ok, installation} =
          Installations.create_installation(account, %{
            github_installation_id: github_installation_id,
            github_account_login: Keyword.fetch!(opts, :github_account_login),
            github_account_type: Keyword.fetch!(opts, :github_account_type),
            github_account_id: Keyword.fetch!(opts, :github_account_id)
          })

        installation

      %GithubInstallation{} = installation ->
        installation
    end
  end

  defp ensure_github_project!(
         %Account{} = account,
         %GithubInstallation{} = installation,
         handle,
         opts
       ) do
    attrs =
      opts
      |> Map.new()
      |> Map.put(:handle, handle)

    case Projects.get_project(account, handle) do
      nil ->
        {:ok, _project} = Projects.create_project_from_github(account, installation.id, attrs)

        :ok

      %Project{} = project ->
        {:ok, _project} =
          project
          |> Project.changeset(attrs)
          |> Repo.update()

        :ok
    end
  end

  # ----------------------------------------------------------------------------
  # Translation Sessions
  # ----------------------------------------------------------------------------

  defp ensure_translation_sessions!(%Project{} = project, %User{} = user) do
    existing =
      Repo.one(
        from s in TranslationSession,
          where: s.project_id == ^project.id,
          select: count(s.id)
      )

    if existing == 0, do: seed_translation_sessions!(project, user)

    refresh_seeded_translation_outcomes!(project)
    # A developer whose local database predates the durable progress events
    # keeps the three demo session rows but has no progress rows to fold into
    # the "Translated files" panel. Replay them here, guarded per-session, so
    # the panel populates without needing an ecto reset. `broadcast_session_event`
    # writes with `on_conflict: :nothing` on `(session_id, seq)`, so replay is a
    # no-op when the rows already exist.
    backfill_seeded_translation_progress!(project)
    ensure_translation_dashboard_history!(project, user)
    ensure_translation_pagination_history!(project, user)
    ensure_linguistic_reviews!(project, user)
    ensure_translation_reasons_demo!(project, user)

    # Demo execution provenance is separate from the content SHA. Keep existing
    # local seeds current without overwriting any real recorded engine version.
    demo_image = "ghcr.io/glossia/glossia@sha256:" <> String.duplicate("a", 64)

    from(s in TranslationSession,
      where: s.project_id == ^project.id and not is_nil(s.started_at) and is_nil(s.engine_image)
    )
    |> Repo.update_all(set: [engine_image: demo_image])
  end

  # A separate, explicitly seeded run keeps realistic assessment reasons easy
  # to inspect without fabricating historical reasons for older demo sessions.
  defp ensure_translation_reasons_demo!(project, user) do
    commit_sha = "seed-translation-reasons-v2"
    now = DateTime.utc_now()

    session =
      Repo.get_by(TranslationSession, project_id: project.id, commit_sha: commit_sha) ||
        elem(
          TranslationSessions.create_session(user.account, project, %{
            commit_sha: commit_sha,
            commit_message: "Update onboarding docs, terminology, and validation (demo)",
            status: "completed",
            outcome: "translated",
            translated_content_count: 7,
            content_hit_count: 291,
            source_language: "en",
            target_languages: ["es", "fr", "de", "ja"],
            summary:
              "Demo: translated 7 files after source, glossary, instructions, validation, and output changes. 291 translations were already up to date.",
            started_at: DateTime.add(now, -2400),
            completed_at: DateTime.add(now, -2100)
          }),
          1
        )

    if TranslationSessions.max_progress_seq(session.id) == 0 do
      items = [
        {"content/blog/getting-started.md", "es", :es_getting_started},
        {"content/blog/getting-started.md", "fr", :fr_getting_started},
        {"content/blog/advanced-localization.md", "ja", :ja_advanced},
        {"content/blog/advanced-localization.md", "de", :de_advanced},
        {"content/blog/getting-started-meta.json", "es", :es_meta},
        {"content/blog/repository-setup.md", "es", :es_getting_started},
        {"content/blog/repository-setup.md", "fr", :fr_getting_started}
      ]

      queued =
        items
        |> Enum.with_index()
        |> Enum.map(fn {{source, locale, _preview}, index} ->
          output = Path.join(["content", locale, "blog", Path.basename(source)])

          {lock, current, output_hash} =
            translation_demo_comparison(index, source, locale, output)

          %{
            index: index,
            source_path: source,
            output_path: output,
            locale: locale,
            translation_reasons: Locks.translation_reasons(lock, current, output, output_hash),
            translation_diff: Locks.translation_diff(lock, current, output, output_hash)
          }
        end)

      completed =
        Enum.zip(queued, items)
        |> Enum.flat_map(fn {item, {_, _, preview}} ->
          [
            Map.merge(item, %{type: "item_started", total: 298}),
            %{
              type: "item_completed",
              index: item.index,
              output_preview: seed_translation_preview(preview),
              model_calls: 2
            }
          ]
        end)

      seed_progress_events!(
        session,
        [
          %{type: "run_started"},
          %{type: "plan", total: 298},
          %{
            type: "plan_assessed",
            total: 298,
            needs_translation: 7,
            up_to_date: 291,
            queued: queued
          }
        ] ++ completed
      )
    end
  end

  # Generate evidence through the real lock comparison, never by inventing a
  # rendered diff. Row zero deliberately changes several independent branches.
  defp translation_demo_comparison(index, source, locale, output) do
    voice = %{
      tone: "Calm",
      formality: "Neutral",
      target_audience: "Developers",
      guidelines: "Use concrete examples.",
      description: "Repository-native localization.",
      cultural_notes: %{},
      locale: locale
    }

    glossary = [
      %{
        namespaced_id: "repo:lockfile",
        term: "lockfile",
        translation: "lockfile",
        definition: "Translation baseline",
        case_sensitive: false
      },
      %{
        namespaced_id: "repo:Glossia",
        term: "Glossia",
        translation: "Glossia",
        definition: "Product name",
        case_sensitive: true
      }
    ]

    context = %{Context.empty_bundle(locale) | voice: voice, glossary: glossary}

    documents = [
      %{relative_path: "L10N.md", body: "# Product\nKeep Glossia untranslated.\n"},
      %{
        relative_path: "content/blog/L10N.md",
        body: "# Tone\nUse a friendly tone.\n\n# Formatting\nPreserve code blocks.\n"
      }
    ]

    body = Enum.map_join(documents, "\n\n", & &1.body)

    before = %{
      format: if(Path.extname(source) == ".json", do: "json", else: "markdown"),
      source_path: source,
      source_content:
        "# Getting started\n\nSet up Glossia in five minutes.\n\n## Requirements\n\nA GitHub repository.\n",
      provider: "openai",
      model: "openai/gpt-5-mini",
      source_language: "en",
      language: locale,
      locale: locale,
      frontmatter_mode: :preserve,
      preserve: ["Glossia"],
      custom_prompt: nil,
      context_body: body,
      locale_override_body: "# Terminology\nKeep repository terms consistent.\n",
      context_documents: documents,
      locale_documents: [
        %{
          relative_path: "L10N/#{locale}.md",
          body: "# Terminology\nKeep repository terms consistent.\n"
        }
      ],
      retries: 2,
      check_cmd: nil,
      check_cmds: %{"json" => "jq empty"},
      validation: nil,
      validation_relative_path: "L10N.md",
      server_context: context,
      decision_model: %{
        handle: "reviewer",
        model: "typesafe/jev-latest",
        base_url: nil,
        decision_min_score: 7.0
      }
    }

    current =
      case index do
        0 ->
          %{
            before
            | model: "openai/gpt-5",
              retries: 3,
              source_content:
                String.replace(before.source_content, "five minutes", "three minutes"),
              server_context: %{
                context
                | voice: %{voice | tone: "Direct", target_audience: "Platform engineers"}
              },
              decision_model: %{before.decision_model | decision_min_score: 8.0}
          }

        1 ->
          guidance = "# Terminology\nPrefer dépôt for repository.\n"

          %{
            before
            | source_content:
                before.source_content <>
                  "\n## Next steps\n\nOpen your translation pull request.\n",
              locale_override_body: guidance,
              locale_documents: [%{relative_path: "L10N/#{locale}.md", body: guidance}]
          }

        2 ->
          entries = [
            %{
              hd(glossary)
              | translation: "ロックファイル",
                definition: "Per-source, per-locale translation baseline"
            },
            List.last(glossary)
          ]

          %{before | server_context: %{context | glossary: entries}}

        3 ->
          [root, blog] = documents

          updated = [
            root,
            %{blog | body: String.replace(blog.body, "friendly tone", "concise, direct tone")}
          ]

          %{
            before
            | context_documents: updated,
              context_body: Enum.map_join(updated, "\n\n", & &1.body)
          }

        4 ->
          %{before | check_cmds: %{"json" => "jq -e 'type == \"object\"'"}, retries: 3}

        _ ->
          before
      end

    previous = Locks.build_hash_state(before)

    lock = %{
      "hash" => previous.hash,
      "hash_tree" => previous.tree,
      "output_path" => output,
      "output_hash" => Locks.output_hash("Accepted translated output."),
      "source_commit_sha" => "57f484cf34215985850f4b24b427584a3c434b64"
    }

    lock = if index == 5, do: nil, else: lock

    output_hash =
      case index do
        5 -> ""
        6 -> Locks.output_hash("Externally edited translated output.")
        _ -> Locks.output_hash("Accepted translated output.")
      end

    {lock, Locks.build_hash_state(current), output_hash}
  end

  defp ensure_linguistic_reviews!(project, user) do
    for {sha, status, answer, guidance} <- [
          {"seed-review-open", "open", nil, nil},
          {"seed-review-answered", "answered", "A source-control branch for a release.",
           "Branch means a source-control branch, never a tree limb."}
        ] do
      session =
        Repo.one(
          from s in TranslationSession,
            where:
              s.project_id == ^project.id and s.commit_sha == ^sha and
                is_nil(s.continued_from_session_id)
        ) ||
          elem(
            TranslationSessions.create_session(user.account, project, %{
              status: "awaiting_input",
              commit_sha: sha,
              commit_message: "Clarify release-branch terminology",
              source_language: "en",
              target_languages: ["es"],
              started_at: DateTime.add(DateTime.utc_now(), -900)
            }),
            1
          )

      continuation =
        if status == "answered" do
          Repo.get_by(TranslationSession, continued_from_session_id: session.id) ||
            elem(
              TranslationSessions.create_session(user.account, project, %{
                continued_from_session_id: session.id,
                status: "completed",
                outcome: "translated",
                commit_sha: sha,
                commit_message: "Translate using the linguist's release-branch decision",
                source_language: "en",
                target_languages: ["es"],
                translated_content_count: 1,
                summary:
                  "Translated the release guide and proposed Spanish terminology guidance.",
                completed_at: DateTime.utc_now()
              }),
              1
            )
        end

      review =
        Repo.get_by(Review, translation_session_id: session.id) ||
          Repo.insert!(%Review{
            translation_session_id: session.id,
            source_path: "docs/releases.txt",
            output_path: "es/releases.txt",
            locale: "es",
            fingerprint: Base.encode16(:crypto.hash(:sha256, sha), case: :lower),
            reason: "missing_context",
            question: "Does branch mean a source-control branch or a tree limb?",
            source_excerpt: "Create a branch before launching the release.",
            translation_excerpt: "Crea una rama antes de publicar la versión.",
            status: status,
            answer: answer,
            guidance: guidance,
            answered_by_id: if(answer, do: user.id),
            resumed_session_id: continuation && continuation.id,
            context_path: if(guidance, do: "L10N/es.md"),
            context_targets: %{"locale" => %{"path" => "L10N/es.md", "digest" => nil}}
          })

      ensure_goal_conversation!(review, project, user)

      seed_progress_events!(session, [
        %{type: "plan", seq: 1, total: 1},
        %{type: "plan_assessed", seq: 2, total: 1, needs_translation: 1, up_to_date: 0},
        %{
          type: "item_awaiting_input",
          seq: 3,
          index: 0,
          output_path: "es/releases.txt",
          locale: "es"
        }
      ])
    end
  end

  defp ensure_goal_conversation!(review, project, user) do
    conversation = Glossia.Toki.ensure_review_conversation(review, project.id)
    now = DateTime.utc_now()

    Repo.insert_all(
      Glossia.LinguisticReviews.Participant,
      [%{linguistic_review_id: review.id, user_id: user.id, inserted_at: now, updated_at: now}],
      on_conflict: :nothing
    )

    # Explicit demo dialogue, not a model call or an inferred production decision.
    human =
      Repo.get_by(Glossia.Toki.Message, conversation_id: conversation.id, role: "user") ||
        Repo.insert!(%Glossia.Toki.Message{
          conversation_id: conversation.id,
          user_id: user.id,
          role: "user",
          status: "completed",
          content: "This release guide is about source control, not trees."
        })

    proposal =
      Repo.get_by(Glossia.Toki.Message, reply_to_id: human.id) ||
        Repo.insert!(%Glossia.Toki.Message{
          conversation_id: conversation.id,
          reply_to_id: human.id,
          role: "assistant",
          status: "completed",
          content:
            "Proposed decision: branch means a source-control release branch. Resolve the goal to approve it; optionally save the terminology as Spanish repository guidance."
        })

    if review.status == "answered" and is_nil(review.resolution_message_id) do
      review |> Ecto.Changeset.change(resolution_message_id: proposal.id) |> Repo.update!()
    end
  end

  defp seed_translation_sessions!(%Project{} = project, %User{} = user) do
    now = DateTime.utc_now()
    two_hours_ago = DateTime.add(now, -7200, :second)
    one_hour_ago = DateTime.add(now, -3600, :second)
    fifteen_min_ago = DateTime.add(now, -900, :second)

    # Session 1: completed translation (en -> es, fr). Production emits a single
    # `status` event summarising the run; the file-by-file view is rebuilt from
    # the durable progress events RepositoryRun broadcasts.
    {:ok, session1} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "a1b2c3d",
        commit_message: "Update blog post: Getting started with Glossia",
        status: "completed",
        outcome: "translated",
        translated_content_count: 3,
        content_hit_count: 2,
        source_language: "en",
        target_languages: ["es", "fr"],
        publication_branch: "glossia/translate-a1b2c3d",
        publication_commit_sha: "f6e5d4c3b2a1",
        pull_request_url: "https://github.com/dev-user/blog/pull/12",
        pull_request_number: 12,
        summary: "Translated 3 files into Spanish and French. 2 files were already up to date.",
        started_at: two_hours_ago,
        completed_at: DateTime.add(two_hours_ago, 342, :second)
      })

    seed_progress_events!(session1, session1_progress_events())

    record_translation_status!(
      session1,
      "Translated 3 files into Spanish and French. 2 files were already up to date."
    )

    # Session 2: a run superseded by a newer default-branch commit. Production
    # records no dedicated superseded event — the session is cancelled and the
    # replacement run's outcome tells the story. Items in flight are closed out
    # with `item_cancelled` so the panel does not leave them spinning.
    {:ok, superseded_session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "d3e4f5a",
        commit_message: "Add new blog post: Advanced localization patterns",
        status: "cancelled",
        outcome: "superseded",
        translated_content_count: 1,
        content_hit_count: 0,
        source_language: "en",
        target_languages: ["ja", "de"],
        publication_branch: "glossia/translate-d3e4f5a",
        publication_commit_sha: "b4c5d6e7f8a9",
        pull_request_url: "https://github.com/dev-user/blog/pull/13",
        pull_request_number: 13,
        started_at: one_hour_ago,
        completed_at: DateTime.add(one_hour_ago, 180, :second)
      })

    seed_progress_events!(superseded_session, superseded_session_progress_events())

    # Session 3: the replacement session, still in flight. Its first file is
    # done, the second is in the middle of translating. Because it is still
    # `running`, no completion status event has been recorded yet.
    {:ok, session2} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "e4f5g6h",
        commit_message: "Polish advanced localization examples",
        status: "running",
        source_language: "en",
        target_languages: ["ja", "de"],
        continued_from_session_id: superseded_session.id,
        publication_branch: superseded_session.publication_branch,
        publication_commit_sha: superseded_session.publication_commit_sha,
        pull_request_url: superseded_session.pull_request_url,
        pull_request_number: superseded_session.pull_request_number,
        started_at: fifteen_min_ago
      })

    seed_progress_events!(session2, session2_progress_events())

    # ClickHouse buffer flush for the session1 status event.
    Process.sleep(2_000)
  end

  # Broadcasts durable progress events through the same seam production uses,
  # so each event is written to `translation_session_progress_events` and folds
  # into the same panel state a live viewer would see.
  defp seed_progress_events!(%TranslationSession{} = session, events) do
    Enum.each(events, &TranslationSessions.broadcast_session_event(session, &1))
  end

  # Replays each demo session's durable progress events on top of whatever the
  # database already has. `broadcast_session_event` inserts with
  # `on_conflict: :nothing` on `(session_id, seq)`, so this is a no-op on a
  # freshly seeded database and backfills the missing rows on an older one.
  defp backfill_seeded_translation_progress!(%Project{} = project) do
    events_by_sha = %{
      "a1b2c3d" => session1_progress_events(),
      "d3e4f5a" => superseded_session_progress_events(),
      "e4f5g6h" => session2_progress_events()
    }

    sessions =
      Repo.all(
        from s in TranslationSession,
          where: s.project_id == ^project.id and s.commit_sha in ["a1b2c3d", "d3e4f5a", "e4f5g6h"]
      )

    Enum.each(sessions, fn session ->
      case Map.get(events_by_sha, session.commit_sha) do
        nil -> :ok
        events -> seed_progress_events!(session, events)
      end
    end)
  end

  defp session1_progress_events do
    [
      %{type: "run_started"},
      %{type: "plan", total: 5},
      %{type: "plan_assessed", total: 5, needs_translation: 3, up_to_date: 2},
      %{
        type: "item_started",
        index: 0,
        total: 5,
        output_path: "content/es/blog/getting-started.md",
        locale: "es"
      },
      %{
        type: "item_completed",
        index: 0,
        output_path: "content/es/blog/getting-started.md",
        output_preview: seed_translation_preview(:es_getting_started),
        model_calls: 2
      },
      %{
        type: "item_started",
        index: 1,
        total: 5,
        output_path: "content/fr/blog/getting-started.md",
        locale: "fr"
      },
      %{
        type: "item_completed",
        index: 1,
        output_path: "content/fr/blog/getting-started.md",
        output_preview: seed_translation_preview(:fr_getting_started),
        model_calls: 2
      },
      %{
        type: "item_started",
        index: 2,
        total: 5,
        output_path: "content/es/blog/getting-started-meta.json",
        locale: "es"
      },
      %{
        type: "item_completed",
        index: 2,
        output_path: "content/es/blog/getting-started-meta.json",
        output_preview: seed_translation_preview(:es_meta),
        model_calls: 1
      }
    ]
  end

  defp superseded_session_progress_events do
    [
      %{type: "run_started"},
      %{type: "plan", total: 4},
      %{type: "plan_assessed", total: 4, needs_translation: 4, up_to_date: 0},
      %{
        type: "item_started",
        index: 0,
        total: 4,
        output_path: "content/ja/blog/advanced-localization.md",
        locale: "ja"
      },
      %{
        type: "item_completed",
        index: 0,
        output_path: "content/ja/blog/advanced-localization.md",
        output_preview: seed_translation_preview(:ja_advanced),
        model_calls: 3
      },
      %{
        type: "item_started",
        index: 1,
        total: 4,
        output_path: "content/de/blog/advanced-localization.md",
        locale: "de"
      },
      %{
        type: "item_cancelled",
        index: 1,
        output_path: "content/de/blog/advanced-localization.md",
        locale: "de",
        reason: %{"kind" => "session_superseded"}
      }
    ]
  end

  defp session2_progress_events do
    [
      %{type: "run_started"},
      %{type: "plan", total: 4},
      %{type: "plan_assessed", total: 4, needs_translation: 4, up_to_date: 0},
      %{
        type: "item_started",
        index: 0,
        total: 4,
        output_path: "content/ja/blog/advanced-localization.md",
        locale: "ja"
      },
      %{
        type: "item_completed",
        index: 0,
        output_path: "content/ja/blog/advanced-localization.md",
        output_preview: seed_translation_preview(:ja_advanced),
        model_calls: 3
      },
      %{
        type: "item_started",
        index: 1,
        total: 4,
        output_path: "content/de/blog/advanced-localization.md",
        locale: "de"
      }
    ]
  end

  defp record_translation_status!(%TranslationSession{} = session, content) do
    Ingestion.record_translation_session_event(session.id, 0, "status", content, "{}")
  end

  # Short, realistic translated excerpts so the "Show translated output"
  # disclosures on the file rows contain actual content rather than lorem ipsum.
  defp seed_translation_preview(:es_getting_started) do
    """
    # Primeros pasos con Glossia

    Glossia mantiene la localización de tu proyecto sincronizada con tu código.
    En esta guía configurarás Glossia en tu repositorio en menos de cinco minutos.

    ## Requisitos previos

    - Una cuenta de Glossia
    - Un repositorio de GitHub con contenido en inglés
    """
  end

  defp seed_translation_preview(:fr_getting_started) do
    """
    # Prise en main de Glossia

    Glossia maintient la localisation de votre projet synchronisée avec votre code.
    Dans ce guide, vous allez configurer Glossia dans votre dépôt en moins de cinq minutes.

    ## Prérequis

    - Un compte Glossia
    - Un dépôt GitHub avec du contenu en anglais
    """
  end

  defp seed_translation_preview(:es_meta) do
    ~s({\n  "title": "Primeros pasos con Glossia",\n  "description": "Configura Glossia en tu proyecto en cinco minutos.",\n  "tags": ["guía", "localización", "inicio rápido"]\n})
  end

  defp seed_translation_preview(:de_advanced) do
    """
    # Erweiterte Lokalisierung

    Glossia übersetzt nur geänderte Inhalte und berücksichtigt dabei die
    Terminologie und Anweisungen aus deinem Repository.

    ## Änderungen prüfen

    Prüfe die Übersetzungen gemeinsam mit ihren Lockfiles im Pull Request.
    Unveränderte Übersetzungen bleiben erhalten.
    """
  end

  defp seed_translation_preview(:ja_advanced) do
    """
    # 高度なローカライゼーションのパターン

    このガイドでは、Glossia を使って大規模な多言語プロジェクトを管理するための
    実践的なパターンを紹介します。翻訳の一貫性を保ちながら、レビューのオーバーヘッドを
    最小限に抑える方法を学びます。

    ## 前提条件

    - Glossia を設定済みのリポジトリ
    - ソース言語で書かれたコンテンツ
    """
  end

  defp refresh_seeded_translation_outcomes!(%Project{} = project) do
    now = DateTime.utc_now()

    updates = [
      {"a1b2c3d", %{outcome: "translated", translated_content_count: 3, content_hit_count: 2}},
      {"d3e4f5a", %{outcome: "superseded", translated_content_count: 1, content_hit_count: 0}},
      {"e4f5g6h",
       %{
         status: "running",
         outcome: nil,
         translated_content_count: 0,
         content_hit_count: 0,
         completed_at: nil,
         updated_at: now
       }}
    ]

    Enum.each(updates, fn {commit_sha, attrs} ->
      from(s in TranslationSession,
        where: s.project_id == ^project.id and s.commit_sha == ^commit_sha
      )
      |> Repo.update_all(set: Map.to_list(attrs))
    end)
  end

  defp ensure_translation_dashboard_history!(%Project{} = project, %User{} = user) do
    now = DateTime.utc_now()

    history = [
      {"seed001", "Publish the summer product guide", 13, "translated", 4, 2},
      {"seed002", "Refresh the pricing page metadata", 12, "content_hit", 0, 7},
      {"seed003", "Add onboarding examples", 10, "translated", 3, 1},
      {"seed004", "Draft the partner announcement", 9, "superseded", 2, 0},
      {"seed005", "Update the developer guide", 7, "translated", 5, 4},
      {"seed006", "Correct a navigation link", 6, "content_hit", 0, 6},
      {"seed007", "Launch the localization handbook", 4, "translated", 8, 2},
      {"seed008", "Revise the release announcement", 3, "cancelled", 1, 0},
      {"seed009", "Document the translation workflow", 2, "translated", 2, 5},
      {"seed010", "Reorder the documentation sidebar", 1, "content_hit", 0, 9}
    ]

    Enum.each(history, fn {sha, message, days_ago, outcome, translated, hits} ->
      happened_at = DateTime.add(now, -days_ago * 86_400, :second)
      status = if outcome in ["superseded", "cancelled"], do: "cancelled", else: "completed"

      attrs = %{
        commit_sha: sha,
        commit_message: message,
        status: status,
        outcome: outcome,
        translated_content_count: translated,
        content_hit_count: hits,
        source_language: "en",
        target_languages: ["es", "fr"],
        summary: translation_seed_summary(outcome, translated, hits),
        started_at: happened_at,
        completed_at: DateTime.add(happened_at, 240, :second)
      }

      session =
        case Repo.get_by(TranslationSession, project_id: project.id, commit_sha: sha) do
          nil ->
            {:ok, session} = TranslationSessions.create_session(user.account, project, attrs)
            session

          session ->
            session
            |> TranslationSession.changeset(attrs)
            |> Repo.update!()
        end

      session
      |> Ecto.Changeset.change(inserted_at: happened_at, updated_at: happened_at)
      |> Repo.update!()
    end)
  end

  defp translation_seed_summary("content_hit", _translated, hits),
    do: "#{hits} content items were already current."

  defp translation_seed_summary("superseded", translated, _hits),
    do: "Reused #{translated} translated content items in the replacement run."

  defp translation_seed_summary("cancelled", translated, _hits),
    do: "Cancelled after translating #{translated} content item."

  defp translation_seed_summary(_outcome, translated, hits),
    do: "Translated #{translated} content items and reused #{hits} content hits."

  # Seeds enough rows to exercise the cursor pagination on the Recent activity
  # table. The page size is 25 — 120 rows gives a healthy 5 pages of history.
  defp ensure_translation_pagination_history!(%Project{} = project, %User{} = user) do
    total = 120

    inserted =
      Repo.one(
        from s in TranslationSession,
          where: s.project_id == ^project.id and like(s.commit_sha, "page%"),
          select: count(s.id)
      )

    if inserted < total do
      seed_translation_pagination_history!(project, user, total)
    end
  end

  defp seed_translation_pagination_history!(%Project{} = project, %User{} = user, total) do
    now = DateTime.utc_now()

    outcomes = [
      {"translated", "completed"},
      {"content_hit", "completed"},
      {"translated", "completed"},
      {"failed", "failed"},
      {"cancelled", "cancelled"},
      {"superseded", "cancelled"}
    ]

    messages = [
      "Refresh the pricing page",
      "Ship the winter blog series",
      "Localize the onboarding wizard",
      "Update the glossary handbook",
      "Publish the release notes",
      "Rework the getting started guide",
      "Localize the settings screens",
      "Translate the changelog",
      "Update the docs sidebar",
      "Localize the new billing FAQ",
      "Refresh the marketing homepage",
      "Correct translation of a button label",
      "Publish the roadmap page",
      "Ship the developer changelog",
      "Localize the docs quickstart"
    ]

    Enum.each(1..total, fn i ->
      commit_sha = "page" <> String.pad_leading(Integer.to_string(i), 4, "0")

      case Repo.get_by(TranslationSession, project_id: project.id, commit_sha: commit_sha) do
        %TranslationSession{} ->
          :ok

        nil ->
          {outcome, status} = Enum.at(outcomes, rem(i, length(outcomes)))
          message = Enum.at(messages, rem(i, length(messages))) <> " (##{i})"

          translated = rem(i * 7, 9)
          hits = rem(i * 3, 11)
          minutes_ago = i * 37 + 20
          happened_at = DateTime.add(now, -minutes_ago * 60, :second)
          runtime_seconds = 90 + rem(i * 13, 300)

          attrs = %{
            commit_sha: commit_sha,
            commit_message: message,
            status: status,
            outcome: outcome,
            translated_content_count: translated,
            content_hit_count: hits,
            source_language: "en",
            target_languages: Enum.take(["es", "fr", "de", "ja", "pt", "it"], 1 + rem(i, 4)),
            summary: translation_seed_summary(outcome, translated, hits),
            started_at: happened_at,
            completed_at: DateTime.add(happened_at, runtime_seconds, :second)
          }

          {:ok, session} = TranslationSessions.create_session(user.account, project, attrs)

          session
          |> Ecto.Changeset.change(inserted_at: happened_at, updated_at: happened_at)
          |> Repo.update!()
      end
    end)
  end

  defp ensure_discussion_comment!(ticket, user, opts) do
    body = Keyword.fetch!(opts, :body)

    import Ecto.Query

    existing =
      Repo.one(
        from c in DiscussionComment,
          where: c.discussion_id == ^ticket.id and c.body == ^body
      )

    if existing do
      existing
    else
      {:ok, comment} = Discussions.add_comment(ticket, user, %{"body" => body})
      comment
    end
  end

  defp reset_routing_rules!(account) do
    Repo.delete_all(
      from r in Glossia.Accounts.TranslationRoutingRule, where: r.account_id == ^account.id
    )
  end

  defp ensure_routing_rule!(account, user, target_locale, model_handle) do
    model = LLMModels.get_model_by_handle(model_handle, account.id)

    if model do
      {:ok, _rule} =
        TranslationRouting.create_rule(account, user, model, %{
          "target_locale" => target_locale
        })
    end
  end

  defp ensure_llm_model!(account, user, opts) do
    handle = Keyword.fetch!(opts, :handle)
    requested_default = Keyword.get(opts, :default, :unspecified)
    requested_concurrency = Keyword.get(opts, :translation_concurrency, :unspecified)

    attrs =
      %{
        "handle" => handle,
        "model" => Keyword.fetch!(opts, :model),
        "api_key" => Keyword.fetch!(opts, :api_key),
        "category" => Keyword.get(opts, :category, "generative"),
        "decision_min_score" => Keyword.get(opts, :decision_min_score, 7.0)
      }
      |> then(fn attrs ->
        if requested_default == :unspecified,
          do: attrs,
          else: Map.put(attrs, "default", requested_default)
      end)
      |> then(fn attrs ->
        if requested_concurrency == :unspecified,
          do: attrs,
          else: Map.put(attrs, "translation_concurrency", requested_concurrency)
      end)

    case LLMModels.get_model_by_handle(handle, account.id) do
      nil ->
        {:ok, model} = LLMModels.create_model(account, user, attrs)
        model

      existing ->
        cond do
          existing.category != attrs["category"] or
              existing.decision_min_score != attrs["decision_min_score"] ->
            do_update_llm_model!(account, user, existing, attrs)

          existing.model != attrs["model"] ->
            do_update_llm_model!(account, user, existing, attrs)

          existing.api_key != attrs["api_key"] ->
            do_update_llm_model!(account, user, existing, attrs)

          requested_default != :unspecified and existing.default != requested_default ->
            do_update_llm_model!(account, user, existing, attrs)

          requested_concurrency != :unspecified and
              existing.translation_concurrency != requested_concurrency ->
            do_update_llm_model!(account, user, existing, attrs)

          true ->
            existing
        end
    end
  end

  defp do_update_llm_model!(account, user, existing, attrs) do
    {:ok, model} = LLMModels.update_model(account, user, existing, attrs)
    model
  end
end

Glossia.Seeds.run()
