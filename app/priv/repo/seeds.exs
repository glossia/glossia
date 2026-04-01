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

  alias Glossia.DeveloperTokens
  alias Glossia.LLMModels
  alias Glossia.Github.Installations
  alias Glossia.Glossaries
  alias Glossia.OAuth.FirstPartyClient
  alias Glossia.Organizations
  alias Glossia.Projects
  alias Glossia.Discussions
  alias Glossia.Discussions.{Discussion, DiscussionComment}
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession
  alias Glossia.Voices

  import Ecto.Query

  def run do
    dev =
      ensure_user!(
        handle: "dev",
        email: "dev@glossia.ai",
        name: "Dev User",
        has_access: true,
        super_admin: true,
        identity: %{provider: "dev", provider_uid: "dev-001"}
      )

    alex =
      ensure_user!(
        handle: "alex",
        email: "alex.chen@glossia.test",
        name: "Alex Chen",
        has_access: true
      )

    maria =
      ensure_user!(
        handle: "maria",
        email: "maria.rossi@glossia.test",
        name: "Maria Rossi",
        has_access: false
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
      setup_status: "pending",
      setup_target_languages: ["de", "ja", "pt-BR"]
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

    # Translation sessions for the "blog" project to exercise the activity timeline
    if blog_project, do: ensure_translation_sessions!(blog_project, dev)

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

    # Glossary: seed terminology entries with per-language translations.
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
                %{locale: "es", translation: "glosario"},
                %{locale: "ja", translation: "\u7528\u8A9E\u96C6"},
                %{locale: "de", translation: "Glossar"}
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
                %{locale: "es", translation: "glosario"},
                %{locale: "ja", translation: "\u7528\u8A9E\u96C6"},
                %{locale: "de", translation: "Glossar"},
                %{locale: "fr", translation: "glossaire"}
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
          "Proposed glossary update with billing terminology for support and onboarding content.",
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
      model: "anthropic:claude-sonnet-4-20250514",
      api_key: "sk-ant-dev-placeholder-key"
    )

    ensure_llm_model!(dev.account, dev,
      handle: "gpt-4o",
      model: "openai:gpt-4o",
      api_key: "sk-dev-placeholder-key"
    )

    ensure_llm_model!(acme.account, dev,
      handle: "acme-claude",
      model: "anthropic:claude-sonnet-4-20250514",
      api_key: "sk-ant-acme-placeholder-key"
    )

    :ok
  end

  # ----------------------------------------------------------------------------
  # Users
  # ----------------------------------------------------------------------------

  defp ensure_user!(opts) do
    handle = Keyword.fetch!(opts, :handle)
    email = Keyword.fetch!(opts, :email)
    name = Keyword.get(opts, :name)
    has_access = Keyword.get(opts, :has_access, false)
    super_admin = Keyword.get(opts, :super_admin, false)

    account =
      case Repo.get_by(Account, handle: handle) do
        nil ->
          Repo.insert!(%Account{
            handle: handle,
            type: "user",
            has_access: has_access
          })

        %Account{type: "user"} = account ->
          account

        %Account{} ->
          raise "Account handle '#{handle}' is already taken by an organization"
      end

    user =
      case Repo.get_by(User, account_id: account.id) do
        nil ->
          Repo.insert!(%User{
            account_id: account.id,
            email: email,
            name: name,
            has_access: has_access,
            super_admin: super_admin
          })

        %User{} = user ->
          user
      end

    account =
      if account.has_access != has_access do
        {:ok, account} =
          account
          |> Account.changeset(%{has_access: has_access})
          |> Repo.update()

        account
      else
        account
      end

    user =
      if user.email != email or user.name != name or user.has_access != has_access or
           user.super_admin != super_admin do
        {:ok, user} =
          user
          |> User.changeset(%{email: email, name: name, has_access: has_access})
          |> Ecto.Changeset.change(super_admin: super_admin)
          |> Repo.update()

        user
      else
        user
      end

    maybe_ensure_identity!(user, Keyword.get(opts, :identity))

    user = %{user | account: account}

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
        %Account{type: "organization"} = account ->
          Organizations.get_organization_for_account(account)

        nil ->
          {:ok, %{organization: org}} =
            Organizations.create_organization(admin, %{
              handle: handle,
              name: name
            })

          org

        %Account{} ->
          raise "Account handle '#{handle}' is already taken by a user account"
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
        DeveloperTokens.create_account_token(account, user, %{
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
    case Projects.get_project(account, handle) do
      nil ->
        {:ok, _project} =
          Projects.create_project_from_github(account, installation.id, %{
            handle: handle,
            name: Keyword.fetch!(opts, :name),
            github_repo_id: Keyword.fetch!(opts, :github_repo_id),
            github_repo_full_name: Keyword.fetch!(opts, :github_repo_full_name),
            github_repo_default_branch: Keyword.fetch!(opts, :github_repo_default_branch),
            setup_status: Keyword.get(opts, :setup_status, "pending"),
            setup_target_languages: Keyword.get(opts, :setup_target_languages, [])
          })

        :ok

      %Project{} ->
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
        summary:
          "Translated 3 files into Spanish and French. All translations verified against glossary.",
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
       ~s({"entries":[{"label":"Read voice and glossary configuration","status":"completed"},{"label":"Translate getting-started.md to Spanish","status":"completed"},{"label":"Translate getting-started.md to French","status":"completed"},{"label":"Translate getting-started-meta.json to Spanish","status":"completed"},{"label":"Translate getting-started-meta.json to French","status":"completed"},{"label":"Run glossary validation","status":"completed"}]})},
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
       "Both language translations for the main blog post are done. Now I need to handle the meta JSON file and run glossary validation.",
       "{}"},
      {14, "tool_call", "glossia translate content/blog/getting-started-meta.json --lang es,fr",
       ~s({"tool_name":"glossia-cli","command":"glossia translate content/blog/getting-started-meta.json --lang es,fr"})},
      {15, "tool_result",
       "Translated content/blog/getting-started-meta.json -> content/es/blog/getting-started-meta.json\nTranslated content/blog/getting-started-meta.json -> content/fr/blog/getting-started-meta.json",
       ~s({"tool_name":"glossia-cli"})},
      {16, "tool_call", "glossia validate --glossary",
       ~s({"tool_name":"glossia-cli","command":"glossia validate --glossary"})},
      {17, "tool_result", "Glossary validation passed. All terms consistent across translations.",
       ~s({"tool_name":"glossia-cli"})},
      {18, "message",
       "All translations completed and validated. 3 files translated into Spanish and French. Glossary terms are consistent.",
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
       ~s({"entries":[{"label":"Read voice and glossary configuration","status":"completed"},{"label":"Translate advanced-localization.md to Japanese","status":"in_progress"},{"label":"Translate advanced-localization.md to German","status":"pending"},{"label":"Translate advanced-localization-meta.json to Japanese and German","status":"pending"},{"label":"Run glossary validation","status":"pending"}]})},
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

    case LLMModels.get_model_by_handle(handle, account.id) do
      nil ->
        attrs = %{
          "handle" => handle,
          "model" => Keyword.fetch!(opts, :model),
          "api_key" => Keyword.fetch!(opts, :api_key)
        }

        {:ok, model} = LLMModels.create_model(account, user, attrs)
        model

      existing ->
        existing
    end
  end
end

Glossia.Seeds.run()
