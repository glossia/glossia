# Script for populating the database with realistic development data.
#
# Run with:
#
#     mix run priv/repo/seeds.exs
#
# This script is intended to be idempotent: it should be safe to run multiple
# times without creating a pile of duplicate records.

defmodule Glossia.Seeds do
  alias Glossia.Repo

  alias Glossia.Accounts.{Account, Glossary, Identity, PersonalAccessToken, Project, User, Voice}

  alias Glossia.DeveloperTokens
  alias Glossia.Glossaries
  alias Glossia.Organizations
  alias Glossia.Projects
  alias Glossia.Support
  alias Glossia.Support.{Ticket, TicketMessage}
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
          """,
          change_note: "Initial voice"
        },
        %{
          tone: "authoritative",
          formality: "formal",
          target_audience: "Engineering leaders and localization managers",
          guidelines: """
          ## Style

          - Be precise and unambiguous.
          - Avoid hype and filler.
          - Prefer terminology that maps to UI labels.

          ## Formatting

          - Use code fences for commands.
          - Use tables for structured reference data.
          """,
          change_note: "Tighten language for documentation"
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
          ],
          change_note: "Initial org voice"
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
    ensure_personal_access_token!(dev.account, dev,
      name: "CI Pipeline Token",
      description: "Used by GitHub Actions to push translations",
      scope: "voice:read voice:write glossary:read glossary:write"
    )

    # ── Support tickets ──
    ticket1 =
      ensure_ticket!(dev.account, dev,
        title: "Voice settings not saving",
        description:
          "When I change the tone to 'playful' and click save, the page reloads but the tone reverts to 'casual'. Tried in Chrome and Firefox.",
        type: "issue",
        status: "in_progress"
      )

    ensure_ticket_message!(ticket1, dev,
      body: "I can reproduce this every time. Attaching a screen recording would help.",
      is_staff: true
    )

    ensure_ticket_message!(ticket1, dev,
      body: "Thanks! I recorded it. The save button shows a spinner but the value snaps back."
    )

    _ticket2 =
      ensure_ticket!(alex.account, alex,
        title: "Add support for Portuguese (Brazil) glossary",
        description:
          "We need pt-BR as a supported language in the glossary section. Right now only pt-PT is available.",
        type: "request",
        status: "open"
      )

    ticket3 =
      ensure_ticket!(dev.account, dev,
        title: "OAuth redirect URI validation too strict",
        description:
          "When I enter http://localhost:3000/callback as a redirect URI it gets rejected. Local development URIs should be allowed.",
        type: "issue",
        status: "resolved"
      )

    ensure_ticket_message!(ticket3, dev,
      body:
        "We have relaxed the URI validation for localhost addresses. This should work now. Let us know if you still see issues.",
      is_staff: true
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

  defp ensure_personal_access_token!(account, user, opts) do
    name = Keyword.fetch!(opts, :name)

    existing =
      Repo.one(
        from t in PersonalAccessToken,
          where: t.account_id == ^account.id and t.name == ^name and is_nil(t.revoked_at)
      )

    if existing do
      existing
    else
      {:ok, %{token: token}} =
        DeveloperTokens.create_personal_access_token(account, user, %{
          "name" => name,
          "description" => Keyword.get(opts, :description, ""),
          "scope" => Keyword.get(opts, :scope, ""),
          "expires_at" => DateTime.add(DateTime.utc_now(), 90, :day)
        })

      token
    end
  end

  # ----------------------------------------------------------------------------
  # Support tickets
  # ----------------------------------------------------------------------------

  defp ensure_ticket!(account, user, opts) do
    title = Keyword.fetch!(opts, :title)

    import Ecto.Query

    existing =
      Repo.one(
        from t in Ticket,
          where: t.account_id == ^account.id and t.title == ^title
      )

    if existing do
      existing
    else
      {:ok, ticket} =
        Support.create_ticket(account, user, %{
          "title" => title,
          "description" => Keyword.fetch!(opts, :description),
          "type" => Keyword.get(opts, :type, "issue")
        })

      status = Keyword.get(opts, :status, "open")

      if status != "open" do
        {:ok, ticket} = Support.update_ticket_status(ticket, status)
        ticket
      else
        ticket
      end
    end
  end

  defp ensure_ticket_message!(ticket, user, opts) do
    body = Keyword.fetch!(opts, :body)
    is_staff = Keyword.get(opts, :is_staff, false)

    import Ecto.Query

    existing =
      Repo.one(
        from m in TicketMessage,
          where: m.ticket_id == ^ticket.id and m.body == ^body
      )

    if existing do
      existing
    else
      {:ok, message} = Support.add_message(ticket, user, %{"body" => body}, is_staff: is_staff)
      message
    end
  end
end

Glossia.Seeds.run()
