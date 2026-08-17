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
  alias Glossia.LLMModels
  alias Glossia.Quality

  alias Glossia.Quality.{
    Finding,
    Occurrence,
    Page,
    ProjectContextEntry,
    ProjectContextVersion,
    Run,
    SessionEvent
  }

  alias Glossia.Github.Installations
  alias Glossia.Glossaries
  alias Glossia.OAuth.FirstPartyClient
  alias Glossia.Organizations
  alias Glossia.Projects
  alias Glossia.Discussions
  alias Glossia.Discussions.{Discussion, DiscussionComment}
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession
  alias Glossia.Sandboxes.{Sandbox, SandboxSession}
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

    # Membership mix: admin + member + linguist
    ensure_member!(acme, alex, "member")
    ensure_member!(acme, maria, "linguist")
    ensure_member!(northwind, dev, "member")

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

    # Setup events for the "blog" project to exercise the agent session UI
    blog_project = Projects.get_project(dev.account, "blog")
    if blog_project, do: ensure_setup_events!(blog_project)

    # Analytics domain for the "blog" project, used to dogfood the @glossia/web
    # SDK on the dev site (see :web_analytics in config/dev.exs). We mark it
    # verified so the analytics page lights up in development without having
    # to run the DNS / meta-tag dance against a fake domain.
    if blog_project, do: ensure_analytics_settings!(blog_project, domain: "localhost")
    if blog_project, do: ensure_analytics_events!(blog_project)

    # Translation sessions for the "blog" project to exercise the activity timeline
    if blog_project, do: ensure_translation_sessions!(blog_project, dev)
    if blog_project, do: ensure_quality_data!(blog_project, dev)

    # A local git remote that stands in for the blog project's GitHub repo, so the
    # full clone → translate → PR flow can run end-to-end locally (dev only).
    seed_local_remote!("dev-user/blog",
      files: [
        {"GLOSSIA.md",
         """
         ---
         source_language: en
         model: local-codex
         targets:
           es: Spanish
           fr: French
         sources:
           "docs/*.md": "docs/i18n/{locale}/*.md"
         ---
         Blog project context: keep a friendly, concise tone.
         """},
        {"GLOSSIA/fr.md",
         """
         ---
         locale: fr
         model: local-claude
         ---
         French translations should feel natural and editorial, rather than literal.
         """},
        {"docs/getting-started.md",
         "# Getting started\n\nWelcome to the blog. This short guide helps you publish your first post.\n"}
      ]
    )

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

    # Historical sandbox lifecycle records for workflow execution APIs.
    if blog_project, do: ensure_sandbox_history!(blog_project)

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
          - Prefer terminology that maps to UI labels.

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

          ## Terminology

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

    # Terminology: seed entries with per-language translations.
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
              term: "terminology",
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
          change_note: "Initial terminology"
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
              term: "terminology",
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
          change_note: "Initial org terminology"
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
        title: "Add support for Portuguese (Brazil) terminology",
        body:
          "We need pt-BR as a supported language in the terminology section. Right now only pt-PT is available.",
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

    _terminology_request =
      ensure_discussion!(acme.account, maria,
        title: "Terminology suggestion: Add billing terms",
        body:
          "Proposed terminology update with billing terminology for support and onboarding content.",
        status: "open",
        kind: "glossary_suggestion",
        metadata: %{
          "resource" => "glossary",
          "change_note" => "Add billing and invoice terminology",
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
      default: true
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
      default: false
    )

    ensure_llm_model!(dev.account, dev,
      handle: "long-form-guides",
      model: "fireworks_ai/accounts/fireworks/models/kimi-k2p5",
      api_key: "fw-dev-placeholder-key",
      default: false
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

    :ok
  end

  defp ensure_quality_data!(project, user) do
    {:ok, _profile} =
      Quality.upsert_profile(project, %{
        source_locale: "en",
        locale_origins: %{
          "en" => "http://localhost:4000",
          "es" => "http://localhost:4000/es"
        },
        seed_paths: ["/", "/docs"],
        max_pages: 10
      })

    now = DateTime.utc_now()

    run_attrs = %{
      account_id: project.account_id,
      project_id: project.id,
      triggered_by_id: user.id,
      status: "completed",
      configuration: %{
        "source_locale" => "en",
        "locale_origins" => %{
          "en" => "http://localhost:4000",
          "es" => "http://localhost:4000/es"
        },
        "seed_paths" => ["/", "/docs"],
        "max_pages" => 10,
        "seeded" => true
      },
      pages_count: 1,
      findings_count: 1,
      started_at: DateTime.add(now, -15, :minute),
      completed_at: DateTime.add(now, -14, :minute)
    }

    run =
      case Repo.get(Run, "00000000-0000-4000-8000-00000000a101") do
        nil ->
          Repo.insert!(
            struct!(Run, Map.put(run_attrs, :id, "00000000-0000-4000-8000-00000000a101"))
          )

        existing ->
          existing |> Ecto.Changeset.change(run_attrs) |> Repo.update!()
      end

    page_attrs = %{
      run_id: run.id,
      project_id: project.id,
      locale: "es",
      logical_path: "/docs",
      requested_url: "http://localhost:4000/es/docs",
      final_url: "http://localhost:4000/es/docs",
      title: "Documentación",
      document_locale: "es",
      visible_text: "Localization QA helps teams ship consistent translations.",
      alternate_links: %{"en" => "http://localhost:4000/docs"}
    }

    page =
      case Repo.get(Page, "00000000-0000-4000-8000-00000000a102") do
        nil ->
          Repo.insert!(
            struct!(Page, Map.put(page_attrs, :id, "00000000-0000-4000-8000-00000000a102"))
          )

        existing ->
          existing |> Ecto.Changeset.change(page_attrs) |> Repo.update!()
      end

    finding_attrs = %{
      project_id: project.id,
      fingerprint: String.duplicate("a", 64),
      check: "possible_untranslated_content",
      category: "language",
      severity: "medium",
      status: "acknowledged",
      title: "Possible untranslated content",
      description: "The Spanish page contains a substantial phrase from the English page.",
      locale: "es",
      logical_path: "/docs",
      source_text: "Localization QA",
      target_text: "Localization QA",
      metadata: %{},
      first_seen_at: now,
      last_seen_at: now
    }

    finding =
      case Repo.get(Finding, "00000000-0000-4000-8000-00000000a103") do
        nil ->
          Repo.insert!(
            struct!(Finding, Map.put(finding_attrs, :id, "00000000-0000-4000-8000-00000000a103"))
          )

        existing ->
          existing |> Ecto.Changeset.change(finding_attrs) |> Repo.update!()
      end

    unless Repo.get(Occurrence, "00000000-0000-4000-8000-00000000a104") do
      Repo.insert!(%Occurrence{
        id: "00000000-0000-4000-8000-00000000a104",
        finding_id: finding.id,
        run_id: run.id,
        page_id: page.id,
        evidence: %{
          "requested_url" => page.requested_url,
          "text" => finding.source_text
        }
      })
    end

    [
      {"00000000-0000-4000-8000-00000000a107", "session_started", "Review session started",
       "The browser sandbox is ready.", nil, nil, %{}, 0},
      {"00000000-0000-4000-8000-00000000a108", "navigation_started", "Opening es /docs",
       page.requested_url, nil, nil,
       %{"locale" => "es", "logical_path" => "/docs", "requested_url" => page.requested_url}, 4},
      {"00000000-0000-4000-8000-00000000a109", "page_captured", "Captured es /docs", page.title,
       page.id, nil, %{"locale" => "es", "logical_path" => "/docs"}, 9},
      {"00000000-0000-4000-8000-00000000a110", "analysis_started", "Analyzing captured pages",
       "The agent is comparing navigation, declared languages, and visible copy.", nil, nil, %{},
       11},
      {"00000000-0000-4000-8000-00000000a111", "finding_recorded", finding.title,
       finding.description, page.id, finding.id,
       %{
         "severity" => finding.severity,
         "locale" => finding.locale,
         "logical_path" => finding.logical_path
       }, 13},
      {"00000000-0000-4000-8000-00000000a112", "session_completed", "Review session completed",
       "1 page inspected and 1 finding recorded.", nil, nil, %{}, 18}
    ]
    |> Enum.each(fn {id, kind, label, detail, page_id, finding_id, metadata, offset} ->
      event_attrs = %{
        run_id: run.id,
        page_id: page_id,
        finding_id: finding_id,
        kind: kind,
        label: label,
        detail: detail,
        metadata: metadata,
        inserted_at: DateTime.add(run.started_at, offset, :second)
      }

      case Repo.get(SessionEvent, id) do
        nil -> Repo.insert!(struct!(SessionEvent, Map.put(event_attrs, :id, id)))
        existing -> existing |> Ecto.Changeset.change(event_attrs) |> Repo.update!()
      end
    end)

    context_attrs = %{
      project_id: project.id,
      created_by_id: user.id,
      version: 1,
      change_note: "Approved a translation from the seeded localization QA finding"
    }

    context =
      case Repo.get(ProjectContextVersion, "00000000-0000-4000-8000-00000000a105") do
        nil ->
          Repo.insert!(
            struct!(
              ProjectContextVersion,
              Map.put(context_attrs, :id, "00000000-0000-4000-8000-00000000a105")
            )
          )

        existing ->
          existing |> Ecto.Changeset.change(context_attrs) |> Repo.update!()
      end

    context_entry_attrs = %{
      project_context_version_id: context.id,
      origin_finding_id: finding.id,
      kind: "terminology",
      locale: "es",
      source_text: "Localization QA",
      instruction: "QA de localización",
      route_scope: "/docs"
    }

    case Repo.get(ProjectContextEntry, "00000000-0000-4000-8000-00000000a106") do
      nil ->
        Repo.insert!(
          struct!(
            ProjectContextEntry,
            Map.put(context_entry_attrs, :id, "00000000-0000-4000-8000-00000000a106")
          )
        )

      existing ->
        existing |> Ecto.Changeset.change(context_entry_attrs) |> Repo.update!()
    end

    :ok
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
        name = if :rand.uniform(20) == 1, do: "signup", else: "pageview"

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
  # Terminology
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

  defp ensure_setup_events!(%Project{} = project) do
    existing = Glossia.Ingestion.list_setup_events(project.id)

    if existing == [] do
      events = [
        {0, "agent_start", "", "{}"},
        {1, "turn_start", "", "{}"},
        {2, "message_start", "Analyzing repository structure...", "{}"},
        {3, "message_update",
         "I can see this is a blog built with Astro. Let me examine the content directory and configuration files.",
         "{}"},
        {4, "message_end", "", "{}"},
        {5, "tool_execution_start", "ls -la src/content/", ~s({"tool_name":"shell"})},
        {6, "tool_execution_end", "blog/\nen/\nes/\nfr/", ~s({"tool_name":"shell"})},
        {7, "message_start",
         "The repository has content organized by language in src/content/. I can see English, Spanish, and French directories.",
         "{}"},
        {8, "message_end", "", "{}"},
        {9, "tool_execution_start", "cat astro.config.mjs", ~s({"tool_name":"shell"})},
        {10, "tool_execution_end",
         "export default defineConfig({ integrations: [mdx()], i18n: { defaultLocale: 'en', locales: ['en', 'es', 'fr'] } })",
         ~s({"tool_name":"shell"})},
        {11, "message_start",
         "The Astro config confirms i18n support with English as the default locale and Spanish and French as additional locales. Now let me create the GLOSSIA.md file.",
         "{}"},
        {12, "message_end", "", "{}"},
        {13, "tool_execution_start", "Writing GLOSSIA.md", ~s({"tool_name":"file_write"})},
        {14, "tool_execution_end", "File written successfully", ~s({"tool_name":"file_write"})},
        {15, "message_start",
         "I have created GLOSSIA.md with the localization configuration for this Astro blog. The file describes the content structure, supported languages, and recommended translation workflow.",
         "{}"},
        {16, "message_end", "", "{}"},
        {17, "turn_end", "", "{}"},
        {18, "agent_end", "", "{}"}
      ]

      for {seq, type, content, metadata} <- events do
        Glossia.Ingestion.record_setup_event(project.id, seq, type, content, metadata)
      end

      Process.sleep(2_000)
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

    if existing > 0, do: :ok, else: seed_translation_sessions!(project, user)
  end

  defp seed_translation_sessions!(%Project{} = project, %User{} = user) do
    now = DateTime.utc_now()
    two_hours_ago = DateTime.add(now, -7200, :second)
    one_hour_ago = DateTime.add(now, -3600, :second)

    # Session 1: completed translation (en -> es, fr)
    {:ok, session1} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "a1b2c3d",
        commit_message: "Update blog post: Getting started with Glossia",
        status: "completed",
        source_language: "en",
        target_languages: ["es", "fr"],
        publication_branch: "glossia/translate-a1b2c3d",
        publication_commit_sha: "f6e5d4c3b2a1",
        pull_request_url: "https://github.com/glossia/demo/pull/12",
        summary:
          "Translated 3 files into Spanish and French. All translations verified against terminology.",
        started_at: two_hours_ago,
        completed_at: DateTime.add(two_hours_ago, 342, :second)
      })

    session1_events = [
      {0, "message", "Starting translation session for commit a1b2c3d.", "{}"},
      {1, "thought",
       "This commit modifies a blog post. I need to check which languages are configured and translate the changed files.",
       "{}"},
      {2, "tool_call", "glossia status",
       ~s({"tool_name":"glossia-cli","command":"glossia status"})},
      {3, "tool_result",
       "Source language: en\nTarget languages: es, fr\nStale files: 3\n  - content/blog/getting-started.md (es, fr)\n  - content/blog/getting-started-meta.json (es, fr)",
       ~s({"tool_name":"glossia-cli"})},
      {4, "plan", "Translation plan for 3 files",
       ~s({"entries":[{"label":"Read voice and terminology configuration","status":"completed"},{"label":"Translate getting-started.md to Spanish","status":"completed"},{"label":"Translate getting-started.md to French","status":"completed"},{"label":"Translate getting-started-meta.json to Spanish","status":"completed"},{"label":"Translate getting-started-meta.json to French","status":"completed"},{"label":"Run terminology validation","status":"completed"}]})},
      {5, "tool_call", "glossia voice show",
       ~s({"tool_name":"glossia-cli","command":"glossia voice show"})},
      {6, "tool_result",
       "Tone: casual\nFormality: neutral\nTarget audience: Developers evaluating Glossia\nGuidelines: Write in short, concrete sentences. Prefer active voice. Use American English.",
       ~s({"tool_name":"glossia-cli"})},
      {7, "message",
       "Voice loaded. Translating content/blog/getting-started.md to Spanish with casual tone and developer-focused language.",
       "{}"},
      {8, "tool_call", "glossia translate content/blog/getting-started.md --lang es",
       ~s({"tool_name":"glossia-cli","command":"glossia translate content/blog/getting-started.md --lang es"})},
      {9, "tool_result",
       "Translated content/blog/getting-started.md -> content/es/blog/getting-started.md",
       ~s({"tool_name":"glossia-cli"})},
      {10, "message", "Spanish translation complete. Now translating to French.", "{}"},
      {11, "tool_call", "glossia translate content/blog/getting-started.md --lang fr",
       ~s({"tool_name":"glossia-cli","command":"glossia translate content/blog/getting-started.md --lang fr"})},
      {12, "tool_result",
       "Translated content/blog/getting-started.md -> content/fr/blog/getting-started.md",
       ~s({"tool_name":"glossia-cli"})},
      {13, "thought",
       "Both language translations for the main blog post are done. Now I need to handle the meta JSON file and run terminology validation.",
       "{}"},
      {14, "tool_call", "glossia translate content/blog/getting-started-meta.json --lang es,fr",
       ~s({"tool_name":"glossia-cli","command":"glossia translate content/blog/getting-started-meta.json --lang es,fr"})},
      {15, "tool_result",
       "Translated content/blog/getting-started-meta.json -> content/es/blog/getting-started-meta.json\nTranslated content/blog/getting-started-meta.json -> content/fr/blog/getting-started-meta.json",
       ~s({"tool_name":"glossia-cli"})},
      {16, "tool_call", "glossia validate --terminology",
       ~s({"tool_name":"glossia-cli","command":"glossia validate --terminology"})},
      {17, "tool_result",
       "Terminology validation passed. All terms consistent across translations.",
       ~s({"tool_name":"glossia-cli"})},
      {18, "message",
       "All translations completed and validated. 3 files translated into Spanish and French. Terminology terms are consistent.",
       "{}"}
    ]

    for {seq, type, content, metadata} <- session1_events do
      Glossia.Ingestion.record_translation_session_event(
        session1.id,
        seq,
        type,
        content,
        metadata
      )
    end

    # Session 2: running translation (en -> ja, de)
    {:ok, session2} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "e4f5g6h",
        commit_message: "Add new blog post: Advanced localization patterns",
        status: "running",
        source_language: "en",
        target_languages: ["ja", "de"],
        started_at: one_hour_ago
      })

    session2_events = [
      {0, "message", "Starting translation session for commit e4f5g6h.", "{}"},
      {1, "thought",
       "New blog post added. I need to translate it into Japanese and German. Japanese requires careful handling of honorifics and sentence structure.",
       "{}"},
      {2, "tool_call", "glossia status",
       ~s({"tool_name":"glossia-cli","command":"glossia status"})},
      {3, "tool_result",
       "Source language: en\nTarget languages: ja, de\nStale files: 2\n  - content/blog/advanced-localization.md (ja, de)\n  - content/blog/advanced-localization-meta.json (ja, de)",
       ~s({"tool_name":"glossia-cli"})},
      {4, "plan", "Translation plan for 2 files",
       ~s({"entries":[{"label":"Read voice and terminology configuration","status":"completed"},{"label":"Translate advanced-localization.md to Japanese","status":"in_progress"},{"label":"Translate advanced-localization.md to German","status":"pending"},{"label":"Translate advanced-localization-meta.json to Japanese and German","status":"pending"},{"label":"Run terminology validation","status":"pending"}]})},
      {5, "tool_call", "glossia voice show",
       ~s({"tool_name":"glossia-cli","command":"glossia voice show"})},
      {6, "tool_result",
       "Tone: casual\nFormality: neutral\nTarget audience: Developers evaluating Glossia\nCultural notes (JP): Japanese communication style values politeness and indirectness.",
       ~s({"tool_name":"glossia-cli"})},
      {7, "thought",
       "The cultural notes for Japan emphasize politeness. I should adjust the tone to be more formal for the Japanese translation while keeping the technical content accurate.",
       "{}"},
      {8, "message",
       "Translating advanced-localization.md to Japanese with adjusted formality level.", "{}"}
    ]

    for {seq, type, content, metadata} <- session2_events do
      Glossia.Ingestion.record_translation_session_event(
        session2.id,
        seq,
        type,
        content,
        metadata
      )
    end

    # Wait for buffer flush
    Process.sleep(2_000)
  end

  # ----------------------------------------------------------------------------
  # Sandboxes
  # ----------------------------------------------------------------------------

  defp ensure_sandbox_history!(%Project{} = project) do
    case Repo.get_by(Sandbox, project_id: project.id, backend_ref: "seed-project-setup") do
      %Sandbox{} ->
        :ok

      nil ->
        now = DateTime.utc_now()
        ready_at = DateTime.add(now, -5400, :second)
        terminated_at = DateTime.add(now, -4800, :second)

        {:ok, sandbox} =
          %Sandbox{account_id: project.account_id, project_id: project.id}
          |> Sandbox.changeset(%{
            status: "terminated",
            purpose: "project_setup",
            backend: "flame",
            backend_ref: "seed-project-setup",
            labels: %{"workflow" => "setup", "project_id" => to_string(project.id)},
            ready_at: ready_at,
            deadline_at: DateTime.add(ready_at, 3600, :second),
            terminated_at: terminated_at
          })
          |> Repo.insert()

        %SandboxSession{}
        |> SandboxSession.changeset(%{
          sandbox_id: sandbox.id,
          account_id: sandbox.account_id,
          project_id: sandbox.project_id,
          status: "closed",
          opened_at: ready_at,
          closed_at: terminated_at,
          close_reason: "setup_completed"
        })
        |> Repo.insert!()

        :ok
    end
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

  defp ensure_llm_model!(account, user, opts) do
    handle = Keyword.fetch!(opts, :handle)
    requested_default = Keyword.get(opts, :default, :unspecified)

    attrs =
      %{
        "handle" => handle,
        "model" => Keyword.fetch!(opts, :model),
        "api_key" => Keyword.fetch!(opts, :api_key)
      }
      |> then(fn attrs ->
        if requested_default == :unspecified,
          do: attrs,
          else: Map.put(attrs, "default", requested_default)
      end)

    case LLMModels.get_model_by_handle(handle, account.id) do
      nil ->
        {:ok, model} = LLMModels.create_model(account, user, attrs)
        model

      existing ->
        if existing.model != attrs["model"] or existing.api_key != attrs["api_key"] or
             (requested_default != :unspecified and existing.default != requested_default) do
          {:ok, model} = LLMModels.update_model(account, user, existing, attrs)
          model
        else
          existing
        end
    end
  end
end

Glossia.Seeds.run()
