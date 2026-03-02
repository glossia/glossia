defmodule GlossiaWeb.DashboardLive do
  use GlossiaWeb, :live_view

  require Logger

  import GlossiaWeb.DashboardComponents

  alias Glossia.Accounts
  alias Glossia.Auditing
  alias Glossia.ChangeSummary
  alias Glossia.DeveloperTokens
  alias Glossia.Glossaries
  alias Glossia.Kits
  alias Glossia.Organizations
  alias Glossia.Discussions
  alias Glossia.Voices

  @tone_options ~w(casual formal playful authoritative neutral)
  @formality_options ~w(informal neutral formal very_formal)

  # ---------------------------------------------------------------------------
  # Mount
  # ---------------------------------------------------------------------------

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # ---------------------------------------------------------------------------
  # Handle params (dispatches per live_action)
  # ---------------------------------------------------------------------------

  def handle_params(params, _uri, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)

    socket =
      case socket.assigns.live_action do
        :account -> apply_url_params_projects(socket, params)
        :logs -> apply_url_params_logs(socket, params)
        :members -> apply_url_params_members(socket, params)
        :voice -> apply_url_params_voice(socket, params)
        :glossary -> apply_url_params_glossary(socket, params)
        :kits -> apply_url_params_kits(socket, params)
        :project_activity -> apply_url_params_activity(socket, params)
        :project_translations -> apply_url_params_translations(socket, params)
        :project_new -> apply_url_params_project_new(socket, params)
        _ -> socket
      end

    socket = maybe_redirect_to_suggestion_finalize(socket, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :account, _params) do
    account = socket.assigns.account

    {projects, total} =
      case Glossia.Projects.list_projects(account) do
        {:ok, {projects, meta}} -> {projects, meta.total_count}
        _ -> {[], 0}
      end

    public_kits =
      case Kits.list_public_kits(account) do
        {:ok, {kits, _meta}} -> kits
        _ -> []
      end

    assign(socket,
      page_title: socket.assigns.handle,
      projects: projects,
      projects_total: total,
      projects_search: "",
      projects_sort_key: "name",
      projects_sort_dir: "asc",
      projects_page: 1,
      public_kits: public_kits,
      breadcrumb_items: []
    )
  end

  defp apply_action(socket, :logs, _params) do
    require_write!(socket)
    handle = socket.assigns.handle

    socket =
      if Map.has_key?(socket.assigns, :all_events) do
        socket
      else
        all_events = Auditing.list_events(socket.assigns.account.id)
        event_types = all_events |> Enum.map(& &1.name) |> Enum.uniq() |> Enum.sort()

        assign(socket,
          page_title: gettext("Logs"),
          all_events: all_events,
          event_types: event_types,
          events_search: "",
          events_sort_key: "date",
          events_sort_dir: "desc",
          events_filters: %{},
          events_page: 1
        )
      end

    assign(socket,
      breadcrumb_items: [{gettext("Logs"), "/" <> handle <> "/-/logs"}]
    )
  end

  defp apply_action(socket, :voice, _params) do
    require_action!(socket, :voice_read)
    account = socket.assigns.account
    user = socket.assigns.current_user
    existing_draft = socket.assigns[:voice_suggestion_draft]
    existing_token = socket.assigns[:voice_draft_token]
    can_voice_write = socket.assigns[:can_voice_write] || false
    can_voice_propose = socket.assigns[:can_voice_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    voice = Voices.get_latest_voice(account)
    {:ok, {versions, _meta}} = Voices.list_voice_versions(account)
    voice_suggestions = list_suggestion_discussions(account, "voice_suggestion")
    overrides = if voice, do: voice.overrides || [], else: []
    target_countries = if voice, do: voice.target_countries || [], else: []
    cultural_notes = if voice, do: voice.cultural_notes || %{}, else: %{}

    handle = socket.assigns.handle

    socket
    |> assign(
      page_title: gettext("Voice"),
      voice: voice,
      versions: versions,
      voice_suggestions: voice_suggestions,
      overrides: overrides,
      original_voice: voice,
      original_overrides: overrides,
      target_countries: target_countries,
      cultural_notes: cultural_notes,
      can_voice_write: can_voice_write,
      can_voice_propose: can_voice_propose,
      can_voice_suggest?: can_discussion_write,
      can_voice_submit?: can_discussion_write,
      changed?: false,
      voice_form_params: %{},
      voice_suggestion_draft: existing_draft,
      voice_draft_token: existing_token,
      pending_voice_suggestion_redirect:
        socket.assigns[:pending_voice_suggestion_redirect] || false,
      voice_back_path: maybe_with_draft_param("/#{handle}/-/voice", existing_token),
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      context_generation: 0,
      context_timer_ref: nil,
      context_task_ref: nil,
      generating_contexts?: false,
      breadcrumb_items: [{gettext("Voice"), "/" <> handle <> "/-/voice"}]
    )
  end

  defp apply_action(socket, :voice_suggestion_new, params) do
    require_action!(socket, :voice_read)
    account = socket.assigns.account
    handle = socket.assigns.handle
    user = socket.assigns.current_user
    can_voice_write = socket.assigns[:can_voice_write] || false
    can_voice_propose = socket.assigns[:can_voice_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    unless can_discussion_write and (can_voice_propose or can_voice_write) do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end

    baseline_voice = Voices.get_latest_voice(account)
    baseline_overrides = if baseline_voice, do: baseline_voice.overrides || [], else: []
    baseline_countries = if baseline_voice, do: baseline_voice.target_countries || [], else: []
    baseline_notes = if baseline_voice, do: baseline_voice.cultural_notes || %{}, else: %{}

    draft_token = Map.get(params, "draft")

    draft =
      socket.assigns[:voice_suggestion_draft] ||
        voice_suggestion_draft_from_token(
          draft_token,
          baseline_voice,
          baseline_overrides,
          baseline_countries,
          baseline_notes
        )

    {voice, original_voice, overrides, original_overrides, target_countries, cultural_notes,
     voice_form_params, change_summary} =
      case draft do
        %{
          voice: draft_voice,
          original_voice: draft_original_voice,
          overrides: draft_overrides,
          original_overrides: draft_original_overrides,
          target_countries: draft_countries,
          cultural_notes: draft_notes,
          voice_form_params: draft_params,
          change_summary: draft_summary
        } ->
          {draft_voice, draft_original_voice, draft_overrides, draft_original_overrides,
           draft_countries, draft_notes, draft_params, draft_summary}

        _ ->
          {baseline_voice, baseline_voice, baseline_overrides, baseline_overrides,
           baseline_countries, baseline_notes,
           %{"suggestion_title" => "", "suggestion_body" => ""}, ""}
      end

    assign(socket,
      page_title: gettext("Suggest voice changes"),
      voice: voice,
      versions: [],
      voice_suggestions: [],
      overrides: overrides,
      original_voice: original_voice,
      original_overrides: original_overrides,
      target_countries: target_countries,
      cultural_notes: cultural_notes,
      can_voice_write: can_voice_write,
      can_voice_propose: can_voice_propose,
      can_voice_suggest?: true,
      can_voice_submit?: false,
      changed?: false,
      voice_form_params: voice_form_params,
      voice_draft_token: draft_token,
      pending_voice_suggestion_redirect: false,
      voice_back_path: maybe_with_draft_param("/#{handle}/-/voice", draft_token),
      change_summary: change_summary,
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      context_generation: 0,
      context_timer_ref: nil,
      context_task_ref: nil,
      generating_contexts?: false,
      breadcrumb_items: [
        {gettext("Voice"), maybe_with_draft_param("/" <> handle <> "/-/voice", draft_token)},
        {gettext("Suggest changes"), nil}
      ]
    )
  end

  defp apply_action(socket, :voice_version, %{"version" => version_str}) do
    require_action!(socket, :voice_read)
    account = socket.assigns.account
    handle = socket.assigns.handle
    version = String.to_integer(version_str)
    voice = Voices.get_voice_version(account, version)

    unless voice do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Voice
    end

    previous = Voices.get_previous_voice_version(account, version)

    assign(socket,
      page_title: gettext("Voice #%{version}", version: version),
      voice: voice,
      previous: previous,
      can_voice_write: socket.assigns[:can_voice_write] || false,
      breadcrumb_items: [
        {gettext("Voice"), "/" <> handle <> "/-/voice"},
        {"##{version}", nil}
      ]
    )
  end

  defp apply_action(socket, :glossary, _params) do
    require_action!(socket, :glossary_read)
    account = socket.assigns.account
    user = socket.assigns.current_user
    existing_draft = socket.assigns[:glossary_suggestion_draft]
    existing_token = socket.assigns[:glossary_draft_token]
    can_glossary_write = socket.assigns[:can_glossary_write] || false
    can_glossary_propose = socket.assigns[:can_glossary_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    glossary = Glossaries.get_latest_glossary(account)
    {:ok, {versions, _meta}} = Glossaries.list_glossary_versions(account)
    glossary_suggestions = list_suggestion_discussions(account, "glossary_suggestion")
    entries = if glossary, do: glossary.entries || [], else: []

    handle = socket.assigns.handle

    socket
    |> assign(
      page_title: gettext("Glossary"),
      glossary: glossary,
      glossary_versions: versions,
      glossary_suggestions: glossary_suggestions,
      glossary_entries: entries,
      original_glossary: glossary,
      original_glossary_entries: entries,
      can_glossary_write: can_glossary_write,
      can_glossary_propose: can_glossary_propose,
      can_glossary_suggest?: can_discussion_write,
      can_glossary_submit?: can_discussion_write,
      glossary_changed?: false,
      glossary_form_params: %{},
      glossary_suggestion_draft: existing_draft,
      glossary_draft_token: existing_token,
      pending_glossary_suggestion_redirect:
        socket.assigns[:pending_glossary_suggestion_redirect] || false,
      glossary_back_path: maybe_with_draft_param("/#{handle}/-/glossary", existing_token),
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      breadcrumb_items: [{gettext("Glossary"), "/" <> handle <> "/-/glossary"}]
    )
  end

  defp apply_action(socket, :glossary_suggestion_new, params) do
    require_action!(socket, :glossary_read)
    account = socket.assigns.account
    handle = socket.assigns.handle
    user = socket.assigns.current_user
    can_glossary_write = socket.assigns[:can_glossary_write] || false
    can_glossary_propose = socket.assigns[:can_glossary_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    unless can_discussion_write and (can_glossary_propose or can_glossary_write) do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end

    baseline_glossary = Glossaries.get_latest_glossary(account)
    baseline_entries = if baseline_glossary, do: baseline_glossary.entries || [], else: []

    draft_token = Map.get(params, "draft")

    draft =
      socket.assigns[:glossary_suggestion_draft] ||
        glossary_suggestion_draft_from_token(draft_token, baseline_glossary, baseline_entries)

    {glossary, original_glossary, entries, original_entries, glossary_form_params, change_summary} =
      case draft do
        %{
          glossary: draft_glossary,
          original_glossary: draft_original_glossary,
          glossary_entries: draft_entries,
          original_glossary_entries: draft_original_entries,
          glossary_form_params: draft_params,
          change_summary: draft_summary
        } ->
          {draft_glossary, draft_original_glossary, draft_entries, draft_original_entries,
           draft_params, draft_summary}

        _ ->
          {baseline_glossary, baseline_glossary, baseline_entries, baseline_entries,
           %{"suggestion_title" => "", "suggestion_body" => "", "change_note" => ""}, ""}
      end

    assign(socket,
      page_title: gettext("Suggest glossary changes"),
      glossary: glossary,
      glossary_versions: [],
      glossary_suggestions: [],
      glossary_entries: entries,
      original_glossary: original_glossary,
      original_glossary_entries: original_entries,
      can_glossary_write: can_glossary_write,
      can_glossary_propose: can_glossary_propose,
      can_glossary_suggest?: true,
      can_glossary_submit?: false,
      glossary_changed?: false,
      glossary_form_params: glossary_form_params,
      glossary_draft_token: draft_token,
      pending_glossary_suggestion_redirect: false,
      glossary_back_path: maybe_with_draft_param("/#{handle}/-/glossary", draft_token),
      change_summary: change_summary,
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      breadcrumb_items: [
        {gettext("Glossary"),
         maybe_with_draft_param("/" <> handle <> "/-/glossary", draft_token)},
        {gettext("Suggest changes"), nil}
      ]
    )
  end

  defp apply_action(socket, :glossary_version, %{"version" => version_str}) do
    require_action!(socket, :glossary_read)
    account = socket.assigns.account
    handle = socket.assigns.handle
    version = String.to_integer(version_str)
    glossary = Glossaries.get_glossary_version(account, version)

    unless glossary do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Glossary
    end

    previous = Glossaries.get_previous_glossary_version(account, version)

    assign(socket,
      page_title: gettext("Glossary #%{version}", version: version),
      glossary: glossary,
      previous_glossary: previous,
      can_glossary_write: socket.assigns[:can_glossary_write] || false,
      breadcrumb_items: [
        {gettext("Glossary"), "/" <> handle <> "/-/glossary"},
        {"##{version}", nil}
      ]
    )
  end

  defp apply_action(socket, :members, _params) do
    handle = socket.assigns.handle

    socket =
      if Map.has_key?(socket.assigns, :all_members) do
        socket
      else
        account = socket.assigns.account

        unless account.type == "organization" and socket.assigns.is_admin do
          raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
        end

        org = Organizations.get_organization_for_account(account)
        all_members = Organizations.list_members(org)
        all_invitations = Organizations.list_pending_invitations(org)
        member_roles = all_members |> Enum.map(& &1.role) |> Enum.uniq() |> Enum.sort()

        assign(socket,
          page_title: gettext("Members"),
          organization: org,
          all_members: all_members,
          all_invitations: all_invitations,
          member_roles: member_roles,
          members_search: "",
          members_sort_key: "name",
          members_sort_dir: "asc",
          members_filters: %{},
          members_page: 1,
          invitations_search: "",
          invitations_sort_key: "email",
          invitations_sort_dir: "asc",
          invite_form: to_form(%{"email" => "", "role" => "member"}, as: :invite)
        )
      end

    assign(socket,
      breadcrumb_items: [{gettext("Members"), "/" <> handle <> "/-/members"}]
    )
  end

  defp apply_action(socket, :api_tokens, params) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle

    sort_key = Map.get(params, "tsort", "name")
    sort_dir = Map.get(params, "tdir", "asc")

    flop_params = %{
      "order_by" => [sort_key],
      "order_directions" => [sort_dir]
    }

    {:ok, {tokens, _meta}} = DeveloperTokens.list_account_tokens(account, flop_params)
    available_scopes = available_scopes()

    assign(socket,
      page_title: gettext("Account tokens"),
      api_tokens: tokens,
      available_scopes: available_scopes,
      newly_created_token: nil,
      tokens_sort_key: sort_key,
      tokens_sort_dir: sort_dir,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Account tokens"), "/" <> handle <> "/-/settings/tokens"}
      ]
    )
  end

  defp apply_action(socket, :api_tokens_new, _params) do
    require_admin!(socket)
    handle = socket.assigns.handle

    assign(socket,
      page_title: gettext("New account token"),
      available_scopes: available_scopes(),
      token_form:
        to_form(%{"name" => "", "description" => "", "scopes" => [], "expiration" => "90"},
          as: :token
        ),
      newly_created_token: nil,
      token_form_valid?: false,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Account tokens"), "/" <> handle <> "/-/settings/tokens"},
        {gettext("New token"), nil}
      ]
    )
  end

  defp apply_action(socket, :api_token_edit, params) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle
    token = DeveloperTokens.get_account_token!(params["token_id"], account.id)
    current_scopes = String.split(token.scope || "", " ", trim: true)

    assign(socket,
      page_title: token.name,
      editing_token: token,
      available_scopes: available_scopes(),
      token_edit_form:
        to_form(
          %{
            "name" => token.name,
            "description" => token.description || "",
            "scopes" => current_scopes
          },
          as: :token
        ),
      token_edit_changed?: false,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Account tokens"), "/" <> handle <> "/-/settings/tokens"},
        {token.name, nil}
      ]
    )
  end

  defp apply_action(socket, :api_apps, params) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle

    sort_key = Map.get(params, "asort", "name")
    sort_dir = Map.get(params, "adir", "asc")

    flop_params = %{
      "order_by" => [sort_key],
      "order_directions" => [sort_dir]
    }

    {:ok, {apps, _meta}} = DeveloperTokens.list_oauth_applications(account, flop_params)

    assign(socket,
      page_title: gettext("OAuth Apps"),
      oauth_apps: apps,
      newly_created_secret: nil,
      apps_sort_key: sort_key,
      apps_sort_dir: sort_dir,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("OAuth apps"), "/" <> handle <> "/-/settings/apps"}
      ]
    )
  end

  defp apply_action(socket, :api_apps_new, _params) do
    require_admin!(socket)
    handle = socket.assigns.handle

    assign(socket,
      page_title: gettext("New OAuth App"),
      app_form:
        to_form(%{"name" => "", "description" => "", "homepage_url" => "", "redirect_uris" => ""},
          as: :app
        ),
      app_form_valid?: false,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("OAuth apps"), "/" <> handle <> "/-/settings/apps"},
        {gettext("New application"), nil}
      ]
    )
  end

  defp apply_action(socket, :api_app_edit, %{"app_id" => app_id}) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle
    app = DeveloperTokens.get_oauth_application!(app_id, account.id)
    client = DeveloperTokens.get_boruta_client_for_app(app)

    redirect_uris = Enum.join(client.redirect_uris || [], "\n")

    assign(socket,
      page_title: app.name,
      oauth_app: app,
      boruta_client: client,
      app_form:
        to_form(
          %{
            "name" => app.name,
            "description" => app.description || "",
            "homepage_url" => app.homepage_url || "",
            "redirect_uris" => redirect_uris
          },
          as: :app
        ),
      app_edit_original: %{
        "name" => app.name,
        "description" => app.description || "",
        "homepage_url" => app.homepage_url || "",
        "redirect_uris" => redirect_uris
      },
      app_edit_changed?: false,
      newly_regenerated_secret: nil,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("OAuth apps"), "/" <> handle <> "/-/settings/apps"},
        {app.name, nil}
      ]
    )
  end

  defp apply_action(socket, :project_new, _params) do
    if not socket.assigns.can_write do
      socket
      |> put_flash(:error, gettext("You don't have permission to create projects here."))
      |> push_navigate(to: "/#{socket.assigns.handle}")
    else
      handle = socket.assigns.handle

      # Only fetch GitHub repos on initial load (not on every push_patch step change)
      if socket.assigns[:github_repos] do
        assign(socket,
          page_title: gettext("New project"),
          wizard_step: "repo",
          breadcrumb_items: [
            {gettext("New project"), "/" <> handle <> "/-/projects/new"}
          ]
        )
      else
        user = socket.assigns.current_user

        installations = Glossia.Github.Installations.list_installations_for_user(user)

        imported_repositories =
          Glossia.Projects.list_imported_github_repositories(socket.assigns.account)

        repos =
          if installations != [] && Glossia.Github.App.configured?() do
            installations
            |> Enum.flat_map(fn installation ->
              case fetch_github_repos_via_installation(installation) do
                {:ok, repos} -> repos
                {:error, _} -> []
              end
            end)
            |> Enum.uniq_by(& &1["id"])
            |> Enum.sort_by(& &1["full_name"])
          else
            case fetch_github_repos_via_oauth(user) do
              {:ok, repos} -> repos
              {:error, _} -> []
            end
          end
          |> filter_imported_repositories(imported_repositories)

        github_connected? =
          installations != [] || Glossia.Accounts.get_github_token_for_user(user.id) != nil

        assign(socket,
          page_title: gettext("New project"),
          github_installations: installations,
          github_repos: repos,
          github_repos_search: "",
          github_configured?: github_connected?,
          wizard_step: "repo",
          wizard_selected_repo: nil,
          wizard_selected_languages: [],
          wizard_project: nil,
          setup_events: [],
          breadcrumb_items: [
            {gettext("New project"), "/" <> handle <> "/-/projects/new"}
          ]
        )
      end
    end
  end

  @discussions_filter_types %{
    "status" => "select",
    "kind" => "select",
    "title" => "text",
    "inserted_at" => "date_range"
  }

  @translations_filter_types %{
    "status" => "select"
  }

  @wizard_languages [
    %{code: "es", name: "Spanish", native: "Espanol"},
    %{code: "fr", name: "French", native: "Francais"},
    %{code: "de", name: "German", native: "Deutsch"},
    %{code: "ja", name: "Japanese", native: "日本語"},
    %{code: "zh-Hans", name: "Chinese (Simplified)", native: "简体中文"},
    %{code: "ko", name: "Korean", native: "한국어"},
    %{code: "pt-BR", name: "Portuguese (Brazil)", native: "Portugues"},
    %{code: "it", name: "Italian", native: "Italiano"},
    %{code: "ru", name: "Russian", native: "Русский"},
    %{code: "ar", name: "Arabic", native: "العربية"},
    %{code: "nl", name: "Dutch", native: "Nederlands"},
    %{code: "pl", name: "Polish", native: "Polski"},
    %{code: "tr", name: "Turkish", native: "Turkce"},
    %{code: "sv", name: "Swedish", native: "Svenska"},
    %{code: "da", name: "Danish", native: "Dansk"},
    %{code: "fi", name: "Finnish", native: "Suomi"},
    %{code: "nb", name: "Norwegian", native: "Norsk"},
    %{code: "uk", name: "Ukrainian", native: "Українська"},
    %{code: "th", name: "Thai", native: "ไทย"},
    %{code: "vi", name: "Vietnamese", native: "Tieng Viet"},
    %{code: "id", name: "Indonesian", native: "Bahasa Indonesia"},
    %{code: "ms", name: "Malay", native: "Bahasa Melayu"},
    %{code: "hi", name: "Hindi", native: "हिन्दी"},
    %{code: "he", name: "Hebrew", native: "עברית"},
    %{code: "el", name: "Greek", native: "Ελληνικά"},
    %{code: "cs", name: "Czech", native: "Cestina"},
    %{code: "ro", name: "Romanian", native: "Romana"},
    %{code: "hu", name: "Hungarian", native: "Magyar"},
    %{code: "ca", name: "Catalan", native: "Catala"}
  ]

  defp apply_action(socket, :kits, _params) do
    require_action!(socket, :kit_read)
    account = socket.assigns.account
    handle = socket.assigns.handle

    {:ok, {kits, _meta}} = Kits.list_kits(account)

    assign(socket,
      page_title: gettext("Kits"),
      kits: kits,
      kits_sort_key: "inserted_at",
      kits_sort_dir: "desc",
      kits_active_filters: %{},
      breadcrumb_items: [{gettext("Kits"), "/" <> handle <> "/-/kits"}]
    )
  end

  defp apply_action(socket, :kit_new, _params) do
    require_action!(socket, :kit_write)
    handle = socket.assigns.handle

    assign(socket,
      page_title: gettext("New kit"),
      kit_form:
        to_form(
          %{
            "handle" => "",
            "name" => "",
            "description" => "",
            "source_language" => "en",
            "target_languages" => [],
            "domain_tags" => [],
            "visibility" => "public"
          },
          as: :kit
        ),
      kit_form_valid?: false,
      breadcrumb_items: [
        {gettext("Kits"), "/" <> handle <> "/-/kits"},
        {gettext("New kit"), nil}
      ]
    )
  end

  defp apply_action(socket, :kit_show, %{"kit_handle" => kit_handle}) do
    require_action!(socket, :kit_read)
    account = socket.assigns.account
    handle = socket.assigns.handle
    user = socket.assigns.current_user

    kit = Kits.get_kit_by_handle(account, kit_handle)

    unless kit do
      raise Ecto.NoResultsError, queryable: Glossia.Kits.Kit
    end

    starred? = if user, do: Kits.starred_by?(kit, user), else: false

    assign(socket,
      page_title: kit.name,
      kit: kit,
      kit_starred?: starred?,
      breadcrumb_items: [
        {gettext("Kits"), "/" <> handle <> "/-/kits"},
        {kit.name, nil}
      ]
    )
  end

  defp apply_action(socket, :kit_edit, %{"kit_handle" => kit_handle}) do
    require_action!(socket, :kit_write)
    account = socket.assigns.account
    handle = socket.assigns.handle

    kit = Kits.get_kit_by_handle(account, kit_handle)

    unless kit do
      raise Ecto.NoResultsError, queryable: Glossia.Kits.Kit
    end

    assign(socket,
      page_title: gettext("Edit %{name}", name: kit.name),
      kit: kit,
      kit_form:
        to_form(
          %{
            "handle" => kit.handle,
            "name" => kit.name,
            "description" => kit.description || "",
            "source_language" => kit.source_language,
            "target_languages" => kit.target_languages,
            "domain_tags" => kit.domain_tags,
            "visibility" => kit.visibility
          },
          as: :kit
        ),
      kit_form_valid?: true,
      kit_edit_changed?: false,
      breadcrumb_items: [
        {gettext("Kits"), "/" <> handle <> "/-/kits"},
        {kit.name, "/" <> handle <> "/-/kits/" <> kit.handle},
        {gettext("Edit"), nil}
      ]
    )
  end

  defp apply_action(socket, :kit_term_new, %{"kit_handle" => kit_handle}) do
    require_action!(socket, :kit_write)
    account = socket.assigns.account
    handle = socket.assigns.handle

    kit = Kits.get_kit_by_handle(account, kit_handle)

    unless kit do
      raise Ecto.NoResultsError, queryable: Glossia.Kits.Kit
    end

    assign(socket,
      page_title: gettext("New term"),
      kit: kit,
      term_form:
        to_form(
          %{
            "source_term" => "",
            "definition" => "",
            "tags" => [],
            "translations" =>
              Enum.map(kit.target_languages, fn lang ->
                %{"language" => lang, "translated_term" => "", "usage_note" => ""}
              end)
          },
          as: :term
        ),
      term_form_valid?: false,
      breadcrumb_items: [
        {gettext("Kits"), "/" <> handle <> "/-/kits"},
        {kit.name, "/" <> handle <> "/-/kits/" <> kit.handle},
        {gettext("New term"), nil}
      ]
    )
  end

  defp apply_action(socket, :kit_term_edit, %{"kit_handle" => kit_handle, "term_id" => term_id}) do
    require_action!(socket, :kit_write)
    account = socket.assigns.account
    handle = socket.assigns.handle

    kit = Kits.get_kit_by_handle(account, kit_handle)

    unless kit do
      raise Ecto.NoResultsError, queryable: Glossia.Kits.Kit
    end

    term = Kits.get_term!(term_id)

    existing_translations =
      Enum.map(term.translations, fn t ->
        %{
          "language" => t.language,
          "translated_term" => t.translated_term,
          "usage_note" => t.usage_note || ""
        }
      end)

    missing_langs = kit.target_languages -- Enum.map(term.translations, & &1.language)

    all_translations =
      existing_translations ++
        Enum.map(missing_langs, fn lang ->
          %{"language" => lang, "translated_term" => "", "usage_note" => ""}
        end)

    assign(socket,
      page_title: term.source_term,
      kit: kit,
      term: term,
      term_form:
        to_form(
          %{
            "source_term" => term.source_term,
            "definition" => term.definition || "",
            "tags" => term.tags,
            "translations" => all_translations
          },
          as: :term
        ),
      term_form_valid?: true,
      term_edit_changed?: false,
      breadcrumb_items: [
        {gettext("Kits"), "/" <> handle <> "/-/kits"},
        {kit.name, "/" <> handle <> "/-/kits/" <> kit.handle},
        {term.source_term, nil}
      ]
    )
  end

  defp apply_action(socket, :discussions, params) do
    account = socket.assigns.account

    sort_key = Map.get(params, "ksort", "inserted_at")
    sort_dir = Map.get(params, "kdir", "desc")
    active_filters = extract_filters(params, "k")

    flop_params =
      %{
        "order_by" => [sort_key],
        "order_directions" => [sort_dir]
      }
      |> maybe_add_flop_filters(active_filters, @discussions_filter_types)

    {:ok, {tickets, _meta}} = Discussions.list_discussions(account, flop_params)

    assign(socket,
      page_title: gettext("Discussions"),
      tickets: tickets,
      discussions_sort_key: sort_key,
      discussions_sort_dir: sort_dir,
      discussions_active_filters: active_filters,
      breadcrumb_items: [
        {gettext("Discussions"), "/" <> socket.assigns.handle <> "/-/discussions"}
      ]
    )
  end

  defp apply_action(socket, :discussion_new, _params) do
    handle = socket.assigns.handle

    socket
    |> maybe_allow_upload(:ticket_images)
    |> assign(
      page_title: gettext("New discussion"),
      ticket_form: to_form(%{"title" => "", "body" => ""}, as: :ticket),
      generating_title?: false,
      title_manually_edited?: false,
      ticket_title_generation: 0,
      ticket_title_timer_ref: nil,
      ticket_title_task_ref: nil,
      upload_context_id: Uniq.UUID.uuid7(),
      breadcrumb_items: [
        {gettext("Discussions"), "/" <> handle <> "/-/discussions"},
        {gettext("New discussion"), nil}
      ]
    )
  end

  defp apply_action(socket, :discussion_show, params) do
    account = socket.assigns.account
    handle = socket.assigns.handle
    number_str = Map.get(params, "discussion_number") || Map.get(params, "ticket_number")
    ticket = Discussions.get_discussion_by_number!(String.to_integer(number_str), account.id)

    socket
    |> maybe_allow_upload(:comment_images)
    |> assign(
      page_title: ticket.title,
      ticket: ticket,
      comment_form: to_form(%{"body" => ""}, as: :comment),
      breadcrumb_items: [
        {gettext("Discussions"), "/" <> handle <> "/-/discussions"},
        {"##{ticket.number}", nil}
      ]
    )
  end

  defp apply_action(socket, :project, %{"project" => project_handle}) do
    account = socket.assigns.account
    project = Glossia.Projects.get_project(account, project_handle)

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    og_image_url =
      if account.visibility == "public" do
        og_attrs = %{
          title: project.name,
          description: socket.assigns.handle <> "/" <> project.handle,
          category: "project"
        }

        Glossia.OgImage.project_url(socket.assigns.handle, project.handle, og_attrs)
      end

    setup_events = Glossia.Ingestion.list_setup_events(project.id)

    socket =
      if connected?(socket) and project.setup_status in ["pending", "running"] do
        Glossia.Projects.subscribe_setup_events(project)
        socket
      else
        socket
      end

    assign(socket,
      page_title: project.name,
      project: project,
      project_name: project.name,
      og_image_url: og_image_url,
      breadcrumb_items: [
        {project.handle, "/" <> socket.assigns.handle <> "/" <> project.handle},
        {gettext("Overview"), nil}
      ],
      setup_events: setup_events,
      sidebar_context: :project,
      sidebar_project: project
    )
  end

  defp apply_action(socket, :project_settings, %{"project" => project_handle}) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle
    project = Glossia.Projects.get_project(account, project_handle)

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    form =
      to_form(
        %{
          "name" => project.name || "",
          "description" => project.description || "",
          "url" => project.url || ""
        },
        as: :project
      )

    socket =
      cond do
        not connected?(socket) ->
          socket

        Map.has_key?(socket.assigns, :uploads) and
            Map.has_key?(socket.assigns.uploads, :project_avatar) ->
          socket

        true ->
          allow_upload(socket, :project_avatar,
            accept: ~w(.jpg .jpeg .png .gif .webp),
            max_entries: 1,
            max_file_size: 5_000_000
          )
      end

    assign(socket,
      page_title: gettext("Settings"),
      project: project,
      project_settings_form: form,
      project_settings_changed?: false,
      project_avatar_url: project_avatar_display_url(project.avatar_url),
      breadcrumb_items: [
        {project.handle, "/" <> handle <> "/" <> project.handle},
        {gettext("Settings"), nil}
      ],
      sidebar_context: :project,
      sidebar_project: project
    )
  end

  defp apply_action(socket, :project_activity, %{"project" => project_handle}) do
    account = socket.assigns.account
    handle = socket.assigns.handle
    project = Glossia.Projects.get_project(account, project_handle)

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    # Only fetch commits from GitHub on first load (not on push_patch for search)
    {all_commits, commits_error} =
      if Map.has_key?(socket.assigns, :all_commits) do
        {socket.assigns.all_commits, socket.assigns[:commits_error]}
      else
        fetch_project_commits(project)
      end

    sessions_by_sha = Glossia.TranslationSessions.sessions_by_commit_sha(project)

    assign(socket,
      page_title: gettext("Activity"),
      project: project,
      all_commits: all_commits,
      commits: all_commits,
      commits_search: "",
      commits_sort_key: "date",
      commits_sort_dir: "desc",
      commits_error: commits_error,
      sessions_by_sha: sessions_by_sha,
      breadcrumb_items: [
        {project.handle, "/" <> handle <> "/" <> project.handle},
        {gettext("Activity"), nil}
      ],
      sidebar_context: :project,
      sidebar_project: project
    )
  end

  defp apply_action(socket, :project_session, %{
         "project" => project_handle,
         "session_id" => session_id
       }) do
    account = socket.assigns.account
    handle = socket.assigns.handle
    project = Glossia.Projects.get_project(account, project_handle)

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    session = Glossia.TranslationSessions.get_session!(session_id)
    events = Glossia.Ingestion.list_translation_session_events(session.id)

    socket =
      if connected?(socket) and session.status in ["pending", "running"] do
        Glossia.TranslationSessions.subscribe_session_events(session)
        socket
      else
        socket
      end

    assign(socket,
      page_title: gettext("Translation session"),
      project: project,
      session: session,
      session_events: events,
      breadcrumb_items: [
        {project.handle, "/" <> handle <> "/" <> project.handle},
        {gettext("Translations"), "/" <> handle <> "/" <> project.handle <> "/-/translations"},
        {gettext("Session"), nil}
      ],
      sidebar_context: :project,
      sidebar_project: project
    )
  end

  defp apply_action(socket, :project_translations, %{"project" => project_handle}) do
    account = socket.assigns.account
    handle = socket.assigns.handle
    project = Glossia.Projects.get_project(account, project_handle)

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    assign(socket,
      page_title: gettext("Translations"),
      project: project,
      breadcrumb_items: [
        {project.handle, "/" <> handle <> "/" <> project.handle},
        {gettext("Translations"), nil}
      ],
      sidebar_context: :project,
      sidebar_project: project
    )
  end

  defp fetch_project_commits(project) do
    if project.github_installation_id && project.github_repo_full_name do
      installation =
        Glossia.Repo.preload(project, :github_installation).github_installation

      case Glossia.Github.App.installation_token(installation.github_installation_id) do
        {:ok, token} ->
          case Glossia.Github.Client.list_commits(project.github_repo_full_name, token,
                 per_page: 30
               ) do
            {:ok, raw_commits} when is_list(raw_commits) ->
              {Enum.map(raw_commits, &normalize_commit(&1, project.github_repo_full_name)), nil}

            {:error, _reason} ->
              if Application.get_env(:glossia, :dev_routes) do
                {sample_commits(project.github_repo_full_name), nil}
              else
                {[], gettext("Could not load commits from GitHub.")}
              end
          end

        {:error, _reason} ->
          if Application.get_env(:glossia, :dev_routes) do
            {sample_commits(project.github_repo_full_name), nil}
          else
            {[], gettext("Could not load commits from GitHub.")}
          end
      end
    else
      {[], nil}
    end
  end

  defp normalize_commit(raw, repo_full_name) do
    commit = raw["commit"] || %{}
    author = raw["author"] || commit["author"] || %{}

    %{
      sha: raw["sha"] || "",
      short_sha: String.slice(raw["sha"] || "", 0, 7),
      message: commit["message"] || "",
      author_name: author["login"] || get_in(commit, ["author", "name"]) || "",
      author_avatar_url: author["avatar_url"],
      date: parse_commit_date(get_in(commit, ["author", "date"])),
      url: "https://github.com/#{repo_full_name}/commit/#{raw["sha"]}"
    }
  end

  defp parse_commit_date(nil), do: nil

  defp parse_commit_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp sample_commits(repo_full_name) do
    now = DateTime.utc_now()

    messages = [
      {"feat: add multilingual content support for blog posts",
       "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0", -1200},
      {"fix: resolve encoding issue with Japanese characters",
       "b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1", -3600},
      {"chore: update translation glossary for Spanish locale",
       "c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2", -7200},
      {"feat: implement automatic language detection on upload",
       "d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3", -14400},
      {"fix: correct RTL layout for Arabic content pages",
       "e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4", -28800},
      {"docs: add contributing guide for translators", "f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5",
       -86400},
      {"feat: add voice consistency checks to CI pipeline",
       "a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6", -172_800},
      {"refactor: extract content parser into dedicated module",
       "b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7", -259_200},
      {"fix: handle empty frontmatter in markdown files",
       "c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8", -345_600},
      {"feat: support .mdx files in content directory",
       "d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9", -432_000}
    ]

    authors = [
      {"pepicrft", "https://avatars.githubusercontent.com/u/663605?v=4"},
      {"alexchen", nil},
      {"mariarossi", nil}
    ]

    Enum.map(messages, fn {message, sha, offset_seconds} ->
      {author_login, avatar_url} = Enum.random(authors)

      %{
        sha: sha,
        short_sha: String.slice(sha, 0, 7),
        message: message,
        author_name: author_login,
        author_avatar_url: avatar_url,
        date: DateTime.add(now, offset_seconds, :second),
        url: "https://github.com/#{repo_full_name}/commit/#{sha}"
      }
    end)
  end

  defp require_admin!(socket) do
    unless socket.assigns.is_admin do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end
  end

  defp require_write!(socket) do
    unless socket.assigns.can_write do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end
  end

  defp require_action!(socket, action) do
    user = socket.assigns.current_user
    account = socket.assigns.account

    unless Glossia.Policy.authorize?(action, user, account) do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end
  end

  defp available_scopes do
    Glossia.Policy.list_rules()
    |> Enum.map(&"#{&1.object}:#{&1.action}")
    |> Enum.uniq()
    |> Enum.sort()
  end

  @acronyms ~w(api)

  defp humanize_scope_group(group) do
    group
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", fn word ->
      if String.downcase(word) in @acronyms,
        do: String.upcase(word),
        else: String.capitalize(word)
    end)
  end

  defp humanize_scope_action(scope) do
    case String.split(scope, ":") do
      [_object, action] ->
        action
        |> String.replace("_", " ")
        |> String.split(" ")
        |> Enum.map_join(" ", &String.capitalize/1)

      _ ->
        scope
    end
  end

  defp humanize_scope(scope) do
    case String.split(scope, ":") do
      [object, action] ->
        humanize_scope_group(object) <> " " <> String.capitalize(action)

      _ ->
        scope
    end
  end

  # ---------------------------------------------------------------------------
  # Voice form events
  # ---------------------------------------------------------------------------

  def handle_event("validate", params, socket) do
    if not (socket.assigns[:can_voice_submit?] || false) do
      {:noreply, socket}
    else
      # Merge country context edits from form params into assign
      cultural_notes =
        case params["cultural_notes"] do
          ctx when is_map(ctx) ->
            Map.merge(socket.assigns.cultural_notes, ctx)

          _ ->
            socket.assigns.cultural_notes
        end

      socket = assign(socket, cultural_notes: cultural_notes)

      base_changed? =
        form_changed?(params, socket.assigns.original_voice, socket.assigns.original_overrides)

      countries_changed? =
        voice_countries_changed?(
          socket.assigns.target_countries,
          cultural_notes,
          socket.assigns.original_voice
        )

      changed? = base_changed? or countries_changed?
      socket = assign(socket, changed?: changed?, voice_form_params: params)

      old_desc =
        if socket.assigns.original_voice,
          do: socket.assigns.original_voice.description || "",
          else: ""

      new_desc = params["description"] || ""

      socket =
        if new_desc != old_desc and String.length(new_desc) >= 20 and
             socket.assigns.target_countries != [] do
          schedule_context_generation(socket)
        else
          socket
        end

      socket =
        if changed? do
          schedule_summary_generation(socket, :voice)
        else
          cancel_summary_generation(socket)
        end

      {:noreply, socket}
    end
  end

  def handle_event("save_voice", params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    can_write = socket.assigns[:can_voice_write] || false
    can_propose = socket.assigns[:can_voice_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    cond do
      can_discussion_write and (can_propose or can_write) ->
        begin_voice_suggestion(params, socket)

      true ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    end
  end

  def handle_event("create_voice_suggestion", params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    suggestion_title_text = suggestion_text_param(params, "suggestion_title", "request_title")
    suggestion_body_text = suggestion_text_param(params, "suggestion_body", "request_body")

    cond do
      is_nil(user) or not Glossia.Policy.authorize?(:discussion_write, user, account) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      not ((socket.assigns[:can_voice_propose] || false) or
               (socket.assigns[:can_voice_write] || false)) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      suggestion_title_text == "" ->
        {:noreply, put_flash(socket, :error, gettext("A suggestion title is required."))}

      suggestion_body_text == "" ->
        {:noreply, put_flash(socket, :error, gettext("A suggestion description is required."))}

      true ->
        submit_voice_suggestion(params, socket)
    end
  end

  def handle_event("discard_changes", _params, socket) do
    socket = cancel_summary_generation(socket)
    voice = socket.assigns.original_voice
    target_countries = if voice, do: voice.target_countries || [], else: []
    cultural_notes = if voice, do: voice.cultural_notes || %{}, else: %{}

    {:noreply,
     assign(socket,
       overrides: socket.assigns.original_overrides,
       target_countries: target_countries,
       cultural_notes: cultural_notes,
       changed?: false,
       change_summary: "",
       generating_summary?: false,
       generating_contexts?: false
     )}
  end

  def handle_event("add_override", _params, socket) do
    if socket.assigns[:can_voice_submit?] || false do
      new_override = %{
        locale: "",
        tone: nil,
        formality: nil,
        target_audience: nil,
        guidelines: nil
      }

      overrides = socket.assigns.overrides ++ [new_override]
      {:noreply, assign(socket, overrides: overrides, changed?: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_override", %{"index" => idx_str}, socket) do
    if socket.assigns[:can_voice_submit?] || false do
      idx = String.to_integer(idx_str)
      overrides = List.delete_at(socket.assigns.overrides, idx)
      changed? = form_changed_overrides?(overrides, socket.assigns.original_overrides)
      {:noreply, assign(socket, overrides: overrides, changed?: changed?)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_country", %{"code" => code}, socket) do
    if not (socket.assigns[:can_voice_submit?] || false) do
      {:noreply, socket}
    else
      countries = socket.assigns.target_countries

      unless code in countries do
        new_countries = countries ++ [code]

        socket =
          socket
          |> assign(target_countries: new_countries, changed?: true)
          |> push_event("update_country_exclude", %{exclude: new_countries})
          |> schedule_summary_generation(:voice)
          |> maybe_schedule_context_generation(code)

        {:noreply, socket}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_event("remove_country", %{"code" => code}, socket) do
    if socket.assigns[:can_voice_submit?] || false do
      new_countries = List.delete(socket.assigns.target_countries, code)
      new_contexts = Map.delete(socket.assigns.cultural_notes, code)

      changed? =
        voice_countries_changed?(
          new_countries,
          new_contexts,
          socket.assigns.original_voice
        )

      socket =
        socket
        |> assign(
          target_countries: new_countries,
          cultural_notes: new_contexts,
          changed?: changed?
        )
        |> push_event("update_country_exclude", %{exclude: new_countries})
        |> schedule_summary_generation(:voice)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Glossary events
  # ---------------------------------------------------------------------------

  def handle_event("save_glossary", params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    can_write = socket.assigns[:can_glossary_write] || false
    can_propose = socket.assigns[:can_glossary_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    cond do
      can_discussion_write and (can_propose or can_write) ->
        begin_glossary_suggestion(params, socket)

      true ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    end
  end

  def handle_event("create_glossary_suggestion", params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    suggestion_title_text = suggestion_text_param(params, "suggestion_title", "request_title")
    suggestion_body_text = suggestion_text_param(params, "suggestion_body", "request_body")
    change_note = glossary_suggestion_change_note(params, socket)

    cond do
      is_nil(user) or not Glossia.Policy.authorize?(:discussion_write, user, account) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      not ((socket.assigns[:can_glossary_propose] || false) or
               (socket.assigns[:can_glossary_write] || false)) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      suggestion_title_text == "" ->
        {:noreply, put_flash(socket, :error, gettext("A suggestion title is required."))}

      suggestion_body_text == "" ->
        {:noreply, put_flash(socket, :error, gettext("A suggestion description is required."))}

      true ->
        submit_glossary_suggestion(params, change_note, socket)
    end
  end

  def handle_event("glossary_validate", params, socket) do
    if not (socket.assigns[:can_glossary_submit?] || false) do
      {:noreply, socket}
    else
      entries = parse_glossary_entries_from_params(params, socket.assigns.glossary_entries)

      socket =
        socket
        |> assign(
          glossary_entries: entries,
          glossary_changed?: true,
          glossary_form_params: params
        )
        |> schedule_summary_generation(:glossary)

      {:noreply, socket}
    end
  end

  def handle_event("glossary_discard", _params, socket) do
    socket = cancel_summary_generation(socket)

    {:noreply,
     assign(socket,
       glossary_entries: socket.assigns.original_glossary_entries,
       glossary_changed?: false,
       glossary_form_params: %{},
       change_summary: "",
       generating_summary?: false
     )}
  end

  def handle_event("add_glossary_entry", _params, socket) do
    if socket.assigns[:can_glossary_submit?] || false do
      new_entry = %{term: "", definition: nil, case_sensitive: false, translations: []}
      entries = socket.assigns.glossary_entries ++ [new_entry]
      {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_glossary_entry", %{"index" => idx_str}, socket) do
    if socket.assigns[:can_glossary_submit?] || false do
      idx = String.to_integer(idx_str)
      entries = List.delete_at(socket.assigns.glossary_entries, idx)
      {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "add_glossary_translation",
        %{"entry-index" => entry_idx_str},
        socket
      ) do
    if socket.assigns[:can_glossary_submit?] || false do
      entry_idx = String.to_integer(entry_idx_str)
      entries = socket.assigns.glossary_entries

      entry = Enum.at(entries, entry_idx)
      translations = (entry.translations || []) ++ [%{locale: "", translation: ""}]
      updated_entry = Map.put(entry, :translations, translations)
      entries = List.replace_at(entries, entry_idx, updated_entry)

      {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "remove_glossary_translation",
        %{"entry-index" => entry_idx_str, "translation-index" => t_idx_str},
        socket
      ) do
    if socket.assigns[:can_glossary_submit?] || false do
      entry_idx = String.to_integer(entry_idx_str)
      t_idx = String.to_integer(t_idx_str)
      entries = socket.assigns.glossary_entries

      entry = Enum.at(entries, entry_idx)
      translations = List.delete_at(entry.translations, t_idx)
      updated_entry = Map.put(entry, :translations, translations)
      entries = List.replace_at(entries, entry_idx, updated_entry)

      {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
    else
      {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Resource table events (search, sort, filter, page)
  # All events push URL params via push_patch; handle_params restores state.
  # ---------------------------------------------------------------------------

  def handle_event("resource_search", %{"search" => q, "table_id" => table_id}, socket) do
    {:noreply, push_table_params(socket, table_id, %{search: q, page: 1})}
  end

  def handle_event("resource_sort", %{"key" => key, "table_id" => table_id}, socket) do
    {cur_key, cur_dir} = current_sort(socket, table_id)

    dir =
      if cur_key == key && cur_dir == "asc",
        do: "desc",
        else: "asc"

    {:noreply, push_table_params(socket, table_id, %{sort: key, dir: dir})}
  end

  def handle_event(
        "resource_filter",
        %{"key" => _key, "value" => "", "table_id" => _table_id},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event("resource_filter", %{"key" => key, "value" => val, "table_id" => tid}, socket) do
    filters = current_filters(socket, tid)
    existing = Map.get(filters, key, [])

    updated = if val in existing, do: existing, else: existing ++ [val]
    filters = Map.put(filters, key, updated)

    {:noreply, push_table_params(socket, tid, %{filters: filters, page: 1})}
  end

  def handle_event(
        "resource_remove_filter",
        %{"key" => key, "filter_value" => val, "table_id" => tid},
        socket
      ) do
    filters = current_filters(socket, tid)
    existing = Map.get(filters, key, [])
    updated = List.delete(existing, val)

    filters =
      if updated == [],
        do: Map.delete(filters, key),
        else: Map.put(filters, key, updated)

    {:noreply, push_table_params(socket, tid, %{filters: filters, page: 1})}
  end

  def handle_event(
        "resource_filter_text",
        %{"key" => key, "value" => val, "table_id" => tid},
        socket
      ) do
    filters = current_filters(socket, tid)

    filters =
      if val == "",
        do: Map.delete(filters, key),
        else: Map.put(filters, key, [val])

    {:noreply, push_table_params(socket, tid, %{filters: filters, page: 1})}
  end

  def handle_event(
        "resource_filter_date_range",
        %{"key" => key, "from" => from, "to" => to, "table_id" => tid},
        socket
      ) do
    filters = current_filters(socket, tid)

    filters =
      if from == "" and to == "" do
        Map.delete(filters, key)
      else
        range = "#{from}..#{to}"
        Map.put(filters, key, [range])
      end

    {:noreply, push_table_params(socket, tid, %{filters: filters, page: 1})}
  end

  def handle_event("resource_clear_filters", %{"table_id" => table_id}, socket) do
    {:noreply, push_table_params(socket, table_id, %{filters: %{}, page: 1})}
  end

  def handle_event("resource_page", %{"page" => page, "table_id" => table_id}, socket) do
    {:noreply, push_table_params(socket, table_id, %{page: String.to_integer(page)})}
  end

  # ---------------------------------------------------------------------------
  # Members events
  # ---------------------------------------------------------------------------

  def handle_event("send_invitation", %{"invite" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      org = socket.assigns.organization
      user = socket.assigns.current_user

      case Organizations.create_invitation(org, user, params) do
        {:ok, invitation} ->
          Auditing.record("member.invited", socket.assigns.account, user,
            resource_type: "invitation",
            resource_id: to_string(invitation.id),
            resource_path: "/#{socket.assigns.handle}/-/members",
            summary: "Invited #{invitation.email} as #{invitation.role}"
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Invitation sent to %{email}.", email: params["email"]))
           |> assign(
             all_invitations: Organizations.list_pending_invitations(org),
             invite_form: to_form(%{"email" => "", "role" => "member"}, as: :invite)
           )
           |> apply_invitations_filters()}

        {:error, :already_member} ->
          {:noreply, put_flash(socket, :error, gettext("This user is already a member."))}

        {:error, :already_invited} ->
          {:noreply,
           put_flash(socket, :error, gettext("An invitation is already pending for this email."))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not send invitation."))}
      end
    end
  end

  def handle_event("revoke_invitation", %{"id" => invitation_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      org = socket.assigns.organization
      user = socket.assigns.current_user

      case Organizations.get_invitation(org, invitation_id) do
        nil ->
          {:noreply, put_flash(socket, :error, gettext("Invitation not found."))}

        invitation ->
          case Organizations.revoke_invitation(invitation) do
            {:ok, _} ->
              Auditing.record("member.invitation_revoked", socket.assigns.account, user,
                resource_type: "invitation",
                resource_id: to_string(invitation.id),
                resource_path: "/#{socket.assigns.handle}/-/members",
                summary: "Revoked invitation for #{invitation.email}"
              )

              {:noreply,
               socket
               |> assign(all_invitations: Organizations.list_pending_invitations(org))
               |> apply_invitations_filters()
               |> put_flash(:info, gettext("Invitation revoked."))}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, gettext("Could not revoke invitation."))}
          end
      end
    end
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      org = socket.assigns.organization
      current_user = socket.assigns.current_user

      case Accounts.get_user(user_id) do
        nil ->
          {:noreply, put_flash(socket, :error, gettext("User not found."))}

        target_user ->
          cond do
            current_user && target_user.id == current_user.id ->
              {:noreply, put_flash(socket, :error, gettext("You can't remove yourself."))}

            is_nil(Organizations.get_membership(org, target_user)) ->
              {:noreply, put_flash(socket, :error, gettext("User is not a member."))}

            Organizations.sole_admin?(org, target_user) ->
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 gettext("Cannot remove the only admin of the organization.")
               )}

            true ->
              Organizations.remove_member(org, target_user)

              Auditing.record("member.removed", socket.assigns.account, current_user,
                resource_type: "member",
                resource_id: to_string(target_user.id),
                resource_path: "/#{socket.assigns.handle}/-/members",
                summary: "Removed #{target_user.email} from the organization"
              )

              all_members = Organizations.list_members(org)
              member_roles = all_members |> Enum.map(& &1.role) |> Enum.uniq() |> Enum.sort()

              {:noreply,
               socket
               |> assign(all_members: all_members, member_roles: member_roles)
               |> apply_members_filters()
               |> put_flash(:info, gettext("Member removed."))}
          end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # API Token events
  # ---------------------------------------------------------------------------

  def handle_event("validate_token", %{"token" => params}, socket) do
    valid? = String.trim(params["name"] || "") != ""
    {:noreply, assign(socket, token_form_valid?: valid?)}
  end

  def handle_event("validate_token_edit", %{"token" => params}, socket) do
    token = socket.assigns.editing_token
    name_changed = String.trim(params["name"] || "") != (token.name || "")
    desc_changed = String.trim(params["description"] || "") != (token.description || "")

    original_scopes = String.split(token.scope || "", " ", trim: true) |> Enum.sort()
    new_scopes = List.wrap(params["scopes"]) |> Enum.sort()
    scopes_changed = original_scopes != new_scopes

    changed? = name_changed or desc_changed or scopes_changed

    form =
      to_form(
        %{
          "name" => params["name"] || "",
          "description" => params["description"] || "",
          "scopes" => List.wrap(params["scopes"])
        },
        as: :token
      )

    {:noreply, assign(socket, token_edit_changed?: changed?, token_edit_form: form)}
  end

  def handle_event("update_token", %{"token" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      token = socket.assigns.editing_token
      account = socket.assigns.account
      user = socket.assigns.current_user

      new_scopes = List.wrap(params["scopes"]) |> Enum.join(" ")

      attrs = %{
        "name" => params["name"],
        "description" => params["description"],
        "scope" => new_scopes
      }

      case DeveloperTokens.update_account_token(token, attrs) do
        {:ok, updated_token} ->
          Auditing.record("token.updated", account, user,
            resource_type: "account_token",
            resource_id: to_string(updated_token.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/tokens/#{updated_token.id}",
            summary: "Updated account token \"#{updated_token.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Token updated."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/settings/tokens")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not update token."))}
      end
    end
  end

  def handle_event("create_token", %{"token" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user

      scopes = params["scopes"] || []
      scope_string = Enum.join(scopes, " ")

      expires_at =
        case params["expiration"] do
          "30" -> DateTime.add(DateTime.utc_now(), 30, :day)
          "60" -> DateTime.add(DateTime.utc_now(), 60, :day)
          "90" -> DateTime.add(DateTime.utc_now(), 90, :day)
          "never" -> nil
          _ -> DateTime.add(DateTime.utc_now(), 90, :day)
        end

      attrs = %{
        "name" => params["name"],
        "description" => params["description"],
        "scope" => scope_string,
        "expires_at" => expires_at
      }

      case DeveloperTokens.create_account_token(account, user, attrs) do
        {:ok, %{token: token, plain_token: plain_token}} ->
          Auditing.record("token.created", account, user,
            resource_type: "account_token",
            resource_id: to_string(token.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/tokens",
            summary: "Created account token \"#{token.name}\""
          )

          {:ok, {tokens, _meta}} = DeveloperTokens.list_account_tokens(account)

          {:noreply,
           socket
           |> assign(api_tokens: tokens, newly_created_token: plain_token)
           |> push_patch(to: "/#{socket.assigns.handle}/api/tokens")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not create token."))}
      end
    end
  end

  def handle_event("revoke_token", %{"id" => token_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user

      case DeveloperTokens.revoke_account_token(token_id, account.id) do
        {:ok, token} ->
          Auditing.record("token.revoked", account, user,
            resource_type: "account_token",
            resource_id: to_string(token.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/tokens",
            summary: "Revoked account token \"#{token.name}\""
          )

          {:ok, {tokens, _meta}} = DeveloperTokens.list_account_tokens(account)

          {:noreply,
           socket
           |> assign(api_tokens: tokens)
           |> put_flash(:info, gettext("Token revoked."))
           |> push_patch(to: "/#{socket.assigns.handle}/api/tokens")}

        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, gettext("Token not found."))}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # OAuth App events
  # ---------------------------------------------------------------------------

  def handle_event("validate_oauth_app", %{"app" => params}, socket) do
    valid? =
      String.trim(params["name"] || "") != "" and
        String.trim(params["redirect_uris"] || "") != ""

    {:noreply, assign(socket, app_form_valid?: valid?)}
  end

  def handle_event("validate_oauth_app_edit", %{"app" => params}, socket) do
    original = socket.assigns.app_edit_original

    changed? =
      String.trim(params["name"] || "") != String.trim(original["name"] || "") or
        String.trim(params["description"] || "") != String.trim(original["description"] || "") or
        String.trim(params["homepage_url"] || "") != String.trim(original["homepage_url"] || "") or
        String.trim(params["redirect_uris"] || "") != String.trim(original["redirect_uris"] || "")

    {:noreply, assign(socket, app_edit_changed?: changed?)}
  end

  def handle_event("create_oauth_app", %{"app" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user

      case DeveloperTokens.create_oauth_application(account, user, params) do
        {:ok, %{app: app, client_id: client_id, client_secret: client_secret}} ->
          Auditing.record("oauth_app.created", account, user,
            resource_type: "oauth_application",
            resource_id: to_string(app.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/apps/#{app.id}",
            summary: "Created OAuth application \"#{app.name}\""
          )

          {:ok, {apps, _meta}} = DeveloperTokens.list_oauth_applications(account)

          {:noreply,
           socket
           |> assign(
             oauth_apps: apps,
             newly_created_secret: %{client_id: client_id, client_secret: client_secret}
           )
           |> push_patch(to: "/#{socket.assigns.handle}/api/apps")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not create application."))}
      end
    end
  end

  def handle_event("update_oauth_app", %{"app" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      app = socket.assigns.oauth_app
      account = socket.assigns.account
      user = socket.assigns.current_user

      case DeveloperTokens.update_oauth_application(app, params) do
        {:ok, updated_app} ->
          Auditing.record("oauth_app.updated", account, user,
            resource_type: "oauth_application",
            resource_id: to_string(app.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/apps/#{app.id}",
            summary: "Updated OAuth application \"#{updated_app.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Application updated."))
           |> push_patch(to: "/#{socket.assigns.handle}/api/apps/#{app.id}")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not update application."))}
      end
    end
  end

  def handle_event("regenerate_secret", %{"id" => app_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user
      app = DeveloperTokens.get_oauth_application!(app_id, account.id)

      case DeveloperTokens.regenerate_oauth_application_secret(app) do
        {:ok, %{client_secret: secret}} ->
          Auditing.record("oauth_app.secret_regenerated", account, user,
            resource_type: "oauth_application",
            resource_id: to_string(app.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/apps/#{app.id}",
            summary: "Regenerated client secret for \"#{app.name}\""
          )

          {:noreply,
           socket
           |> assign(newly_regenerated_secret: secret)
           |> put_flash(:info, gettext("Client secret regenerated."))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not regenerate secret."))}
      end
    end
  end

  def handle_event("delete_oauth_app", %{"id" => app_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user
      app = DeveloperTokens.get_oauth_application!(app_id, account.id)

      case DeveloperTokens.delete_oauth_application(app) do
        :ok ->
          Auditing.record("oauth_app.deleted", account, user,
            resource_type: "oauth_application",
            resource_id: to_string(app.id),
            resource_path: "/#{socket.assigns.handle}/-/settings/apps",
            summary: "Deleted OAuth application \"#{app.name}\""
          )

          {:ok, {apps, _meta}} = DeveloperTokens.list_oauth_applications(account)

          {:noreply,
           socket
           |> assign(oauth_apps: apps)
           |> put_flash(:info, gettext("Application deleted."))
           |> push_patch(to: "/#{socket.assigns.handle}/api/apps")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not delete application."))}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Kit events
  # ---------------------------------------------------------------------------

  def handle_event("kit_validate", %{"kit" => params}, socket) do
    valid? =
      (params["handle"] || "") != "" and
        (params["name"] || "") != "" and
        (params["source_language"] || "") != ""

    changed? =
      case socket.assigns[:kit] do
        nil ->
          false

        kit ->
          params["handle"] != kit.handle or
            params["name"] != kit.name or
            (params["description"] || "") != (kit.description || "") or
            params["source_language"] != kit.source_language or
            params["visibility"] != kit.visibility
      end

    {:noreply,
     assign(socket,
       kit_form: to_form(params, as: :kit),
       kit_form_valid?: valid?,
       kit_edit_changed?: changed?
     )}
  end

  def handle_event("create_kit", %{"kit" => params}, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user

    unless Glossia.Policy.authorize?(:kit_write, user, account) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      case Kits.create_kit(account, user, params) do
        {:ok, kit} ->
          Auditing.record("kit.created", account, user,
            resource_type: "kit",
            resource_id: to_string(kit.id),
            resource_path: "/#{socket.assigns.handle}/-/kits/#{kit.handle}",
            summary: "Created kit \"#{kit.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Kit created."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/kits/#{kit.handle}")}

        {:error, changeset} ->
          {:noreply, assign(socket, kit_form: to_form(changeset, as: :kit))}
      end
    end
  end

  def handle_event("update_kit", %{"kit" => params}, socket) do
    kit = socket.assigns.kit
    user = socket.assigns.current_user
    account = socket.assigns.account

    unless Glossia.Policy.authorize?(:kit_write, user, account) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      case Kits.update_kit(kit, params) do
        {:ok, updated_kit} ->
          Auditing.record("kit.updated", account, user,
            resource_type: "kit",
            resource_id: to_string(kit.id),
            resource_path: "/#{socket.assigns.handle}/-/kits/#{updated_kit.handle}",
            summary: "Updated kit \"#{updated_kit.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Kit updated."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/kits/#{updated_kit.handle}")}

        {:error, changeset} ->
          {:noreply, assign(socket, kit_form: to_form(changeset, as: :kit))}
      end
    end
  end

  def handle_event("delete_kit", _params, socket) do
    kit = socket.assigns.kit
    user = socket.assigns.current_user
    account = socket.assigns.account

    unless Glossia.Policy.authorize?(:kit_delete, user, account) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      case Kits.delete_kit(kit) do
        {:ok, _} ->
          Auditing.record("kit.deleted", account, user,
            resource_type: "kit",
            resource_id: to_string(kit.id),
            resource_path: "/#{socket.assigns.handle}/-/kits",
            summary: "Deleted kit \"#{kit.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Kit deleted."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/kits")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not delete kit."))}
      end
    end
  end

  def handle_event("term_validate", %{"term" => params}, socket) do
    valid? = (params["source_term"] || "") != ""

    changed? =
      case socket.assigns[:term] do
        nil ->
          false

        term ->
          params["source_term"] != term.source_term or
            (params["definition"] || "") != (term.definition || "")
      end

    {:noreply,
     assign(socket,
       term_form: to_form(params, as: :term),
       term_form_valid?: valid?,
       term_edit_changed?: changed?
     )}
  end

  def handle_event("create_kit_term", %{"term" => params}, socket) do
    kit = socket.assigns.kit
    user = socket.assigns.current_user
    account = socket.assigns.account

    unless Glossia.Policy.authorize?(:kit_write, user, account) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      translations =
        (params["translations"] || %{})
        |> Enum.map(fn {_idx, t} -> t end)
        |> Enum.reject(fn t -> (t["translated_term"] || "") == "" end)

      term_params = Map.put(params, "translations", translations)

      case Kits.add_term(kit, term_params) do
        {:ok, _term} ->
          Auditing.record("kit_term.created", account, user,
            resource_type: "kit_term",
            resource_id: to_string(kit.id),
            resource_path: "/#{socket.assigns.handle}/-/kits/#{kit.handle}",
            summary: "Added term \"#{params["source_term"]}\" to kit \"#{kit.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Term added."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/kits/#{kit.handle}")}

        {:error, changeset} ->
          {:noreply, assign(socket, term_form: to_form(changeset, as: :term))}
      end
    end
  end

  def handle_event("update_kit_term", %{"term" => params}, socket) do
    term = socket.assigns.term
    kit = socket.assigns.kit
    user = socket.assigns.current_user
    account = socket.assigns.account

    unless Glossia.Policy.authorize?(:kit_write, user, account) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      translations =
        (params["translations"] || %{})
        |> Enum.map(fn {_idx, t} -> t end)
        |> Enum.reject(fn t -> (t["translated_term"] || "") == "" end)

      term_params = Map.put(params, "translations", translations)

      case Kits.update_term(term, term_params) do
        {:ok, _updated_term} ->
          Auditing.record("kit_term.updated", account, user,
            resource_type: "kit_term",
            resource_id: to_string(term.id),
            resource_path: "/#{socket.assigns.handle}/-/kits/#{kit.handle}",
            summary: "Updated term \"#{params["source_term"]}\" in kit \"#{kit.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Term updated."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/kits/#{kit.handle}")}

        {:error, changeset} ->
          {:noreply, assign(socket, term_form: to_form(changeset, as: :term))}
      end
    end
  end

  def handle_event("delete_kit_term", %{"term-id" => term_id}, socket) do
    kit = socket.assigns.kit
    user = socket.assigns.current_user
    account = socket.assigns.account

    unless Glossia.Policy.authorize?(:kit_write, user, account) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      term = Kits.get_term!(term_id)

      case Kits.delete_term(term) do
        {:ok, _} ->
          Auditing.record("kit_term.deleted", account, user,
            resource_type: "kit_term",
            resource_id: to_string(term.id),
            resource_path: "/#{socket.assigns.handle}/-/kits/#{kit.handle}",
            summary: "Deleted term \"#{term.source_term}\" from kit \"#{kit.name}\""
          )

          kit = Kits.get_kit!(kit.id)

          {:noreply,
           socket
           |> assign(kit: kit)
           |> put_flash(:info, gettext("Term deleted."))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not delete term."))}
      end
    end
  end

  def handle_event("star_kit", _params, socket) do
    kit = socket.assigns.kit
    user = socket.assigns.current_user

    case Kits.star_kit(kit, user) do
      {:ok, _} ->
        kit = Kits.get_kit!(kit.id)
        {:noreply, assign(socket, kit: kit, kit_starred?: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not star kit."))}
    end
  end

  def handle_event("unstar_kit", _params, socket) do
    kit = socket.assigns.kit
    user = socket.assigns.current_user

    case Kits.unstar_kit(kit, user) do
      {:ok, _} ->
        kit = Kits.get_kit!(kit.id)
        {:noreply, assign(socket, kit: kit, kit_starred?: false)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not unstar kit."))}
    end
  end

  # ---------------------------------------------------------------------------
  # Ticket events
  # ---------------------------------------------------------------------------

  def handle_event("discussion_validate", %{"_target" => target, "ticket" => params}, socket) do
    body = params["body"] || ""
    title = params["title"] || ""

    title_manually_edited? =
      cond do
        target == ["ticket", "title"] and title != "" -> true
        target == ["ticket", "title"] -> false
        true -> socket.assigns[:title_manually_edited?] || false
      end

    socket =
      if String.length(body) >= 20 and not title_manually_edited? do
        schedule_title_generation(socket, body)
      else
        cancel_title_generation(socket)
      end

    {:noreply,
     assign(socket,
       title_manually_edited?: title_manually_edited?,
       ticket_form:
         to_form(
           %{"title" => title, "body" => body},
           as: :ticket
         )
     )}
  end

  def handle_event("create_discussion", %{"ticket" => params}, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user

    cond do
      is_nil(user) or not Glossia.Policy.authorize?(:discussion_write, user, account) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      true ->
        case Discussions.create_discussion(account, user, params) do
          {:ok, ticket} ->
            Auditing.record("discussion.created", account, user,
              resource_type: "discussion",
              resource_id: to_string(ticket.id),
              resource_path: "/#{socket.assigns.handle}/-/discussions/#{ticket.number}",
              summary: "Created discussion \"#{ticket.title}\""
            )

            {:noreply,
             socket
             |> put_flash(:info, gettext("Discussion created."))
             |> push_patch(to: "/#{socket.assigns.handle}/-/discussions/#{ticket.number}")}

          {:error, changeset} ->
            {:noreply, assign(socket, ticket_form: to_form(changeset, as: :ticket))}
        end
    end
  end

  def handle_event("add_discussion_comment", %{"comment" => params}, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user
    account = socket.assigns.account

    cond do
      is_nil(user) or not Glossia.Policy.authorize?(:discussion_write, user, account) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      true ->
        case Discussions.add_comment(ticket, user, params) do
          {:ok, _comment} ->
            Auditing.record("discussion.commented", account, user,
              resource_type: "discussion",
              resource_id: to_string(ticket.id),
              resource_path: "/#{socket.assigns.handle}/-/discussions/#{ticket.number}",
              summary: "Commented on discussion \"#{ticket.title}\""
            )

            ticket = Discussions.get_discussion_by_number!(ticket.number, account.id)

            {:noreply,
             socket
             |> assign(ticket: ticket, comment_form: to_form(%{"body" => ""}, as: :comment))
             |> push_event("clear_editor:comment-body-editor", %{})}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, gettext("Could not add comment."))}
        end
    end
  end

  def handle_event("close_discussion", _params, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user
    account = socket.assigns.account

    if socket.assigns.can_write do
      case Discussions.close_discussion(ticket, user) do
        {:ok, updated_ticket} ->
          Auditing.record("discussion.closed", account, user,
            resource_type: "discussion",
            resource_id: to_string(ticket.id),
            resource_path: "/#{socket.assigns.handle}/-/discussions/#{ticket.number}",
            summary: "Closed discussion \"#{ticket.title}\""
          )

          ticket = Discussions.get_discussion_by_number!(updated_ticket.number, account.id)
          {:noreply, assign(socket, ticket: ticket)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not close discussion."))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    end
  end

  def handle_event("reopen_discussion", _params, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user
    account = socket.assigns.account

    if socket.assigns.can_write do
      case Discussions.reopen_discussion(ticket) do
        {:ok, updated_ticket} ->
          Auditing.record("discussion.reopened", account, user,
            resource_type: "discussion",
            resource_id: to_string(ticket.id),
            resource_path: "/#{socket.assigns.handle}/-/discussions/#{ticket.number}",
            summary: "Reopened discussion \"#{ticket.title}\""
          )

          ticket = Discussions.get_discussion_by_number!(updated_ticket.number, account.id)
          {:noreply, assign(socket, ticket: ticket)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not reopen discussion."))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    end
  end

  def handle_event("apply_suggestion", _params, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user
    account = socket.assigns.account
    handle = socket.assigns.handle

    case apply_discussion_suggestion(ticket, account, user, handle) do
      {:ok, message} ->
        ticket = Discussions.get_discussion_by_number!(ticket.number, account.id)
        {:noreply, socket |> assign(ticket: ticket) |> put_flash(:info, message)}

      {:error, :not_allowed} ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      {:error, :invalid_ticket} ->
        {:noreply, put_flash(socket, :error, gettext("This discussion is not a suggestion."))}

      {:error, :invalid_payload} ->
        {:noreply, put_flash(socket, :error, gettext("Invalid suggestion payload."))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Could not apply suggestion."))}
    end
  end

  def handle_event("quote_reply", %{"body" => body}, socket) do
    quoted =
      body
      |> String.split("\n")
      |> Enum.map_join("\n", &("> " <> &1))

    {:noreply, push_event(socket, "quote_editor:comment-body-editor", %{text: quoted <> "\n\n"})}
  end

  def handle_event("markdown_preview", %{"source" => source}, socket) do
    html =
      case Earmark.as_html(source, %Earmark.Options{code_class_prefix: "language-"}) do
        {:ok, html, _} -> html
        {:error, html, _} -> html
      end

    sanitized = String.replace(html, ~r/<script[\s\S]*?<\/script>/i, "")
    {:reply, %{html: sanitized}, socket}
  end

  def handle_event("disconnect_github", _params, socket) do
    installation = socket.assigns.github_installation

    case Glossia.Github.Installations.delete_installation(installation) do
      {:ok, _} ->
        Auditing.record(
          "github_installation.deleted",
          socket.assigns.account,
          socket.assigns.current_user,
          resource_type: "github_installation",
          resource_id: to_string(installation.id),
          summary: "Disconnected GitHub account #{installation.github_account_login}"
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("GitHub disconnected."))
         |> assign(github_installation: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not disconnect GitHub."))}
    end
  end

  def handle_event("select_repo", params, socket) do
    repo = %{
      "id" => params["repo-id"],
      "full_name" => params["full-name"],
      "name" => params["name"],
      "default_branch" => params["default-branch"],
      "description" => params["description"],
      "owner" => %{"login" => params["owner-login"]}
    }

    {:noreply,
     socket
     |> assign(wizard_selected_repo: repo)
     |> push_patch(to: "/#{socket.assigns.handle}/-/projects/new?step=languages")}
  end

  def handle_event("toggle_language", %{"code" => code}, socket) do
    current = socket.assigns.wizard_selected_languages

    updated =
      if code in current,
        do: List.delete(current, code),
        else: current ++ [code]

    {:noreply, assign(socket, wizard_selected_languages: updated)}
  end

  def handle_event("search_languages", %{"value" => query}, socket) do
    {:noreply, assign(socket, wizard_language_search: query)}
  end

  def handle_event("start_setup", _params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    installations = socket.assigns[:github_installations] || []
    repo = socket.assigns.wizard_selected_repo
    languages = socket.assigns.wizard_selected_languages

    # Find the matching installation for this repo by matching the repo owner
    repo_owner_login = get_in(repo, ["owner", "login"])

    installation =
      Enum.find(installations, fn inst ->
        inst.github_account_login == repo_owner_login
      end)

    repo_name = repo["full_name"] |> String.split("/") |> List.last()
    handle = repo_name |> String.downcase() |> String.replace(~r/[^a-z0-9-]/, "-")

    attrs = %{
      handle: handle,
      name: repo["name"],
      github_repo_id: repo["id"],
      github_repo_full_name: repo["full_name"],
      github_repo_default_branch: repo["default_branch"],
      setup_status: "pending",
      setup_target_languages: languages
    }

    installation_id = if installation, do: installation.id, else: nil

    result =
      if installation_id do
        Glossia.Projects.create_project_from_github(account, installation_id, attrs)
      else
        Glossia.Projects.create_project(account, attrs)
      end

    case result do
      {:ok, project} ->
        Auditing.record("project.created", account, user,
          resource_type: "project",
          resource_id: to_string(project.id),
          resource_path: "/#{socket.assigns.handle}/#{project.handle}",
          summary: "Imported project #{project.handle} from #{repo["full_name"]}"
        )

        if installation_id do
          %{project_id: project.id}
          |> Glossia.Projects.SetupWorker.new()
          |> Oban.insert()
        end

        {:noreply,
         socket
         |> assign(wizard_project: project)
         |> push_patch(to: "/#{socket.assigns.handle}/-/projects/new?step=setup")}

      {:error, changeset} ->
        Logger.warning("Failed to create project from wizard",
          errors: inspect(changeset.errors)
        )

        message =
          case changeset.errors do
            [{:handle, {msg, _}} | _] -> msg
            [{field, {msg, _}} | _] -> "#{field}: #{msg}"
            _ -> gettext("Could not import repository.")
          end

        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("finish_setup", _params, socket) do
    project = socket.assigns.wizard_project

    {:noreply, push_navigate(socket, to: "/#{socket.assigns.handle}/#{project.handle}")}
  end

  def handle_event("wizard_back", %{"step" => step}, socket) do
    {:noreply, push_patch(socket, to: "/#{socket.assigns.handle}/-/projects/new?step=#{step}")}
  end

  def handle_event("search_repos", %{"value" => query}, socket) do
    {:noreply, assign(socket, github_repos_search: query)}
  end

  # ---------------------------------------------------------------------------
  # Project settings events
  # ---------------------------------------------------------------------------

  def handle_event("validate_project_settings", %{"project" => params}, socket) do
    project = socket.assigns.project

    name_changed = String.trim(params["name"] || "") != (project.name || "")
    desc_changed = String.trim(params["description"] || "") != (project.description || "")
    url_changed = String.trim(params["url"] || "") != (project.url || "")

    has_avatar_upload =
      case socket.assigns[:uploads] do
        %{project_avatar: %{entries: entries}} when entries != [] -> true
        _ -> false
      end

    changed? = name_changed or desc_changed or url_changed or has_avatar_upload
    {:noreply, assign(socket, project_settings_changed?: changed?)}
  end

  def handle_event("update_project_settings", %{"project" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      project = socket.assigns.project
      account = socket.assigns.account
      user = socket.assigns.current_user
      handle = socket.assigns.handle

      avatar_url =
        case uploaded_entries(socket, :project_avatar) do
          {[entry], []} ->
            consume_uploaded_entry(socket, entry, fn %{path: path} ->
              content = File.read!(path)
              ext = upload_entry_extension(entry)
              s3_path = "avatars/#{handle}/projects/#{project.handle}.#{ext}"
              {:ok, _} = Glossia.Storage.upload(s3_path, content, content_type: entry.client_type)
              {:ok, s3_path}
            end)

          _ ->
            project.avatar_url
        end

      attrs = %{
        "name" => params["name"],
        "description" => params["description"],
        "url" => params["url"],
        "avatar_url" => avatar_url
      }

      case Glossia.Projects.update_project(project, attrs) do
        {:ok, updated_project} ->
          Auditing.record("project.updated", account, user,
            resource_type: "project",
            resource_id: to_string(updated_project.id),
            resource_path: "/#{handle}/#{updated_project.handle}",
            summary: "Updated project settings for \"#{updated_project.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Project settings updated."))
           |> push_patch(to: "/#{handle}/#{updated_project.handle}/-/settings")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not update project settings."))}
      end
    end
  end

  def handle_event("cancel_project_avatar", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :project_avatar, ref)}
  end

  def handle_event("translate_commit", %{"sha" => sha, "message" => message}, socket) do
    require_write!(socket)
    account = socket.assigns.account
    project = socket.assigns.project

    {:ok, session} =
      Glossia.TranslationSessions.create_session(account, project, %{
        "commit_sha" => sha,
        "commit_message" => first_line(message),
        "status" => "pending",
        "source_language" => "en",
        "target_languages" => ["es", "fr"]
      })

    handle = socket.assigns.handle

    {:noreply,
     push_navigate(socket,
       to: "/" <> handle <> "/" <> project.handle <> "/-/sessions/" <> session.id
     )}
  end

  # ---------------------------------------------------------------------------
  # LLM-generated change summary (throttled async)
  # ---------------------------------------------------------------------------

  def handle_info({:generate_cultural_notes, generation}, socket) do
    if generation != socket.assigns[:context_generation] do
      {:noreply, socket}
    else
      account = socket.assigns.account
      description = socket.assigns.voice_form_params["description"] || ""

      description =
        if description == "",
          do: if(socket.assigns.voice, do: socket.assigns.voice.description || "", else: ""),
          else: description

      countries = socket.assigns.target_countries
      existing_contexts = socket.assigns.cultural_notes

      # Only generate for countries missing context
      countries_needing_context =
        Enum.filter(countries, fn code -> (Map.get(existing_contexts, code) || "") == "" end)

      if countries_needing_context == [] do
        {:noreply, socket}
      else
        case Glossia.RateLimiter.hit("ai:country:#{account.id}", :timer.minutes(1), 20) do
          {:allow, _count} ->
            task =
              Task.async(fn ->
                results =
                  Task.async_stream(
                    countries_needing_context,
                    fn code ->
                      country_name = GlossiaWeb.DashboardComponents.country_name(code)

                      messages = [
                        %{
                          role: :system,
                          content:
                            "You are a cultural advisor. Given a description and a target country, write 2-3 sentences about cultural considerations for communicating in that country. Focus on communication style, values, and preferences. Only output the advice, nothing else."
                        },
                        %{
                          role: :user,
                          content: "Description: #{description}\nCountry: #{country_name}"
                        }
                      ]

                      case Glossia.Minimax.chat(messages, max_tokens: 512) do
                        {:ok, %{content: text}} -> {code, String.trim(text)}
                        _ -> {code, ""}
                      end
                    end,
                    timeout: :infinity
                  )
                  |> Enum.reduce(%{}, fn {:ok, {code, text}}, acc -> Map.put(acc, code, text) end)

                {:ok, results}
              end)

            {:noreply,
             assign(socket,
               generating_contexts?: true,
               context_task_ref: task.ref
             )}

          {:deny, _retry_after} ->
            {:noreply, socket}
        end
      end
    end
  end

  def handle_info({:generate_ticket_title, generation}, socket) do
    if generation != socket.assigns[:ticket_title_generation] do
      {:noreply, socket}
    else
      account = socket.assigns.account
      body = socket.assigns[:ticket_body_for_title] || ""

      case Glossia.RateLimiter.hit("ai:title:#{account.id}", :timer.minutes(1), 10) do
        {:allow, _count} ->
          messages = [
            %{
              role: :system,
              content:
                "You are a ticket tracker assistant. Given a user's description, generate a clear, concise ticket title (under 80 characters). Only output the title, nothing else."
            },
            %{role: :user, content: body}
          ]

          task = Task.async(fn -> Glossia.Minimax.chat(messages, max_tokens: 1024) end)

          form = socket.assigns.ticket_form
          body_val = form[:body].value || ""

          {:noreply,
           assign(socket,
             generating_title?: true,
             ticket_title_task_ref: task.ref,
             ticket_form:
               to_form(
                 %{"title" => "", "body" => body_val},
                 as: :ticket
               )
           )}

        {:deny, _retry_after} ->
          {:noreply, socket}
      end
    end
  end

  def handle_info({:generate_summary, context, generation}, socket) do
    if generation != socket.assigns.summary_generation do
      {:noreply, socket}
    else
      diff =
        case context do
          :voice ->
            ChangeSummary.describe_voice_changes(
              socket.assigns.original_voice,
              socket.assigns.voice_form_params,
              socket.assigns.original_overrides,
              socket.assigns.overrides
            )

          :glossary ->
            ChangeSummary.describe_glossary_changes(
              socket.assigns.original_glossary_entries,
              socket.assigns.glossary_entries
            )
        end

      context_label = if context == :voice, do: "voice configuration", else: "glossary"

      task = Task.async(fn -> ChangeSummary.generate(diff, context_label) end)
      bar_id = save_bar_id(socket)

      {:noreply,
       socket
       |> assign(generating_summary?: true, summary_task_ref: task.ref)
       |> push_event("summary_generating:#{bar_id}", %{})}
    end
  end

  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    cond do
      ref == socket.assigns[:summary_task_ref] ->
        bar_id = save_bar_id(socket)

        case result do
          {:ok, summary} ->
            {:noreply,
             socket
             |> assign(
               change_summary: summary,
               generating_summary?: false,
               summary_task_ref: nil
             )
             |> push_event("summary_generated:#{bar_id}", %{summary: summary})}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(generating_summary?: false, summary_task_ref: nil)
             |> push_event("summary_generated:#{bar_id}", %{summary: nil})}
        end

      ref == socket.assigns[:ticket_title_task_ref] ->
        case result do
          {:ok, %{content: title}} when is_binary(title) and title != "" ->
            title = String.trim(title)
            form = socket.assigns.ticket_form
            body = form[:body].value || ""

            {:noreply,
             socket
             |> assign(
               generating_title?: false,
               ticket_title_task_ref: nil,
               ticket_form:
                 to_form(
                   %{"title" => title, "body" => body},
                   as: :ticket
                 )
             )
             |> push_event("title_generated", %{title: title})}

          _other ->
            {:noreply, assign(socket, generating_title?: false, ticket_title_task_ref: nil)}
        end

      ref == socket.assigns[:context_task_ref] ->
        case result do
          {:ok, contexts} when is_map(contexts) ->
            merged = Map.merge(socket.assigns.cultural_notes, contexts)

            {:noreply,
             assign(socket,
               cultural_notes: merged,
               generating_contexts?: false,
               context_task_ref: nil,
               changed?: true
             )}

          _ ->
            {:noreply, assign(socket, generating_contexts?: false, context_task_ref: nil)}
        end

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  def handle_info({:setup_event, event}, socket) do
    setup_events = socket.assigns[:setup_events] || []
    {:noreply, assign(socket, setup_events: setup_events ++ [event])}
  end

  def handle_info({:translation_session_event, event}, socket) do
    session_events = socket.assigns[:session_events] || []
    {:noreply, assign(socket, session_events: session_events ++ [event])}
  end

  def handle_info({:setup_status, status}, socket) do
    project = socket.assigns[:project]
    wizard_project = socket.assigns[:wizard_project]

    socket =
      cond do
        project ->
          updated = refetch_project(project, status)
          assign(socket, project: updated)

        wizard_project ->
          updated = refetch_project(wizard_project, status)
          assign(socket, wizard_project: updated)

        true ->
          socket
      end

    {:noreply, socket}
  end

  defp refetch_project(project, status) do
    case Glossia.Repo.get(Glossia.Accounts.Project, project.id) do
      nil -> %{project | setup_status: status}
      fresh -> fresh
    end
  end

  # ---------------------------------------------------------------------------
  # Render (dispatches to page components)
  # ---------------------------------------------------------------------------

  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :account -> %>
        <.account_page
          projects={@projects}
          projects_total={@projects_total}
          projects_search={@projects_search}
          projects_sort_key={@projects_sort_key}
          projects_sort_dir={@projects_sort_dir}
          projects_page={@projects_page}
          handle={@handle}
          can_write={@can_write}
          public_kits={assigns[:public_kits] || []}
        />
      <% :logs -> %>
        <.logs_page
          handle={@handle}
          events={@events}
          event_types={@event_types}
          search={@events_search}
          sort_key={@events_sort_key}
          sort_dir={@events_sort_dir}
          filters={@events_filters}
          page={@events_page}
          total={@events_total}
        />
      <% :voice -> %>
        <.voice_page
          voice={@voice}
          original_voice={@original_voice}
          versions={@versions}
          voice_suggestions={@voice_suggestions}
          overrides={@overrides}
          original_overrides={@original_overrides}
          target_countries={@target_countries}
          cultural_notes={@cultural_notes}
          generating_contexts?={@generating_contexts?}
          handle={@handle}
          can_voice_write={@can_voice_write}
          can_voice_propose={@can_voice_propose}
          can_voice_suggest?={assigns[:can_voice_suggest?] || false}
          can_voice_submit?={@can_voice_submit?}
          changed?={@changed?}
          change_summary={@change_summary}
          generating_summary?={@generating_summary?}
          voice_form_params={@voice_form_params}
          voice_back_path={assigns[:voice_back_path]}
          suggestion_mode?={false}
        />
      <% :voice_suggestion_new -> %>
        <.voice_page
          voice={@voice}
          original_voice={@original_voice}
          versions={@versions}
          voice_suggestions={@voice_suggestions}
          overrides={@overrides}
          original_overrides={@original_overrides}
          target_countries={@target_countries}
          cultural_notes={@cultural_notes}
          generating_contexts?={@generating_contexts?}
          handle={@handle}
          can_voice_write={@can_voice_write}
          can_voice_propose={@can_voice_propose}
          can_voice_suggest?={assigns[:can_voice_suggest?] || false}
          can_voice_submit?={@can_voice_submit?}
          changed?={@changed?}
          change_summary={@change_summary}
          generating_summary?={@generating_summary?}
          voice_form_params={@voice_form_params}
          voice_back_path={assigns[:voice_back_path]}
          suggestion_mode?={true}
        />
      <% :voice_version -> %>
        <.voice_version_page
          voice={@voice}
          previous={@previous}
          handle={@handle}
          can_voice_write={@can_voice_write}
        />
      <% :glossary -> %>
        <.glossary_page
          glossary={@glossary}
          glossary_versions={@glossary_versions}
          glossary_suggestions={@glossary_suggestions}
          glossary_entries={@glossary_entries}
          original_glossary_entries={@original_glossary_entries}
          handle={@handle}
          can_glossary_write={@can_glossary_write}
          can_glossary_propose={@can_glossary_propose}
          can_glossary_suggest?={assigns[:can_glossary_suggest?] || false}
          can_glossary_submit?={@can_glossary_submit?}
          glossary_changed?={@glossary_changed?}
          glossary_form_params={assigns[:glossary_form_params] || %{}}
          change_summary={@change_summary}
          generating_summary?={@generating_summary?}
          glossary_back_path={assigns[:glossary_back_path]}
          suggestion_mode?={false}
        />
      <% :glossary_suggestion_new -> %>
        <.glossary_page
          glossary={@glossary}
          glossary_versions={@glossary_versions}
          glossary_suggestions={@glossary_suggestions}
          glossary_entries={@glossary_entries}
          original_glossary_entries={@original_glossary_entries}
          handle={@handle}
          can_glossary_write={@can_glossary_write}
          can_glossary_propose={@can_glossary_propose}
          can_glossary_suggest?={assigns[:can_glossary_suggest?] || false}
          can_glossary_submit?={@can_glossary_submit?}
          glossary_changed?={@glossary_changed?}
          glossary_form_params={assigns[:glossary_form_params] || %{}}
          change_summary={@change_summary}
          generating_summary?={@generating_summary?}
          glossary_back_path={assigns[:glossary_back_path]}
          suggestion_mode?={true}
        />
      <% :glossary_version -> %>
        <.glossary_version_page
          glossary={@glossary}
          previous_glossary={@previous_glossary}
          handle={@handle}
          can_glossary_write={@can_glossary_write}
        />
      <% :members -> %>
        <.members_page
          members={@members}
          members_total={@members_total}
          members_search={@members_search}
          members_sort_key={@members_sort_key}
          members_sort_dir={@members_sort_dir}
          members_filters={@members_filters}
          members_page={@members_page}
          member_roles={@member_roles}
          pending_invitations={@pending_invitations}
          all_invitations={@all_invitations}
          invitations_search={@invitations_search}
          invitations_sort_key={@invitations_sort_key}
          invitations_sort_dir={@invitations_sort_dir}
          invite_form={@invite_form}
          handle={@handle}
          can_write={@can_write}
          current_user={@current_user}
        />
      <% action when action in [:api_tokens, :api_tokens_new, :api_token_edit] -> %>
        <.api_tokens_page
          live_action={@live_action}
          handle={@handle}
          api_tokens={assigns[:api_tokens] || []}
          available_scopes={assigns[:available_scopes] || []}
          token_form={assigns[:token_form]}
          newly_created_token={assigns[:newly_created_token]}
          token_form_valid?={assigns[:token_form_valid?] || false}
          tokens_sort_key={assigns[:tokens_sort_key] || "inserted_at"}
          tokens_sort_dir={assigns[:tokens_sort_dir] || "desc"}
          editing_token={assigns[:editing_token]}
          token_edit_form={assigns[:token_edit_form]}
          token_edit_changed?={assigns[:token_edit_changed?] || false}
        />
      <% action when action in [:api_apps, :api_apps_new, :api_app_edit] -> %>
        <.api_apps_page
          live_action={@live_action}
          handle={@handle}
          oauth_apps={assigns[:oauth_apps] || []}
          oauth_app={assigns[:oauth_app]}
          boruta_client={assigns[:boruta_client]}
          app_form={assigns[:app_form]}
          newly_created_secret={assigns[:newly_created_secret]}
          newly_regenerated_secret={assigns[:newly_regenerated_secret]}
          app_form_valid?={assigns[:app_form_valid?] || false}
          app_edit_changed?={assigns[:app_edit_changed?] || false}
          apps_sort_key={assigns[:apps_sort_key] || "inserted_at"}
          apps_sort_dir={assigns[:apps_sort_dir] || "desc"}
        />
      <% action when action in [:kits, :kit_new, :kit_show, :kit_edit, :kit_term_new, :kit_term_edit] -> %>
        <.kits_page
          live_action={@live_action}
          handle={@handle}
          kits={assigns[:kits] || []}
          kit={assigns[:kit]}
          kit_form={assigns[:kit_form]}
          kit_form_valid?={assigns[:kit_form_valid?] || false}
          kit_edit_changed?={assigns[:kit_edit_changed?] || false}
          kit_starred?={assigns[:kit_starred?] || false}
          term={assigns[:term]}
          term_form={assigns[:term_form]}
          term_form_valid?={assigns[:term_form_valid?] || false}
          term_edit_changed?={assigns[:term_edit_changed?] || false}
          kits_sort_key={assigns[:kits_sort_key] || "inserted_at"}
          kits_sort_dir={assigns[:kits_sort_dir] || "desc"}
          kits_active_filters={assigns[:kits_active_filters] || %{}}
          current_user={@current_user}
          can_kit_write={assigns[:can_kit_write] || false}
        />
      <% action when action in [:discussions, :discussion_new, :discussion_show] -> %>
        <.discussions_page
          live_action={@live_action}
          handle={@handle}
          tickets={assigns[:discussions] || []}
          ticket={assigns[:ticket]}
          ticket_form={assigns[:ticket_form]}
          comment_form={assigns[:comment_form]}
          current_user={@current_user}
          can_write={@can_write}
          can_voice_write={assigns[:can_voice_write] || false}
          can_glossary_write={assigns[:can_glossary_write] || false}
          discussions_sort_key={assigns[:discussions_sort_key] || "inserted_at"}
          discussions_sort_dir={assigns[:discussions_sort_dir] || "desc"}
          discussions_active_filters={assigns[:discussions_active_filters] || %{}}
          generating_title?={assigns[:generating_title?] || false}
        />
      <% :project_new -> %>
        <.project_new_wizard
          handle={@handle}
          account={@account}
          step={@wizard_step}
          github_repos={assigns[:github_repos] || []}
          github_repos_search={assigns[:github_repos_search] || ""}
          github_configured?={assigns[:github_configured?] || false}
          selected_repo={assigns[:wizard_selected_repo]}
          selected_languages={assigns[:wizard_selected_languages] || []}
          language_search={assigns[:wizard_language_search] || ""}
          wizard_project={assigns[:wizard_project]}
          setup_events={assigns[:setup_events] || []}
        />
      <% :project_settings -> %>
        <.project_settings_page
          handle={@handle}
          project={@project}
          project_settings_form={@project_settings_form}
          project_settings_changed?={@project_settings_changed?}
          project_avatar_url={@project_avatar_url}
          uploads={assigns[:uploads]}
        />
      <% :project_activity -> %>
        <.project_activity_page
          handle={@handle}
          project={@project}
          commits={assigns[:commits] || []}
          sessions_by_sha={assigns[:sessions_by_sha] || %{}}
          commits_error={assigns[:commits_error]}
          commits_search={assigns[:commits_search] || ""}
          commits_sort_key={assigns[:commits_sort_key] || "date"}
          commits_sort_dir={assigns[:commits_sort_dir] || "desc"}
          can_write={@can_write}
        />
      <% :project_translations -> %>
        <.project_translations_page
          handle={@handle}
          project={@project}
          translations={assigns[:translations] || []}
          translations_total={assigns[:translations_total] || 0}
          translations_search={assigns[:translations_search] || ""}
          translations_sort_key={assigns[:translations_sort_key] || "inserted_at"}
          translations_sort_dir={assigns[:translations_sort_dir] || "desc"}
          translations_page={assigns[:translations_page] || 1}
          translations_active_filters={assigns[:translations_active_filters] || %{}}
        />
      <% :project_session -> %>
        <.session_detail_page
          handle={@handle}
          project={@project}
          session={@session}
          session_events={assigns[:session_events] || []}
        />
      <% :project -> %>
        <.project_page
          handle={@handle}
          account={@account}
          project={assigns[:project]}
          project_name={@project_name}
          setup_events={assigns[:setup_events] || []}
        />
    <% end %>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Account (projects list)
  # ---------------------------------------------------------------------------

  defp account_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Account")}
        description={gettext("Projects and integrations connected to this account.")}
      >
        <:actions>
          <%= if @can_write do %>
            <.link patch={"/" <> @handle <> "/-/projects/new"} class="dash-btn dash-btn-primary">
              {gettext("New project")}
            </.link>
          <% end %>
        </:actions>
      </.page_header>

      <.resource_table
        id="projects-table"
        rows={@projects}
        search={@projects_search}
        search_placeholder={gettext("Search projects...")}
        sort_key={@projects_sort_key}
        sort_dir={@projects_sort_dir}
        page={@projects_page}
        per_page={25}
        total={@projects_total}
      >
        <:col :let={project} label={gettext("Name")} key="name" sortable>
          <.link navigate={"/" <> @handle <> "/" <> project.handle} class="resource-link">
            {project.name}
          </.link>
        </:col>
        <:col :let={project} label={gettext("Handle")} key="handle" sortable>
          <span class="mono">{project.handle}</span>
        </:col>
        <:col :let={project} label={gettext("Repository")} key="repo">
          <%= if project.github_repo_full_name do %>
            <span class="mono">{project.github_repo_full_name}</span>
          <% else %>
            <span class="muted">&mdash;</span>
          <% end %>
        </:col>
        <:col :let={project} label={gettext("Status")} key="status">
          <%= if project.setup_status do %>
            <span class={[
              "badge",
              project.setup_status == "completed" && "badge-success",
              project.setup_status == "failed" && "badge-error",
              project.setup_status in ["pending", "running"] && "badge-info"
            ]}>
              {project.setup_status}
            </span>
          <% else %>
            <span class="muted">&mdash;</span>
          <% end %>
        </:col>
        <:col :let={project} label={gettext("Created")} key="inserted_at" sortable>
          <time datetime={DateTime.to_iso8601(project.inserted_at)}>
            {Calendar.strftime(project.inserted_at, "%b %d, %Y")}
          </time>
        </:col>

        <:empty>
          <div class="dash-empty-state">
            <svg
              width="32"
              height="32"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z" />
            </svg>
            <h2>{gettext("No projects yet")}</h2>
            <p>{gettext("Projects will show up here once you create one.")}</p>
          </div>
        </:empty>
      </.resource_table>

      <%= if @public_kits != [] do %>
        <div style="margin-top: var(--space-8);">
          <h2 style="font-size: var(--text-lg); font-weight: var(--weight-semibold); margin-bottom: var(--space-4);">
            {gettext("Kits")}
          </h2>
          <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: var(--space-4);">
            <%= for kit <- @public_kits do %>
              <.link
                navigate={"/" <> @handle <> "/-/kits/" <> kit.handle}
                class="card"
                style="text-decoration: none;"
              >
                <h3 style="font-weight: var(--weight-semibold); margin-bottom: var(--space-1);">
                  {kit.name}
                </h3>
                <p style="color: var(--color-text-muted); font-size: var(--text-sm); margin-bottom: var(--space-2);">
                  {kit.description || gettext("No description")}
                </p>
                <div style="display: flex; gap: var(--space-3); font-size: var(--text-xs); color: var(--color-text-muted);">
                  <span>{kit.source_language} &rarr; {Enum.join(kit.target_languages, ", ")}</span>
                  <span>&star; {kit.stars_count}</span>
                </div>
              </.link>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Logs
  # ---------------------------------------------------------------------------

  defp logs_page(assigns) do
    assigns =
      assign(
        assigns,
        :type_filter_options,
        Enum.map(assigns.event_types, fn t -> %{value: t, label: t} end)
      )

    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Logs")}
        description={gettext("Audit trail of actions and events for this account.")}
      />

      <.resource_table
        id="activity-table"
        rows={@events}
        search={@search}
        search_placeholder={gettext("Search events...")}
        sort_key={@sort_key}
        sort_dir={@sort_dir}
        filters={[%{key: "type", label: gettext("Event type"), options: @type_filter_options}]}
        active_filters={@filters}
        page={@page}
        per_page={25}
        total={@total}
      >
        <:col :let={event} label={gettext("Event")} key="summary" sortable class="activity-event-cell">
          <% display_summary =
            if event.summary != "", do: event.summary, else: humanize_event_name(event.name) %>
          <% normalized_path = normalize_resource_path(event.resource_path) %>
          <%= if normalized_path != "" do %>
            <.link navigate={normalized_path} class="activity-event-link">
              {display_summary}
            </.link>
          <% else %>
            <span>{display_summary}</span>
          <% end %>
          <span class="activity-event-name">{event.name}</span>
        </:col>
        <:col :let={event} label={gettext("By")} key="actor" sortable class="activity-actor-cell">
          <%= if event.actor_email != "" do %>
            <span class="voice-author-chip">
              <img
                src={gravatar_url(event.actor_email)}
                alt=""
                width="20"
                height="20"
                class="voice-author-avatar"
              />
              <span>
                {if event.actor_handle != "",
                  do: event.actor_handle,
                  else: event.actor_email}
              </span>
            </span>
          <% else %>
            <span class="activity-system-actor">{gettext("System")}</span>
          <% end %>
        </:col>
        <:col
          :let={event}
          label={gettext("Date")}
          key="date"
          sortable
          class="activity-time-cell"
        >
          <time datetime={DateTime.to_iso8601(event.inserted_at)}>
            {Calendar.strftime(event.inserted_at, "%b %d, %Y %H:%M")}
          </time>
        </:col>

        <:empty>
          <div class="dash-empty-state">
            <svg
              width="32"
              height="32"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
            </svg>
            <h2>{gettext("No logs yet")}</h2>
            <p>{gettext("Events will appear here as you and your team make changes.")}</p>
          </div>
        </:empty>
      </.resource_table>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Voice form
  # ---------------------------------------------------------------------------

  attr :can_write, :boolean, required: true
  attr :can_propose, :boolean, required: true
  attr :resource_name, :string, required: true
  attr :handle, :string, required: true

  defp suggestion_mode_banner(assigns) do
    ~H"""
    <%= cond do %>
      <% @can_propose or @can_write -> %>
        <div class="voice-mode-banner voice-mode-banner-propose">
          <div class="voice-mode-banner-copy">
            <h2>{gettext("Suggestion mode")}</h2>
            <p>
              {gettext(
                "Draft your %{resource} updates here. When you're ready, use the bottom bar to open a suggestion with title and details.",
                resource: @resource_name
              )}
            </p>
          </div>
        </div>
      <% true -> %>
    <% end %>
    """
  end

  defp voice_page(assigns) do
    assigns =
      assigns
      |> assign_new(:suggestion_mode?, fn -> false end)
      |> Map.put(:tone_options, @tone_options)
      |> Map.put(:formality_options, @formality_options)

    ~H"""
    <div class="dash-page">
      <.page_header
        title={if @suggestion_mode?, do: gettext("Suggest voice changes"), else: gettext("Voice")}
        description={
          if @suggestion_mode?,
            do: gettext("Create a suggestion with title, description, and proposed voice updates."),
            else: gettext("Define the tone, formality, and style guidelines for your content.")
        }
      >
        <:actions>
          <%= if (not @suggestion_mode?) and @can_voice_suggest? do %>
            <.link
              patch={"/" <> @handle <> "/-/voice/suggestion/new"}
              class="dash-btn dash-btn-secondary"
            >
              {gettext("Suggest changes")}
            </.link>
          <% end %>
        </:actions>
      </.page_header>

      <%= if not @suggestion_mode? do %>
        <.suggestion_mode_banner
          can_write={@can_voice_write}
          can_propose={@can_voice_propose}
          resource_name={gettext("voice")}
          handle={@handle}
        />
      <% end %>

      <form
        phx-change="validate"
        phx-submit={if @suggestion_mode?, do: "create_voice_suggestion", else: "save_voice"}
        class="voice-form"
        id="voice-form"
      >
        <%= if @suggestion_mode? do %>
          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Suggestion details")}</h2>
              <p>
                {gettext("Provide a clear title, full context, and a concise summary of intent.")}
              </p>
            </div>
            <div class="voice-card">
              <div class="voice-card-fields">
                <div class="ticket-form-field">
                  <label for="voice_suggestion_title">{gettext("Title")}</label>
                  <input
                    type="text"
                    id="voice_suggestion_title"
                    name="suggestion_title"
                    value={@voice_form_params["suggestion_title"] || ""}
                    placeholder={gettext("Short summary of the suggested change")}
                    required
                  />
                </div>
                <div class="ticket-form-field">
                  <label>{gettext("Description")}</label>
                  <.markdown_editor
                    id="voice-suggestion-body-editor"
                    name="suggestion_body"
                    value={@voice_form_params["suggestion_body"] || ""}
                    placeholder={gettext("Explain what should change and why...")}
                    rows={8}
                    required
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="voice-section-divider"></div>
        <% end %>

        <%= if @suggestion_mode? do %>
          <.voice_suggestion_changes
            voice={@voice}
            original_voice={@original_voice}
            voice_form_params={@voice_form_params}
            overrides={@overrides}
            original_overrides={@original_overrides}
            target_countries={@target_countries}
            cultural_notes={@cultural_notes}
          />
          <div class="voice-section-divider"></div>
        <% end %>

        <%= if not @suggestion_mode? do %>
          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("About")}</h2>
              <p>{gettext("Describe what you do and which countries you target.")}</p>
            </div>
            <div class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "description") &&
                    "voice-field-changed"
                ]}>
                  <label for="voice_description">{gettext("Description")}</label>
                  <textarea
                    id="voice_description"
                    name="description"
                    rows="3"
                    placeholder={gettext("Briefly describe what you do and who you serve...")}
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                  >{@voice_form_params["description"] || (@voice && @voice.description) || ""}</textarea>
                  <span class="voice-field-help">
                    {gettext("Used to generate cultural notes for target countries.")}
                  </span>
                </div>
                <div class={[
                  "voice-field",
                  voice_target_countries_changed?(@target_countries, @original_voice) &&
                    "voice-field-changed"
                ]}>
                  <label>{gettext("Target countries")}</label>
                  <%= if @target_countries != [] do %>
                    <div class="voice-country-tags" id="voice-country-tags">
                      <%= for code <- @target_countries do %>
                        <span class="voice-country-tag">
                          {country_flag(code)} {code}
                          <%= if @can_voice_submit? do %>
                            <button
                              type="button"
                              class="voice-country-tag-remove"
                              phx-click="remove_country"
                              phx-value-code={code}
                              aria-label={gettext("Remove %{country}", country: country_name(code))}
                            >
                              &times;
                            </button>
                          <% end %>
                        </span>
                      <% end %>
                    </div>
                  <% end %>
                  <%= if @can_voice_submit? do %>
                    <.country_picker
                      id="voice-country-picker"
                      exclude={@target_countries}
                    />
                  <% end %>
                </div>
                <%= if @target_countries != [] do %>
                  <div class={[
                    "voice-field",
                    voice_cultural_notes_changed?(@cultural_notes, @original_voice) &&
                      "voice-field-changed"
                  ]}>
                    <label>{gettext("Cultural notes")}</label>
                    <span class="voice-field-help">
                      <%= if @generating_contexts? do %>
                        {gettext("Generating cultural notes...")}
                      <% else %>
                        {gettext("AI-generated cultural notes per country. You can edit them.")}
                      <% end %>
                    </span>
                    <%= for code <- @target_countries do %>
                      <div
                        class={[
                          "voice-country-context",
                          voice_country_note_changed?(code, @cultural_notes, @original_voice) &&
                            "voice-country-context-changed"
                        ]}
                        id={"country-context-#{code}"}
                      >
                        <label class="voice-country-context-label">
                          {country_flag(code)} {country_name(code)}
                        </label>
                        <textarea
                          name={"cultural_notes[#{code}]"}
                          rows="3"
                          placeholder={
                            gettext("Cultural notes for %{country}...", country: country_name(code))
                          }
                          disabled={!@can_voice_submit?}
                          phx-debounce="300"
                        >{Map.get(@cultural_notes, code, "")}</textarea>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="voice-section-divider"></div>

          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Tone and style")}</h2>
              <p>{gettext("Set the overall personality and formality level for your content.")}</p>
            </div>
            <div class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "tone") &&
                    "voice-field-changed"
                ]}>
                  <label for="voice_tone">{gettext("Tone")}</label>
                  <select
                    id="voice_tone"
                    name="tone"
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                  >
                    <option value="">{gettext("Select a tone")}</option>
                    <%= for opt <- @tone_options do %>
                      <option
                        value={opt}
                        selected={
                          (@voice_form_params["tone"] || (@voice && @voice.tone) || "") == opt
                        }
                      >
                        {opt |> String.capitalize()}
                      </option>
                    <% end %>
                  </select>
                  <span class="voice-field-help">
                    {gettext("The general character of your writing.")}
                  </span>
                </div>
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "formality") &&
                    "voice-field-changed"
                ]}>
                  <label for="voice_formality">{gettext("Formality")}</label>
                  <select
                    id="voice_formality"
                    name="formality"
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                  >
                    <option value="">{gettext("Select a level")}</option>
                    <%= for opt <- @formality_options do %>
                      <option
                        value={opt}
                        selected={
                          (@voice_form_params["formality"] || (@voice && @voice.formality) || "") ==
                            opt
                        }
                      >
                        {opt |> String.replace("_", " ") |> String.capitalize()}
                      </option>
                    <% end %>
                  </select>
                  <span class="voice-field-help">
                    {gettext("How casual or formal the language should be.")}
                  </span>
                </div>
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "target_audience") &&
                    "voice-field-changed"
                ]}>
                  <label for="voice_target_audience">{gettext("Target audience")}</label>
                  <input
                    type="text"
                    id="voice_target_audience"
                    name="target_audience"
                    value={
                      @voice_form_params["target_audience"] || (@voice && @voice.target_audience) ||
                        ""
                    }
                    placeholder={gettext("e.g. Developers, marketing teams, general public")}
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                  />
                  <span class="voice-field-help">{gettext("Who you are writing for.")}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="voice-section-divider"></div>

          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Guidelines")}</h2>
              <p>
                {gettext(
                  "Detailed writing rules, brand voice notes, and things to avoid. Supports Markdown."
                )}
              </p>
            </div>
            <div class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "guidelines") &&
                    "voice-field-changed"
                ]}>
                  <label for="voice_guidelines">{gettext("Writing guidelines")}</label>
                  <textarea
                    id="voice_guidelines"
                    name="guidelines"
                    rows="10"
                    placeholder={gettext("Write your brand voice guidelines here...")}
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                  >{@voice_form_params["guidelines"] || (@voice && @voice.guidelines) || ""}</textarea>
                </div>
              </div>
            </div>
          </div>

          <div class="voice-section-divider"></div>

          <div class="voice-section" id="voice-overrides">
            <div class="voice-section-info">
              <h2>{gettext("Language overrides")}</h2>
              <p>
                {gettext(
                  "Customize the voice for specific languages. Fields left empty will fall back to the base voice above."
                )}
              </p>
            </div>
            <div class="voice-card">
              <div class={[@overrides != [] && "voice-card-fields"]} id="override-list">
                <%= for {override, idx} <- Enum.with_index(@overrides) do %>
                  <div
                    class={[
                      "voice-override-block",
                      voice_override_changed?(override, @original_overrides) &&
                        "voice-override-block-changed"
                    ]}
                    data-override-index={idx}
                  >
                    <div class="voice-override-header">
                      <span class="voice-override-locale">
                        {if override.locale != "", do: override.locale, else: gettext("New override")}
                      </span>
                      <%= if @can_voice_submit? do %>
                        <button
                          type="button"
                          class="voice-link-btn voice-link-btn-danger"
                          phx-click="remove_override"
                          phx-value-index={idx}
                        >
                          {gettext("Remove")}
                        </button>
                      <% end %>
                    </div>
                    <%= if override.locale == "" do %>
                      <div class="voice-override-fields">
                        <div class="voice-field">
                          <label>{gettext("Language")}</label>
                          <.locale_picker
                            id={"voice-locale-#{idx}"}
                            name={"overrides[#{idx}][locale]"}
                            value=""
                          />
                        </div>
                      </div>
                    <% else %>
                      <input type="hidden" name={"overrides[#{idx}][locale]"} value={override.locale} />
                    <% end %>
                    <div class="voice-override-fields">
                      <div class="voice-field-row">
                        <div class="voice-field">
                          <label>{gettext("Tone")}</label>
                          <select name={"overrides[#{idx}][tone]"} disabled={!@can_voice_submit?}>
                            <option value="">{gettext("Use base")}</option>
                            <%= for opt <- @tone_options do %>
                              <option value={opt} selected={override.tone == opt}>
                                {opt |> String.capitalize()}
                              </option>
                            <% end %>
                          </select>
                        </div>
                        <div class="voice-field">
                          <label>{gettext("Formality")}</label>
                          <select name={"overrides[#{idx}][formality]"} disabled={!@can_voice_submit?}>
                            <option value="">{gettext("Use base")}</option>
                            <%= for opt <- @formality_options do %>
                              <option value={opt} selected={override.formality == opt}>
                                {opt |> String.replace("_", " ") |> String.capitalize()}
                              </option>
                            <% end %>
                          </select>
                        </div>
                      </div>
                      <div class="voice-field">
                        <label>{gettext("Target audience")}</label>
                        <input
                          type="text"
                          name={"overrides[#{idx}][target_audience]"}
                          value={override.target_audience || ""}
                          disabled={!@can_voice_submit?}
                          phx-debounce="300"
                        />
                      </div>
                      <div class="voice-field">
                        <label>{gettext("Guidelines")}</label>
                        <textarea
                          name={"overrides[#{idx}][guidelines]"}
                          rows="4"
                          disabled={!@can_voice_submit?}
                          phx-debounce="300"
                        >{override.guidelines || ""}</textarea>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
              <%= if @can_voice_submit? do %>
                <div class="voice-card-footer" style="justify-content: flex-start;">
                  <button type="button" class="voice-link-btn" phx-click="add_override">
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 20 20"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      aria-hidden="true"
                    >
                      <line x1="10" y1="4" x2="10" y2="16" /><line x1="4" y1="10" x2="16" y2="10" />
                    </svg>
                    {gettext("Add language override")}
                  </button>
                </div>
              <% end %>
            </div>
          </div>

          <%= if (not @suggestion_mode?) and @versions != [] do %>
            <div class="voice-section-divider"></div>

            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Version history")}</h2>
                <p>{gettext("Previous versions of your voice configuration.")}</p>
              </div>
              <.resource_table id="voice-versions" rows={@versions}>
                <:col :let={v} label={gettext("Version")} class="resource-col-nowrap">
                  <.link
                    patch={"/" <> @handle <> "/-/voice/" <> to_string(v.version)}
                    class="voice-history-link"
                  >
                    {"##{v.version}"}
                  </.link>
                </:col>
                <:col :let={v} label={gettext("Date")} class="resource-col-nowrap">
                  <time datetime={DateTime.to_iso8601(v.inserted_at)}>
                    {Calendar.strftime(v.inserted_at, "%b %d, %Y %H:%M")}
                  </time>
                </:col>
                <:col :let={v} label={gettext("By")} class="resource-col-nowrap">
                  <%= if v.created_by do %>
                    <span class="voice-author-chip">
                      <img
                        src={gravatar_url(v.created_by.email)}
                        alt=""
                        width="20"
                        height="20"
                        class="voice-author-avatar"
                      />
                      <span>
                        {(v.created_by.account && v.created_by.account.handle) ||
                          v.created_by.email}
                      </span>
                    </span>
                  <% else %>
                    -
                  <% end %>
                </:col>
              </.resource_table>
            </div>
          <% end %>

          <%= if (not @suggestion_mode?) and @voice_suggestions != [] do %>
            <div class="voice-section-divider"></div>

            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Open suggestions")}</h2>
                <p>{gettext("Pending voice proposals from contributors.")}</p>
              </div>
              <.resource_table id="voice-suggestions" rows={@voice_suggestions}>
                <:col :let={ticket} label={gettext("Suggestion")} class="resource-col-nowrap">
                  <.link
                    patch={"/" <> @handle <> "/-/discussions/" <> Integer.to_string(ticket.number)}
                    class="voice-history-link"
                  >
                    {"##{ticket.number}"}
                  </.link>
                </:col>
                <:col :let={ticket} label={gettext("Title")}>{ticket.title}</:col>
                <:col :let={ticket} label={gettext("By")} class="resource-col-nowrap">
                  <%= if ticket.user do %>
                    <span class="voice-author-chip">
                      <img
                        src={gravatar_url(ticket.user.email)}
                        alt=""
                        width="20"
                        height="20"
                        class="voice-author-avatar"
                      />
                      <span>
                        {(ticket.user.account && ticket.user.account.handle) || ticket.user.email}
                      </span>
                    </span>
                  <% else %>
                    -
                  <% end %>
                </:col>
                <:col :let={ticket} label={gettext("Date")} class="resource-col-nowrap">
                  <time datetime={DateTime.to_iso8601(ticket.inserted_at)}>
                    {Calendar.strftime(ticket.inserted_at, "%b %d, %Y %H:%M")}
                  </time>
                </:col>
              </.resource_table>
            </div>
          <% end %>
        <% end %>

        <%= if @suggestion_mode? do %>
          <div class="ticket-form-actions">
            <.link
              patch={@voice_back_path || "/" <> @handle <> "/-/voice"}
              class="dash-btn dash-btn-secondary"
            >
              {gettext("Cancel")}
            </.link>
            <button type="submit" class="dash-btn dash-btn-primary">
              {gettext("Submit suggestion")}
            </button>
          </div>
        <% else %>
          <%= if @can_voice_submit? do %>
            <.save_bar
              id="voice-save-bar"
              form="voice-form"
              visible={@changed?}
              discard_event="discard_changes"
              change_summary={@change_summary}
              generating_summary?={@generating_summary?}
              state_label={gettext("Ready to suggest changes")}
              submit_label={gettext("Suggest changes")}
              show_note={false}
            />
          <% end %>
        <% end %>
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Voice version (diff view)
  # ---------------------------------------------------------------------------

  defp voice_version_page(assigns) do
    ~H"""
    <div class="dash-page">
      <div class="dash-page-header">
        <div class="voice-version-header">
          <h1>
            <span>{"##{@voice.version}"}</span>
          </h1>
          <p class="voice-version-meta">
            <time datetime={DateTime.to_iso8601(@voice.inserted_at)}>
              {Calendar.strftime(@voice.inserted_at, "%b %d, %Y at %H:%M")}
            </time>
            <%= if @voice.created_by do %>
              <span class="voice-version-meta-sep">&middot;</span>
              <span class="voice-author-chip">
                <img
                  src={gravatar_url(@voice.created_by.email)}
                  alt=""
                  width="20"
                  height="20"
                  class="voice-author-avatar"
                />
                <span>
                  {(@voice.created_by.account && @voice.created_by.account.handle) ||
                    @voice.created_by.email}
                </span>
              </span>
            <% end %>
          </p>
        </div>
      </div>

      <%= if (@voice.description || "") != "" or (@voice.target_countries || []) != [] do %>
        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("About")}</h2>
            <p>{gettext("Description and target countries for this version.")}</p>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <.diff_field
                label={gettext("Description")}
                current={@voice.description}
                previous={@previous && @previous.description}
              />
              <div class="voice-field">
                <label>{gettext("Target countries")}</label>
                <div class="voice-country-tags">
                  <%= for code <- @voice.target_countries || [] do %>
                    <span class="voice-country-tag">
                      {country_flag(code)} {code}
                    </span>
                  <% end %>
                  <%= if (@voice.target_countries || []) == [] do %>
                    <span class="muted">{gettext("None")}</span>
                  <% end %>
                </div>
              </div>
              <%= for {code, ctx} <- @voice.cultural_notes || %{} do %>
                <div class="voice-field">
                  <label>{country_flag(code)} {country_name(code)}</label>
                  <p style="font-size: var(--text-sm); color: var(--color-text-muted);">{ctx}</p>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="voice-section-divider"></div>
      <% end %>

      <div class="voice-section">
        <div class="voice-section-info">
          <h2>{gettext("Tone and style")}</h2>
          <p>{gettext("Voice personality and formality settings for this version.")}</p>
        </div>
        <div class="voice-card">
          <div class="voice-card-fields">
            <div class="voice-field-row">
              <.diff_field
                label={gettext("Tone")}
                current={@voice.tone}
                previous={@previous && @previous.tone}
              />
              <.diff_field
                label={gettext("Formality")}
                current={@voice.formality}
                previous={@previous && @previous.formality}
                formatter={&humanize_formality/1}
              />
            </div>
            <.diff_field
              label={gettext("Target audience")}
              current={@voice.target_audience}
              previous={@previous && @previous.target_audience}
            />
          </div>
        </div>
      </div>

      <div class="voice-section-divider"></div>

      <div class="voice-section">
        <div class="voice-section-info">
          <h2>{gettext("Guidelines")}</h2>
          <p>{gettext("Writing rules and brand voice notes.")}</p>
        </div>
        <div class="voice-card">
          <div class="voice-card-fields">
            <%= if @previous && @previous.guidelines != @voice.guidelines do %>
              <div class="voice-diff-text-block">
                <%= if @previous.guidelines do %>
                  <div class="voice-diff-text-removed">
                    <span class="voice-diff-text-badge voice-diff-text-badge-removed">
                      {gettext("Previous")}
                    </span>
                    <pre>{@previous.guidelines}</pre>
                  </div>
                <% end %>
                <%= if @voice.guidelines do %>
                  <div class="voice-diff-text-added">
                    <span class="voice-diff-text-badge voice-diff-text-badge-added">
                      {gettext("Current")}
                    </span>
                    <pre>{@voice.guidelines}</pre>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="voice-diff-field">
                <pre class="voice-diff-guidelines-pre">{@voice.guidelines || gettext("No guidelines set.")}</pre>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%= if @voice.overrides != [] || (@previous && @previous.overrides != []) do %>
        <div class="voice-section-divider"></div>

        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("Language overrides")}</h2>
            <p>{gettext("Per-language voice customizations in this version.")}</p>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <% current_locales = MapSet.new(Enum.map(@voice.overrides, & &1.locale))

              prev_locales =
                if @previous,
                  do: MapSet.new(Enum.map(@previous.overrides, & &1.locale)),
                  else: MapSet.new()

              all_locales = MapSet.union(current_locales, prev_locales) |> Enum.sort() %>
              <%= for locale <- all_locales do %>
                <% cur = Enum.find(@voice.overrides, &(&1.locale == locale))

                prev =
                  if @previous, do: Enum.find(@previous.overrides, &(&1.locale == locale)), else: nil

                status =
                  cond do
                    cur && !prev -> :added
                    !cur && prev -> :removed
                    true -> :existing
                  end %>
                <div class={"voice-override-diff-block voice-override-diff-#{status}"}>
                  <div class="voice-override-diff-header">
                    <span class="voice-override-locale">{locale}</span>
                    <%= case status do %>
                      <% :added -> %>
                        <span class="voice-diff-badge voice-diff-badge-added">
                          {gettext("Added")}
                        </span>
                      <% :removed -> %>
                        <span class="voice-diff-badge voice-diff-badge-removed">
                          {gettext("Removed")}
                        </span>
                      <% _ -> %>
                    <% end %>
                  </div>
                  <div class="voice-override-diff-fields">
                    <div class="voice-field-row">
                      <.diff_field
                        label={gettext("Tone")}
                        current={cur && cur.tone}
                        previous={prev && prev.tone}
                      />
                      <.diff_field
                        label={gettext("Formality")}
                        current={cur && cur.formality}
                        previous={prev && prev.formality}
                        formatter={&humanize_formality/1}
                      />
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Glossary
  # ---------------------------------------------------------------------------

  defp glossary_page(assigns) do
    assigns = assign_new(assigns, :suggestion_mode?, fn -> false end)

    ~H"""
    <div class="dash-page">
      <.page_header
        title={
          if @suggestion_mode?, do: gettext("Suggest glossary changes"), else: gettext("Glossary")
        }
        description={
          if @suggestion_mode?,
            do:
              gettext("Create a suggestion with title, description, and proposed glossary updates."),
            else: gettext("Approved terms and translations to keep your content consistent.")
        }
      >
        <:actions>
          <%= if (not @suggestion_mode?) and @can_glossary_suggest? do %>
            <.link
              patch={"/" <> @handle <> "/-/glossary/suggestion/new"}
              class="dash-btn dash-btn-secondary"
            >
              {gettext("Suggest changes")}
            </.link>
          <% end %>
        </:actions>
      </.page_header>

      <%= if not @suggestion_mode? do %>
        <.suggestion_mode_banner
          can_write={@can_glossary_write}
          can_propose={@can_glossary_propose}
          resource_name={gettext("glossary")}
          handle={@handle}
        />
      <% end %>

      <form
        phx-change="glossary_validate"
        phx-submit={if @suggestion_mode?, do: "create_glossary_suggestion", else: "save_glossary"}
        class="voice-form"
        id="glossary-form"
      >
        <%= if @suggestion_mode? do %>
          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Suggestion details")}</h2>
              <p>
                {gettext("Provide a clear title, full context, and a concise summary of intent.")}
              </p>
            </div>
            <div class="voice-card">
              <div class="voice-card-fields">
                <div class="ticket-form-field">
                  <label for="glossary_suggestion_title">{gettext("Title")}</label>
                  <input
                    type="text"
                    id="glossary_suggestion_title"
                    name="suggestion_title"
                    value={@glossary_form_params["suggestion_title"] || ""}
                    placeholder={gettext("Short summary of the suggested change")}
                    required
                  />
                </div>
                <div class="ticket-form-field">
                  <label>{gettext("Description")}</label>
                  <.markdown_editor
                    id="glossary-suggestion-body-editor"
                    name="suggestion_body"
                    value={@glossary_form_params["suggestion_body"] || ""}
                    placeholder={gettext("Explain what should change and why...")}
                    rows={8}
                    required
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="voice-section-divider"></div>
        <% end %>

        <%= if @suggestion_mode? do %>
          <.glossary_suggestion_changes
            glossary_entries={@glossary_entries}
            original_glossary_entries={@original_glossary_entries}
          />
          <div class="voice-section-divider"></div>
        <% end %>

        <%= if not @suggestion_mode? do %>
          <div class="voice-section" id="glossary-entries">
            <div class="voice-section-info">
              <h2>{gettext("Terms")}</h2>
              <p>
                {gettext(
                  "Define canonical terms and their approved translations per language. Terms are matched during content processing to ensure consistent terminology."
                )}
              </p>
            </div>
            <div class="voice-card">
              <div class={[@glossary_entries != [] && "voice-card-fields"]} id="glossary-entry-list">
                <%= for {entry, idx} <- Enum.with_index(@glossary_entries) do %>
                  <div
                    class={[
                      "glossary-entry-block",
                      glossary_entry_changed?(entry, @original_glossary_entries) &&
                        "glossary-entry-block-changed"
                    ]}
                    data-entry-index={idx}
                  >
                    <div class="voice-override-header">
                      <span class="voice-override-locale">
                        {if(entry.term != "" && entry.term, do: entry.term, else: gettext("New term"))}
                      </span>
                      <%= if @can_glossary_submit? do %>
                        <button
                          type="button"
                          class="voice-link-btn voice-link-btn-danger"
                          phx-click="remove_glossary_entry"
                          phx-value-index={idx}
                        >
                          {gettext("Remove")}
                        </button>
                      <% end %>
                    </div>
                    <div class="voice-override-fields">
                      <div class="voice-field-row">
                        <div class={[
                          "voice-field",
                          glossary_entry_field_changed?(entry, @original_glossary_entries, :term) &&
                            "voice-field-changed"
                        ]}>
                          <label>{gettext("Term")}</label>
                          <input
                            type="text"
                            name={"entries[#{idx}][term]"}
                            value={entry.term || ""}
                            placeholder={gettext("e.g. API, workspace, deploy")}
                            required
                            disabled={!@can_glossary_submit?}
                            phx-debounce="300"
                          />
                        </div>
                        <div class={[
                          "voice-field",
                          glossary_entry_field_changed?(
                            entry,
                            @original_glossary_entries,
                            :case_sensitive
                          ) && "voice-field-changed"
                        ]}>
                          <label>{gettext("Case sensitive")}</label>
                          <select
                            name={"entries[#{idx}][case_sensitive]"}
                            disabled={!@can_glossary_submit?}
                            phx-debounce="300"
                          >
                            <option value="false" selected={!entry.case_sensitive}>
                              {gettext("No")}
                            </option>
                            <option value="true" selected={entry.case_sensitive}>
                              {gettext("Yes")}
                            </option>
                          </select>
                        </div>
                      </div>
                      <div class={[
                        "voice-field",
                        glossary_entry_field_changed?(
                          entry,
                          @original_glossary_entries,
                          :definition
                        ) && "voice-field-changed"
                      ]}>
                        <label>{gettext("Definition")}</label>
                        <input
                          type="text"
                          name={"entries[#{idx}][definition]"}
                          value={entry.definition || ""}
                          placeholder={gettext("Context or description (optional)")}
                          disabled={!@can_glossary_submit?}
                          phx-debounce="300"
                        />
                      </div>
                      <div class="glossary-translations-section">
                        <div class="glossary-translations-header">
                          <span class="voice-diff-label">{gettext("Translations")}</span>
                          <%= if @can_glossary_submit? do %>
                            <button
                              type="button"
                              class="voice-link-btn"
                              phx-click="add_glossary_translation"
                              phx-value-entry-index={idx}
                            >
                              <svg
                                width="14"
                                height="14"
                                viewBox="0 0 20 20"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                aria-hidden="true"
                              >
                                <line x1="10" y1="4" x2="10" y2="16" /><line
                                  x1="4"
                                  y1="10"
                                  x2="16"
                                  y2="10"
                                />
                              </svg>
                              {gettext("Add")}
                            </button>
                          <% end %>
                        </div>
                        <%= for {translation, tidx} <- Enum.with_index(entry.translations || []) do %>
                          <div class={[
                            "glossary-translation-row",
                            glossary_translation_changed?(
                              entry,
                              translation,
                              @original_glossary_entries
                            ) && "glossary-translation-row-changed"
                          ]}>
                            <div class="voice-field">
                              <.locale_picker
                                id={"locale-picker-#{idx}-#{tidx}"}
                                name={"entries[#{idx}][translations][#{tidx}][locale]"}
                                value={translation.locale || ""}
                                disabled={!@can_glossary_submit?}
                              />
                            </div>
                            <div
                              class={[
                                "voice-field",
                                glossary_translation_changed?(
                                  entry,
                                  translation,
                                  @original_glossary_entries
                                ) && "voice-field-changed"
                              ]}
                              style="flex: 1;"
                            >
                              <input
                                type="text"
                                name={"entries[#{idx}][translations][#{tidx}][translation]"}
                                value={translation.translation || ""}
                                placeholder={gettext("Translation")}
                                disabled={!@can_glossary_submit?}
                                phx-debounce="300"
                              />
                            </div>
                            <%= if @can_glossary_submit? do %>
                              <button
                                type="button"
                                class="voice-link-btn voice-link-btn-danger"
                                phx-click="remove_glossary_translation"
                                phx-value-entry-index={idx}
                                phx-value-translation-index={tidx}
                              >
                                {gettext("Remove")}
                              </button>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
              <%= if @can_glossary_submit? do %>
                <div class="voice-card-footer" style="justify-content: flex-start;">
                  <button type="button" class="voice-link-btn" phx-click="add_glossary_entry">
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 20 20"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      aria-hidden="true"
                    >
                      <line x1="10" y1="4" x2="10" y2="16" /><line x1="4" y1="10" x2="16" y2="10" />
                    </svg>
                    {gettext("Add term")}
                  </button>
                </div>
              <% end %>
            </div>
          </div>

          <%= if (not @suggestion_mode?) and @glossary_versions != [] do %>
            <div class="voice-section-divider"></div>

            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Version history")}</h2>
                <p>{gettext("Previous versions of your glossary.")}</p>
              </div>
              <.resource_table id="glossary-versions" rows={@glossary_versions}>
                <:col :let={v} label={gettext("Version")} class="resource-col-nowrap">
                  <.link
                    patch={"/" <> @handle <> "/-/glossary/" <> to_string(v.version)}
                    class="voice-history-link"
                  >
                    {"##{v.version}"}
                  </.link>
                </:col>
                <:col :let={v} label={gettext("Note")}>{v.change_note || "-"}</:col>
                <:col :let={v} label={gettext("Date")} class="resource-col-nowrap">
                  <time datetime={DateTime.to_iso8601(v.inserted_at)}>
                    {Calendar.strftime(v.inserted_at, "%b %d, %Y %H:%M")}
                  </time>
                </:col>
                <:col :let={v} label={gettext("By")} class="resource-col-nowrap">
                  <%= if v.created_by do %>
                    <span class="voice-author-chip">
                      <img
                        src={gravatar_url(v.created_by.email)}
                        alt=""
                        width="20"
                        height="20"
                        class="voice-author-avatar"
                      />
                      <span>
                        {(v.created_by.account && v.created_by.account.handle) ||
                          v.created_by.email}
                      </span>
                    </span>
                  <% else %>
                    -
                  <% end %>
                </:col>
              </.resource_table>
            </div>
          <% end %>

          <%= if (not @suggestion_mode?) and @glossary_suggestions != [] do %>
            <div class="voice-section-divider"></div>

            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Open suggestions")}</h2>
                <p>{gettext("Pending glossary proposals from contributors.")}</p>
              </div>
              <.resource_table id="glossary-suggestions" rows={@glossary_suggestions}>
                <:col :let={ticket} label={gettext("Suggestion")} class="resource-col-nowrap">
                  <.link
                    patch={"/" <> @handle <> "/-/discussions/" <> Integer.to_string(ticket.number)}
                    class="voice-history-link"
                  >
                    {"##{ticket.number}"}
                  </.link>
                </:col>
                <:col :let={ticket} label={gettext("Title")}>{ticket.title}</:col>
                <:col :let={ticket} label={gettext("By")} class="resource-col-nowrap">
                  <%= if ticket.user do %>
                    <span class="voice-author-chip">
                      <img
                        src={gravatar_url(ticket.user.email)}
                        alt=""
                        width="20"
                        height="20"
                        class="voice-author-avatar"
                      />
                      <span>
                        {(ticket.user.account && ticket.user.account.handle) || ticket.user.email}
                      </span>
                    </span>
                  <% else %>
                    -
                  <% end %>
                </:col>
                <:col :let={ticket} label={gettext("Date")} class="resource-col-nowrap">
                  <time datetime={DateTime.to_iso8601(ticket.inserted_at)}>
                    {Calendar.strftime(ticket.inserted_at, "%b %d, %Y %H:%M")}
                  </time>
                </:col>
              </.resource_table>
            </div>
          <% end %>
        <% end %>

        <%= if @suggestion_mode? do %>
          <div class="ticket-form-actions">
            <.link
              patch={@glossary_back_path || "/" <> @handle <> "/-/glossary"}
              class="dash-btn dash-btn-secondary"
            >
              {gettext("Cancel")}
            </.link>
            <button type="submit" class="dash-btn dash-btn-primary">
              {gettext("Submit suggestion")}
            </button>
          </div>
        <% else %>
          <%= if @can_glossary_submit? do %>
            <.save_bar
              id="glossary-save-bar"
              form="glossary-form"
              visible={@glossary_changed?}
              discard_event="glossary_discard"
              change_summary={@change_summary}
              generating_summary?={@generating_summary?}
              state_label={gettext("Ready to suggest changes")}
              submit_label={gettext("Suggest changes")}
              show_note={false}
            />
          <% end %>
        <% end %>
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Glossary version (diff view)
  # ---------------------------------------------------------------------------

  defp glossary_version_page(assigns) do
    ~H"""
    <div class="dash-page">
      <div class="dash-page-header">
        <div class="voice-version-header">
          <h1>
            <span>{"##{@glossary.version}"}</span>
            <%= if @glossary.change_note do %>
              <span class="voice-version-title-note">{@glossary.change_note}</span>
            <% end %>
          </h1>
          <p class="voice-version-meta">
            <time datetime={DateTime.to_iso8601(@glossary.inserted_at)}>
              {Calendar.strftime(@glossary.inserted_at, "%b %d, %Y at %H:%M")}
            </time>
            <%= if @glossary.created_by do %>
              <span class="voice-version-meta-sep">&middot;</span>
              <span class="voice-author-chip">
                <img
                  src={gravatar_url(@glossary.created_by.email)}
                  alt=""
                  width="20"
                  height="20"
                  class="voice-author-avatar"
                />
                <span>
                  {(@glossary.created_by.account && @glossary.created_by.account.handle) ||
                    @glossary.created_by.email}
                </span>
              </span>
            <% end %>
          </p>
        </div>
      </div>

      <div class="voice-section">
        <div class="voice-section-info">
          <h2>{gettext("Terms")}</h2>
          <p>{gettext("Glossary entries in this version.")}</p>
        </div>
        <div class="voice-card">
          <div class="voice-card-fields">
            <% current_terms = MapSet.new(Enum.map(@glossary.entries, & &1.term))

            prev_terms =
              if @previous_glossary,
                do: MapSet.new(Enum.map(@previous_glossary.entries, & &1.term)),
                else: MapSet.new()

            all_terms =
              MapSet.union(current_terms, prev_terms)
              |> Enum.sort() %>
            <%= for term <- all_terms do %>
              <% cur = Enum.find(@glossary.entries, &(&1.term == term))

              prev =
                if @previous_glossary, do: Enum.find(@previous_glossary.entries, &(&1.term == term))

              status =
                cond do
                  cur && !prev -> :added
                  !cur && prev -> :removed
                  true -> :existing
                end %>
              <div class={"voice-override-diff-block voice-override-diff-#{status}"}>
                <div class="voice-override-diff-header">
                  <span class="voice-override-locale">{term}</span>
                  <%= case status do %>
                    <% :added -> %>
                      <span class="voice-diff-badge voice-diff-badge-added">{gettext("Added")}</span>
                    <% :removed -> %>
                      <span class="voice-diff-badge voice-diff-badge-removed">
                        {gettext("Removed")}
                      </span>
                    <% _ -> %>
                  <% end %>
                </div>
                <div class="voice-override-diff-fields">
                  <.diff_field
                    label={gettext("Definition")}
                    current={cur && cur.definition}
                    previous={prev && prev.definition}
                  />
                  <div class="glossary-translations-diff">
                    <span class="voice-diff-label">{gettext("Translations")}</span>
                    <% cur_translations = if(cur, do: cur.translations || [], else: [])
                    prev_translations = if(prev, do: prev.translations || [], else: [])
                    cur_locales = MapSet.new(Enum.map(cur_translations, & &1.locale))
                    prev_locales = MapSet.new(Enum.map(prev_translations, & &1.locale))
                    all_locales = MapSet.union(cur_locales, prev_locales) |> Enum.sort() %>
                    <%= for locale <- all_locales do %>
                      <% cur_t = Enum.find(cur_translations, &(&1.locale == locale))
                      prev_t = Enum.find(prev_translations, &(&1.locale == locale)) %>
                      <div class="glossary-translation-diff-row">
                        <span class="glossary-translation-diff-locale">{locale}</span>
                        <.diff_field
                          label=""
                          current={cur_t && cur_t.translation}
                          previous={prev_t && prev_t.translation}
                        />
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Project (placeholder)
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Page: Members
  # ---------------------------------------------------------------------------

  defp members_page(assigns) do
    assigns =
      assign(
        assigns,
        :role_filter_options,
        Enum.map(assigns.member_roles, fn r -> %{value: r, label: String.capitalize(r)} end)
      )

    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Members")}
        description={gettext("Manage who has access to this account.")}
      />

      <div class="members-invite-section">
        <h2>{gettext("Invite a new member")}</h2>
        <.form
          for={@invite_form}
          id="invite-form"
          phx-submit="send_invitation"
          class="members-invite-form"
        >
          <div class="members-invite-fields">
            <div class="voice-field">
              <label for="invite_email">{gettext("Email address")}</label>
              <input
                type="email"
                id="invite_email"
                name="invite[email]"
                value={@invite_form[:email].value}
                required
                placeholder={gettext("colleague@example.com")}
              />
            </div>
            <div class="voice-field">
              <label for="invite_role">{gettext("Role")}</label>
              <select id="invite_role" name="invite[role]">
                <option value="member" selected={@invite_form[:role].value == "member"}>
                  {gettext("Member")}
                </option>
                <option value="admin" selected={@invite_form[:role].value == "admin"}>
                  {gettext("Admin")}
                </option>
              </select>
            </div>
          </div>
          <button type="submit" class="dash-btn dash-btn-primary">
            {gettext("Send invitation")}
          </button>
        </.form>
      </div>

      <div class="members-section">
        <h2>{gettext("Current members")}</h2>
        <.resource_table
          id="members-table"
          rows={@members}
          search={@members_search}
          search_placeholder={gettext("Search members...")}
          sort_key={@members_sort_key}
          sort_dir={@members_sort_dir}
          filters={[%{key: "role", label: gettext("Role"), options: @role_filter_options}]}
          active_filters={@members_filters}
          page={@members_page}
          per_page={10}
          total={@members_total}
        >
          <:col :let={member} label={gettext("Name")} key="name" sortable>
            <span class="voice-author-chip">
              <img
                src={gravatar_url(member.user.email)}
                alt=""
                width="24"
                height="24"
                class="voice-author-avatar"
              />
              <span>{member.user.name || member.user.email}</span>
            </span>
          </:col>
          <:col :let={member} label={gettext("Email")} key="email" sortable>
            {member.user.email}
          </:col>
          <:col :let={member} label={gettext("Role")} key="role" sortable>
            <span class={"members-role-badge members-role-#{member.role}"}>
              {String.capitalize(member.role)}
            </span>
          </:col>
          <:col
            :let={member}
            label={gettext("Joined")}
            key="joined"
            sortable
            class="resource-col-nowrap"
          >
            <time datetime={DateTime.to_iso8601(member.inserted_at)}>
              {Calendar.strftime(member.inserted_at, "%b %d, %Y")}
            </time>
          </:col>
          <:action :let={member}>
            <%= if @can_write && @current_user && member.user.id != @current_user.id do %>
              <button
                type="button"
                class="voice-link-btn voice-link-btn-danger"
                phx-click="remove_member"
                phx-value-user-id={member.user.id}
                data-confirm={gettext("Are you sure you want to remove this member?")}
              >
                {gettext("Remove")}
              </button>
            <% end %>
          </:action>
        </.resource_table>
      </div>

      <%= if @all_invitations != [] do %>
        <div class="members-section">
          <h2>{gettext("Pending invitations")}</h2>
          <.resource_table
            id="invitations-table"
            rows={@pending_invitations}
            search={@invitations_search}
            search_placeholder={gettext("Search invitations...")}
            sort_key={@invitations_sort_key}
            sort_dir={@invitations_sort_dir}
          >
            <:col :let={inv} label={gettext("Email")} key="email" sortable>
              {inv.email}
            </:col>
            <:col :let={inv} label={gettext("Role")} key="role" sortable>
              <span class={"members-role-badge members-role-#{inv.role}"}>
                {String.capitalize(inv.role)}
              </span>
            </:col>
            <:col :let={inv} label={gettext("Invited by")} key="invited_by" sortable>
              <%= if inv.invited_by do %>
                {inv.invited_by.name || inv.invited_by.email}
              <% else %>
                -
              <% end %>
            </:col>
            <:col
              :let={inv}
              label={gettext("Expires")}
              key="expires"
              sortable
              class="resource-col-nowrap"
            >
              <time datetime={DateTime.to_iso8601(inv.expires_at)}>
                {Calendar.strftime(inv.expires_at, "%b %d, %Y")}
              </time>
            </:col>
            <:action :let={inv}>
              <button
                type="button"
                class="voice-link-btn voice-link-btn-danger"
                phx-click="revoke_invitation"
                phx-value-id={inv.id}
              >
                {gettext("Revoke")}
              </button>
            </:action>
          </.resource_table>
        </div>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: API Tokens
  # ---------------------------------------------------------------------------

  attr :live_action, :atom, required: true
  attr :handle, :string, required: true
  attr :api_tokens, :list, default: []
  attr :available_scopes, :list, default: []
  attr :token_form, :any, default: nil
  attr :newly_created_token, :string, default: nil
  attr :token_form_valid?, :boolean, default: false
  attr :tokens_sort_key, :string, default: "inserted_at"
  attr :tokens_sort_dir, :string, default: "desc"
  attr :editing_token, :any, default: nil
  attr :token_edit_form, :any, default: nil
  attr :token_edit_changed?, :boolean, default: false

  defp api_tokens_page(assigns) do
    scope_groups =
      assigns.available_scopes
      |> Enum.group_by(fn scope -> scope |> String.split(":") |> List.first() end)
      |> Enum.sort_by(&elem(&1, 0))

    selected_scopes =
      if assigns[:token_edit_form],
        do: List.wrap(assigns.token_edit_form[:scopes].value),
        else: []

    assigns =
      assigns
      |> assign(:scope_groups, scope_groups)
      |> assign(:selected_scopes, selected_scopes)

    ~H"""
    <div class="dash-page">
      <%= cond do %>
        <% @live_action == :api_tokens_new -> %>
          <.page_header title={gettext("New account token")} />

          <.form
            for={@token_form}
            id="token-form"
            phx-submit="create_token"
            phx-change="validate_token"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Token details")}</h2>
                <p>{gettext("Give your token a descriptive name and select the scopes it needs.")}</p>
              </div>
              <div class="voice-card">
                <div class="voice-card-fields">
                  <div class="voice-field">
                    <label for="token-name">{gettext("Name")}</label>
                    <input
                      type="text"
                      id="token-name"
                      name="token[name]"
                      value={@token_form[:name].value}
                      required
                      placeholder={gettext("e.g. CI Pipeline Token")}
                    />
                  </div>
                  <div class="voice-field">
                    <label for="token-description">{gettext("Description")}</label>
                    <input
                      type="text"
                      id="token-description"
                      name="token[description]"
                      value={@token_form[:description].value}
                      placeholder={gettext("What is this token for?")}
                    />
                  </div>
                  <div class="voice-field">
                    <label for="token-expiration">{gettext("Expiration")}</label>
                    <select id="token-expiration" name="token[expiration]">
                      <option value="30">{gettext("30 days")}</option>
                      <option value="60">{gettext("60 days")}</option>
                      <option value="90" selected>{gettext("90 days")}</option>
                      <option value="never">{gettext("No expiration")}</option>
                    </select>
                    <span class="voice-field-help">
                      {gettext("Tokens with no expiration are a security risk.")}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div class="voice-section-divider"></div>

            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Scopes")}</h2>
                <p>
                  {gettext(
                    "Select the permissions this token should have. Only grant the minimum scopes needed."
                  )}
                </p>
              </div>
              <div class="voice-card">
                <div class="voice-card-fields">
                  <%= for {group, scopes} <- @scope_groups do %>
                    <div class="api-scope-group">
                      <div class="api-scope-group-title">{humanize_scope_group(group)}</div>
                      <div class="api-scope-grid">
                        <%= for scope <- scopes do %>
                          <label class="api-scope-item">
                            <input type="checkbox" name="token[scopes][]" value={scope} />
                            <span>{humanize_scope_action(scope)}</span>
                          </label>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <.form_save_bar
              id="token-save-bar"
              visible={@token_form_valid?}
              cancel_path={"/" <> @handle <> "/-/settings/tokens"}
            />
          </.form>
        <% @live_action == :api_token_edit -> %>
          <.page_header title={@editing_token.name} />

          <.form
            for={@token_edit_form}
            id="token-edit-form"
            phx-submit="update_token"
            phx-change="validate_token_edit"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Token details")}</h2>
              </div>
              <div class="voice-card">
                <div class="voice-card-fields">
                  <div class="voice-field">
                    <label for="edit-token-name">{gettext("Name")}</label>
                    <input
                      type="text"
                      id="edit-token-name"
                      name="token[name]"
                      value={@token_edit_form[:name].value}
                      required
                    />
                  </div>
                  <div class="voice-field">
                    <label for="edit-token-description">{gettext("Description")}</label>
                    <input
                      type="text"
                      id="edit-token-description"
                      name="token[description]"
                      value={@token_edit_form[:description].value}
                      placeholder={gettext("What is this token for?")}
                    />
                  </div>
                  <div class="voice-field">
                    <label>{gettext("Token prefix")}</label>
                    <input
                      type="text"
                      value={"#{@editing_token.token_prefix}..."}
                      disabled
                      style="opacity: 0.6; cursor: not-allowed;"
                    />
                  </div>
                  <div class="voice-field">
                    <label>{gettext("Expires")}</label>
                    <input
                      type="text"
                      value={
                        if @editing_token.expires_at,
                          do: Calendar.strftime(@editing_token.expires_at, "%b %d, %Y"),
                          else: gettext("Never")
                      }
                      disabled
                      style="opacity: 0.6; cursor: not-allowed;"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="voice-section-divider"></div>

            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Scopes")}</h2>
                <p>
                  {gettext(
                    "Select the permissions this token should have. Only grant the minimum scopes needed."
                  )}
                </p>
              </div>
              <div class="voice-card">
                <div class="voice-card-fields">
                  <%= for {group, scopes} <- @scope_groups do %>
                    <div class="api-scope-group">
                      <div class="api-scope-group-title">{humanize_scope_group(group)}</div>
                      <div class="api-scope-grid">
                        <%= for scope <- scopes do %>
                          <label class="api-scope-item">
                            <input
                              type="checkbox"
                              name="token[scopes][]"
                              value={scope}
                              checked={scope in @selected_scopes}
                            />
                            <span>{humanize_scope_action(scope)}</span>
                          </label>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <.form_save_bar
              id="token-edit-save-bar"
              visible={@token_edit_changed?}
              cancel_path={"/" <> @handle <> "/-/settings/tokens"}
            />
          </.form>

          <div class="voice-section-divider"></div>

          <div class="api-action-section api-action-danger">
            <div class="api-action-info">
              <h2>{gettext("Revoke token")}</h2>
              <p>
                {gettext(
                  "Revoking this token will immediately prevent any applications using it from accessing the API."
                )}
              </p>
            </div>
            <button
              class="dash-btn dash-btn-danger"
              phx-click="revoke_token"
              phx-value-id={@editing_token.id}
              data-confirm={
                gettext(
                  "Are you sure you want to revoke this token? Any applications using this token will no longer be able to access the API."
                )
              }
            >
              {gettext("Revoke token")}
            </button>
          </div>
        <% true -> %>
          <.page_header
            title={gettext("Account tokens")}
            description={
              gettext("Tokens you have generated that can be used to access the Glossia API.")
            }
          >
            <:actions>
              <.link
                patch={"/" <> @handle <> "/-/settings/tokens/new"}
                class="dash-btn dash-btn-primary"
              >
                {gettext("Generate new token")}
              </.link>
            </:actions>
          </.page_header>

          <%= if @newly_created_token do %>
            <div class="api-token-reveal" id="token-reveal">
              <p>
                {gettext(
                  "Make sure to copy your account token now. You will not be able to see it again."
                )}
              </p>
              <div class="api-token-reveal-value">
                <code id="token-value">{@newly_created_token}</code>
                <button
                  type="button"
                  class="dash-btn dash-btn-secondary"
                  phx-hook=".CopyToken"
                  id="copy-token-btn"
                  data-value={@newly_created_token}
                >
                  {gettext("Copy")}
                </button>
              </div>
            </div>
            <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyToken">
              export default {
                mounted() {
                  this.el.addEventListener("click", () => {
                    var value = this.el.getAttribute("data-value");
                    var original = this.el.innerHTML;
                    navigator.clipboard.writeText(value).then(() => {
                      var svg = this.el.querySelector("svg");
                      if (svg) {
                        svg.innerHTML = '<polyline points="20 6 9 17 4 12"></polyline>';
                      } else {
                        this.el.textContent = "Copied!";
                      }
                      setTimeout(() => { this.el.innerHTML = original; }, 1500);
                    });
                  });
                }
              }
            </script>
          <% end %>

          <.resource_table
            id="tokens-table"
            rows={@api_tokens}
            search=""
            search_placeholder={gettext("Search tokens...")}
            sort_key={@tokens_sort_key}
            sort_dir={@tokens_sort_dir}
          >
            <:col :let={token} label={gettext("Name")} key="name" sortable>
              <.link
                patch={"/" <> @handle <> "/-/settings/tokens/" <> token.id}
                class="voice-link-btn"
              >
                {token.name}
              </.link>
            </:col>
            <:col :let={token} label={gettext("Scopes")} key="scopes">
              <% scopes = String.split(token.scope || "", " ", trim: true) %>
              <span style="white-space: nowrap;">
                {Enum.take(scopes, 2) |> Enum.map(&humanize_scope/1) |> Enum.join(", ")}
                <%= if length(scopes) > 2 do %>
                  , ...
                <% end %>
              </span>
            </:col>
            <:col :let={token} label={gettext("Last used")} key="last_used_at" sortable>
              <%= if token.last_used_at do %>
                <time datetime={DateTime.to_iso8601(token.last_used_at)} style="white-space: nowrap;">
                  {Calendar.strftime(token.last_used_at, "%b %d, %Y")}
                </time>
              <% else %>
                <span class="muted">{gettext("Never")}</span>
              <% end %>
            </:col>
            <:col :let={token} label={gettext("Expires")} key="expires_at" sortable>
              <%= if token.expires_at do %>
                <time datetime={DateTime.to_iso8601(token.expires_at)} style="white-space: nowrap;">
                  {Calendar.strftime(token.expires_at, "%b %d, %Y")}
                </time>
              <% else %>
                <span>{gettext("Never")}</span>
              <% end %>
            </:col>
            <:empty>
              <div class="dash-empty-state">
                <svg
                  width="32"
                  height="32"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  aria-hidden="true"
                >
                  <path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4" />
                  <path d="m21 2-9.6 9.6" />
                  <circle cx="7.5" cy="15.5" r="5.5" />
                </svg>
                <h2>{gettext("No tokens yet")}</h2>
                <p>{gettext("Account tokens allow you to authenticate with the Glossia API.")}</p>
              </div>
            </:empty>
          </.resource_table>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: OAuth Applications
  # ---------------------------------------------------------------------------

  attr :live_action, :atom, required: true
  attr :handle, :string, required: true
  attr :oauth_apps, :list, default: []
  attr :oauth_app, :any, default: nil
  attr :boruta_client, :any, default: nil
  attr :app_form, :any, default: nil
  attr :newly_created_secret, :any, default: nil
  attr :newly_regenerated_secret, :string, default: nil
  attr :app_form_valid?, :boolean, default: false
  attr :app_edit_changed?, :boolean, default: false
  attr :apps_sort_key, :string, default: "inserted_at"
  attr :apps_sort_dir, :string, default: "desc"

  defp api_apps_page(assigns) do
    ~H"""
    <div class="dash-page">
      <%= cond do %>
        <% @live_action == :api_apps_new -> %>
          <.page_header title={gettext("Register a new OAuth application")} />

          <.form
            for={@app_form}
            id="oauth-app-form"
            phx-submit="create_oauth_app"
            phx-change="validate_oauth_app"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Application details")}</h2>
                <p>
                  {gettext(
                    "Register an OAuth application to allow users to sign in with Glossia or to let external services access your account."
                  )}
                </p>
              </div>
              <div class="voice-card">
                <div class="voice-card-fields">
                  <div class="voice-field">
                    <label for="app-name">{gettext("Application name")}</label>
                    <input
                      type="text"
                      id="app-name"
                      name="app[name]"
                      value={@app_form[:name].value}
                      required
                    />
                  </div>
                  <div class="voice-field">
                    <label for="app-description">{gettext("Description")}</label>
                    <textarea
                      id="app-description"
                      name="app[description]"
                      rows="3"
                    >{@app_form[:description].value}</textarea>
                  </div>
                  <div class="voice-field">
                    <label for="app-homepage">{gettext("Homepage URL")}</label>
                    <input
                      type="url"
                      id="app-homepage"
                      name="app[homepage_url]"
                      value={@app_form[:homepage_url].value}
                      placeholder="https://example.com"
                    />
                  </div>
                  <div class="voice-field">
                    <label for="app-redirect">{gettext("Authorization callback URL")}</label>
                    <input
                      type="url"
                      id="app-redirect"
                      name="app[redirect_uris]"
                      value={@app_form[:redirect_uris].value}
                      required
                      placeholder="https://example.com/callback"
                    />
                    <span class="voice-field-help">
                      {gettext("The URL where users will be redirected after authorization.")}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <.form_save_bar
              id="oauth-app-save-bar"
              visible={@app_form_valid?}
              cancel_path={"/" <> @handle <> "/-/settings/apps"}
            />
          </.form>
        <% @live_action == :api_app_edit -> %>
          <.page_header title={@oauth_app.name} />

          <%= if @newly_regenerated_secret do %>
            <div class="api-token-reveal" id="secret-reveal">
              <p>
                {gettext(
                  "Make sure to copy your new client secret now. You will not be able to see it again."
                )}
              </p>
              <div class="api-token-reveal-value">
                <code>{@newly_regenerated_secret}</code>
                <button
                  type="button"
                  class="dash-btn dash-btn-secondary"
                  phx-hook=".CopyToken"
                  id="copy-secret-btn"
                  data-value={@newly_regenerated_secret}
                >
                  {gettext("Copy")}
                </button>
              </div>
            </div>
          <% end %>

          <.form
            for={@app_form}
            id="oauth-app-edit-form"
            phx-submit="update_oauth_app"
            phx-change="validate_oauth_app_edit"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Application details")}</h2>
              </div>
              <div class="voice-card">
                <div class="voice-card-fields">
                  <div class="voice-field">
                    <label>{gettext("Client ID")}</label>
                    <input
                      type="text"
                      value={@boruta_client.id}
                      disabled
                      style="opacity: 0.6; cursor: not-allowed;"
                    />
                  </div>
                  <div class="voice-field">
                    <label for="edit-app-name">{gettext("Application name")}</label>
                    <input
                      type="text"
                      id="edit-app-name"
                      name="app[name]"
                      value={@app_form[:name].value}
                      required
                    />
                  </div>
                  <div class="voice-field">
                    <label for="edit-app-description">{gettext("Description")}</label>
                    <textarea
                      id="edit-app-description"
                      name="app[description]"
                      rows="3"
                    >{@app_form[:description].value}</textarea>
                  </div>
                  <div class="voice-field">
                    <label for="edit-app-homepage">{gettext("Homepage URL")}</label>
                    <input
                      type="url"
                      id="edit-app-homepage"
                      name="app[homepage_url]"
                      value={@app_form[:homepage_url].value}
                      placeholder="https://example.com"
                    />
                  </div>
                  <div class="voice-field">
                    <label for="edit-app-redirect">{gettext("Authorization callback URL")}</label>
                    <input
                      type="url"
                      id="edit-app-redirect"
                      name="app[redirect_uris]"
                      value={@app_form[:redirect_uris].value}
                      placeholder="https://example.com/callback"
                    />
                  </div>
                </div>
              </div>
            </div>

            <.form_save_bar
              id="oauth-app-edit-save-bar"
              visible={@app_edit_changed?}
              cancel_path={"/" <> @handle <> "/-/settings/apps"}
            />
          </.form>

          <div class="voice-section-divider"></div>

          <div class="api-action-section">
            <div class="api-action-info">
              <h2>{gettext("Client secret")}</h2>
              <p>{gettext("Regenerate the client secret if you believe it has been compromised.")}</p>
            </div>
            <button
              class="dash-btn dash-btn-secondary"
              phx-click="regenerate_secret"
              phx-value-id={@oauth_app.id}
              data-confirm={
                gettext(
                  "Are you sure? Existing integrations using the current secret will stop working."
                )
              }
            >
              {gettext("Regenerate client secret")}
            </button>
          </div>

          <div class="api-action-section api-action-danger">
            <div class="api-action-info">
              <h2>{gettext("Danger zone")}</h2>
              <p>
                {gettext(
                  "Deleting this application will revoke all tokens issued through it and break any integrations using it."
                )}
              </p>
            </div>
            <button
              class="dash-btn dash-btn-danger"
              phx-click="delete_oauth_app"
              phx-value-id={@oauth_app.id}
              data-confirm={
                gettext(
                  "Are you sure you want to delete this application? This action cannot be undone."
                )
              }
            >
              {gettext("Delete application")}
            </button>
          </div>
        <% true -> %>
          <.page_header
            title={gettext("OAuth applications")}
            description={
              gettext(
                "OAuth applications allow external services to access Glossia on behalf of users."
              )
            }
          >
            <:actions>
              <.link
                patch={"/" <> @handle <> "/-/settings/apps/new"}
                class="dash-btn dash-btn-primary"
              >
                {gettext("Register new application")}
              </.link>
            </:actions>
          </.page_header>

          <%= if @newly_created_secret do %>
            <div class="api-token-reveal" id="app-secret-reveal">
              <p>
                {gettext(
                  "Make sure to copy your client secret now. You will not be able to see it again."
                )}
              </p>
              <div class="api-token-reveal-credentials">
                <div class="api-token-reveal-field">
                  <strong>{gettext("Client ID")}</strong>
                  <code>{@newly_created_secret.client_id}</code>
                </div>
                <div class="api-token-reveal-field">
                  <strong>{gettext("Client Secret")}</strong>
                  <code>{@newly_created_secret.client_secret}</code>
                </div>
              </div>
            </div>
          <% end %>

          <.resource_table
            id="oauth-apps-table"
            rows={@oauth_apps}
            search=""
            search_placeholder={gettext("Search applications...")}
            sort_key={@apps_sort_key}
            sort_dir={@apps_sort_dir}
          >
            <:col :let={app} label={gettext("Name")} key="name" sortable>
              <.link
                patch={"/" <> @handle <> "/-/settings/apps/" <> app.id}
                class="voice-link-btn"
              >
                {app.name}
              </.link>
            </:col>
            <:col :let={app} label={gettext("Client ID")} key="client_id">
              <span class="mono" style="font-size: var(--text-xs);">
                {app.boruta_client_id}
              </span>
            </:col>
            <:col :let={app} label={gettext("Created")} key="inserted_at" sortable>
              <time datetime={DateTime.to_iso8601(app.inserted_at)} style="white-space: nowrap;">
                {Calendar.strftime(app.inserted_at, "%b %d, %Y")}
              </time>
            </:col>
            <:empty>
              <div class="dash-empty-state">
                <svg
                  width="32"
                  height="32"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  aria-hidden="true"
                >
                  <rect x="2" y="3" width="20" height="14" rx="2" ry="2" />
                  <line x1="8" y1="21" x2="16" y2="21" />
                  <line x1="12" y1="17" x2="12" y2="21" />
                </svg>
                <h2>{gettext("No OAuth applications yet")}</h2>
                <p>
                  {gettext(
                    "Register an OAuth application to enable 'Sign in with Glossia' or to let external services access your account."
                  )}
                </p>
              </div>
            </:empty>
          </.resource_table>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Project
  # ---------------------------------------------------------------------------

  defp project_page(assigns) do
    project = assigns[:project]

    setup_pr_url =
      setup_pr_url(assigns[:setup_events] || []) ||
        setup_pr_url_from_audit(assigns[:account], project)

    assigns = assign(assigns, :setup_pr_url, setup_pr_url)

    ~H"""
    <div class="dash-page">
      <.page_header title={@project_name} />

      <%= if @project && @project.setup_status in ["pending", "running"] do %>
        <div class="setup-feed">
          <div class="setup-feed-header">
            <span class="setup-feed-pulse"></span>
            <h3>{gettext("Setting up localization...")}</h3>
          </div>
          <div class="setup-feed-events" id="setup-events" phx-hook=".SetupFeedScroll">
            <%= for event <- @setup_events do %>
              <.setup_event_item event={event} />
            <% end %>
          </div>
        </div>
        <script :type={Phoenix.LiveView.ColocatedHook} name=".SetupFeedScroll">
          export default {
            mounted() {
              this.scrollToBottom()
            },
            updated() {
              this.scrollToBottom()
            },
            scrollToBottom() {
              this.el.scrollTop = this.el.scrollHeight
            }
          }
        </script>
      <% else %>
        <%= if @project && @project.setup_status == "failed" do %>
          <div class="setup-feed">
            <div class="setup-feed-header setup-feed-header-error">
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line
                  x1="9"
                  y1="9"
                  x2="15"
                  y2="15"
                />
              </svg>
              <div class="setup-feed-header-copy">
                <h3>{gettext("Setup failed")}</h3>
                <p class="setup-feed-error-msg">
                  {@project.setup_error || gettext("An error occurred during setup.")}
                </p>
              </div>
            </div>
            <%= if @setup_events != [] do %>
              <details class="setup-feed-details">
                <summary>{gettext("View agent session")}</summary>
                <div class="setup-feed-events" id="setup-events">
                  <%= for event <- @setup_events do %>
                    <.setup_event_item event={event} />
                  <% end %>
                </div>
              </details>
            <% end %>
          </div>
        <% else %>
          <%= if @setup_pr_url do %>
            <div class="setup-pr-card">
              <span class="setup-pr-card-label">{gettext("Pull request ready")}</span>
              <a href={@setup_pr_url} target="_blank" rel="noopener noreferrer" class="setup-pr-link">
                {gettext("Open pull request")}
              </a>
            </div>
          <% else %>
            <%= if @project && @project.setup_status == "completed" do %>
              <div class="setup-pr-card">
                <span class="setup-pr-card-label">{gettext("Pull request unavailable")}</span>
                <p>
                  {gettext(
                    "Setup finished without a pull request link. Check setup events for details."
                  )}
                </p>
              </div>
            <% end %>
          <% end %>

          <%= if @setup_events != [] do %>
            <details class="setup-feed-details">
              <summary>{gettext("View setup session")}</summary>
              <div class="setup-feed">
                <div class="setup-feed-events" id="setup-events">
                  <%= for event <- @setup_events do %>
                    <.setup_event_item event={event} />
                  <% end %>
                </div>
              </div>
            </details>
          <% end %>

          <div class="dash-empty-state">
            <svg
              width="32"
              height="32"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z" />
              <polyline points="14 2 14 8 20 8" />
            </svg>
            <h2>{gettext("Project overview")}</h2>
            <%= if @project && @project.github_repo_full_name do %>
              <p>
                {gettext("Connected to")}
                <a
                  href={"https://github.com/#{@project.github_repo_full_name}"}
                  target="_blank"
                  rel="noopener"
                >
                  {@project.github_repo_full_name}
                </a>
              </p>
            <% else %>
              <p>{gettext("This is a placeholder for the project detail page.")}</p>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp project_settings_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Project settings")}
        description={gettext("Manage your project details and appearance.")}
      />

      <.form
        for={@project_settings_form}
        id="project-settings-form"
        phx-submit="update_project_settings"
        phx-change="validate_project_settings"
      >
        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("Avatar")}</h2>
            <p>{gettext("Upload an image to represent this project.")}</p>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <div class="voice-field">
                <div class="project-avatar-upload">
                  <% project_avatar_upload =
                    assigns[:uploads] && Map.get(assigns[:uploads], :project_avatar) %>
                  <% has_pending_upload =
                    project_avatar_upload && project_avatar_upload.entries != [] %>
                  <% pending_entry =
                    if(has_pending_upload, do: List.first(project_avatar_upload.entries)) %>
                  <%= if has_pending_upload do %>
                    <div class="project-avatar-preview-wrapper">
                      <.live_img_preview
                        entry={pending_entry}
                        class="project-avatar-img"
                      />
                      <button
                        type="button"
                        phx-click="cancel_project_avatar"
                        phx-value-ref={pending_entry.ref}
                        class="project-avatar-remove"
                        title={gettext("Remove")}
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <line x1="18" y1="6" x2="6" y2="18"></line>
                          <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                      </button>
                    </div>
                    <%= for err <- upload_errors(project_avatar_upload, pending_entry) do %>
                      <p class="project-avatar-error">
                        {upload_error_to_string(err)}
                      </p>
                    <% end %>
                  <% else %>
                    <label
                      for={if(project_avatar_upload, do: project_avatar_upload.ref, else: nil)}
                      class="project-avatar-placeholder"
                    >
                      <%= if @project_avatar_url do %>
                        <img
                          src={@project_avatar_url}
                          alt={gettext("Project avatar")}
                          class="project-avatar-img"
                        />
                      <% else %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          width="32"
                          height="32"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="1.5"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                          <circle cx="8.5" cy="8.5" r="1.5"></circle>
                          <polyline points="21 15 16 10 5 21"></polyline>
                        </svg>
                      <% end %>
                      <span class="project-avatar-hint">{gettext("Click to upload")}</span>
                    </label>
                  <% end %>
                  <%= if project_avatar_upload do %>
                    <.live_file_input
                      upload={project_avatar_upload}
                      class="project-avatar-file-input"
                    />
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("General")}</h2>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <div class="voice-field">
                <label for="project-name">{gettext("Name")}</label>
                <input
                  type="text"
                  id="project-name"
                  name="project[name]"
                  value={@project_settings_form[:name].value}
                  required
                />
              </div>
              <div class="voice-field">
                <label for="project-description">{gettext("Description")}</label>
                <textarea
                  id="project-description"
                  name="project[description]"
                  rows="3"
                  placeholder={gettext("A brief description of this project")}
                >{@project_settings_form[:description].value}</textarea>
              </div>
              <div class="voice-field">
                <label for="project-url">{gettext("URL")}</label>
                <input
                  type="url"
                  id="project-url"
                  name="project[url]"
                  value={@project_settings_form[:url].value}
                  placeholder="https://example.com"
                />
              </div>
            </div>
          </div>
        </div>

        <.form_save_bar
          id="project-settings-save-bar"
          visible={@project_settings_changed?}
          cancel_path={"/" <> @handle <> "/" <> @project.handle}
        />
      </.form>
    </div>
    """
  end

  defp project_avatar_display_url(nil), do: nil
  defp project_avatar_display_url(""), do: nil

  defp project_avatar_display_url(s3_path) do
    # Extract handle and project from the S3 path (avatars/{handle}/projects/{project}.{ext})
    case Regex.run(~r{avatars/([^/]+)/projects/([^/.]+)}, s3_path) do
      [_, handle, project_handle] -> "/avatars/#{handle}/projects/#{project_handle}"
      _ -> nil
    end
  end

  defp upload_error_to_string(:too_large), do: gettext("File is too large (max 5 MB)")
  defp upload_error_to_string(:not_accepted), do: gettext("File type not accepted")
  defp upload_error_to_string(:too_many_files), do: gettext("Too many files")
  defp upload_error_to_string(_), do: gettext("Upload error")

  defp project_activity_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Activity")}
        description={gettext("Recent content activity for this project.")}
      />

      <%= if @commits_error do %>
        <div class="dash-empty-state">
          <p>{gettext("Could not load activity from GitHub.")}</p>
        </div>
      <% else %>
        <.resource_table
          id="commits-table"
          rows={@commits}
          search={@commits_search}
          sort_key={@commits_sort_key}
          sort_dir={@commits_sort_dir}
        >
          <:col :let={commit} label={gettext("Commit")} key="message" sortable>
            <div class="commit-message-cell">
              <span class="commit-message-text">{first_line(commit.message)}</span>
              <%= if @sessions_by_sha[commit.sha] do %>
                <.link
                  navigate={
                    "/" <> @handle <> "/" <> @project.handle <> "/-/sessions/" <>
                      hd(@sessions_by_sha[commit.sha]).id
                  }
                  class={[
                    "commit-session-badge",
                    "commit-session-badge-#{hd(@sessions_by_sha[commit.sha]).status}"
                  ]}
                >
                  {hd(@sessions_by_sha[commit.sha]).status}
                </.link>
              <% end %>
            </div>
          </:col>
          <:col
            :let={commit}
            label={gettext("Author")}
            key="author"
            sortable
            class="resource-col-nowrap"
          >
            <div class="commit-author-cell">
              <%= if commit.author_avatar_url do %>
                <img
                  src={commit.author_avatar_url}
                  alt={commit.author_name}
                  class="commit-author-avatar"
                />
              <% end %>
              <span>{commit.author_name}</span>
            </div>
          </:col>
          <:col :let={commit} label={gettext("Date")} key="date" sortable class="resource-col-nowrap">
            <%= if commit.date do %>
              {relative_time(commit.date)}
            <% end %>
          </:col>
          <:action :let={commit}>
            <%= if @can_write and !@sessions_by_sha[commit.sha] do %>
              <button
                class="commit-translate-btn"
                phx-click="translate_commit"
                phx-value-sha={commit.sha}
                phx-value-message={commit.message}
              >
                {gettext("Translate")}
              </button>
            <% end %>
            <a href={commit.url} target="_blank" rel="noopener" class="commit-sha">
              {commit.short_sha}
            </a>
          </:action>
          <:empty>
            <p>{gettext("No commits yet.")}</p>
          </:empty>
        </.resource_table>
      <% end %>
    </div>
    """
  end

  defp project_translations_page(assigns) do
    assigns =
      assign(assigns,
        translation_filters: [
          %{
            key: "status",
            label: gettext("Status"),
            type: "select",
            options: [
              %{value: "pending", label: gettext("Pending")},
              %{value: "running", label: gettext("Running")},
              %{value: "completed", label: gettext("Completed")},
              %{value: "failed", label: gettext("Failed")}
            ]
          }
        ]
      )

    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Translations")}
        description={gettext("Translation sessions for this project.")}
      />

      <.resource_table
        id="translations-table"
        rows={@translations}
        search={@translations_search}
        sort_key={@translations_sort_key}
        sort_dir={@translations_sort_dir}
        page={@translations_page}
        total={@translations_total}
        filters={@translation_filters}
        active_filters={@translations_active_filters}
      >
        <:col :let={session} label={gettext("Status")} key="status" sortable>
          <span class={["badge", "badge-#{session.status}"]}>{session.status}</span>
        </:col>
        <:col :let={session} label={gettext("Languages")} key="languages">
          <%= if session.source_language do %>
            {session.source_language} &rarr; {Enum.join(session.target_languages || [], ", ")}
          <% end %>
        </:col>
        <:col :let={session} label={gettext("Commit")} key="commit" class="resource-col-nowrap">
          <%= if session.commit_sha do %>
            <span class="mono">{String.slice(session.commit_sha, 0, 7)}</span>
          <% end %>
        </:col>
        <:col
          :let={session}
          label={gettext("Created")}
          key="inserted_at"
          sortable
          class="resource-col-nowrap"
        >
          {Calendar.strftime(session.inserted_at, "%b %d, %Y %H:%M")}
        </:col>
        <:action :let={session}>
          <.link
            navigate={
              "/" <> @handle <> "/" <> @project.handle <> "/-/sessions/" <> session.id
            }
            class="button button-small"
          >
            {gettext("View")}
          </.link>
        </:action>
        <:empty>
          <p>{gettext("No translation sessions yet.")}</p>
        </:empty>
      </.resource_table>
    </div>
    """
  end

  defp session_detail_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Translation session")}
        description={
          if @session.commit_sha,
            do: gettext("Session for commit %{sha}", sha: String.slice(@session.commit_sha, 0, 7)),
            else: gettext("Translation session details")
        }
      />

      <div class="session-header">
        <div class="session-header-row">
          <span class={["badge", "badge-#{@session.status}"]}>{@session.status}</span>
          <%= if @session.source_language do %>
            <span class="session-header-languages">
              {@session.source_language} &rarr; {Enum.join(@session.target_languages, ", ")}
            </span>
          <% end %>
          <%= if @session.commit_sha && @project.github_repo_full_name do %>
            <a
              href={"https://github.com/#{@project.github_repo_full_name}/commit/#{@session.commit_sha}"}
              target="_blank"
              rel="noopener"
              class="commit-sha"
            >
              {String.slice(@session.commit_sha, 0, 7)}
            </a>
          <% end %>
        </div>
        <%= if @session.commit_message do %>
          <p class="session-header-commit-message">{@session.commit_message}</p>
        <% end %>
        <div class="session-header-meta">
          <%= if @session.started_at do %>
            <span>{gettext("Started %{time}", time: relative_time(@session.started_at))}</span>
          <% end %>
          <%= if @session.completed_at do %>
            <span>{gettext("Completed %{time}", time: relative_time(@session.completed_at))}</span>
          <% end %>
          <%= if @session.summary do %>
            <span>{@session.summary}</span>
          <% end %>
        </div>
      </div>

      <%= if @session_events == [] do %>
        <div class="dash-empty-state">
          <p>{gettext("No events recorded yet.")}</p>
        </div>
      <% else %>
        <div class="session-event-feed">
          <%= for event <- @session_events do %>
            <.session_event_item event={event} project={@project} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp session_event_item(%{event: event} = assigns) do
    event_type = event[:event_type] || Map.get(event, :event_type, "")
    content = event[:content] || Map.get(event, :content, "")

    assigns = assign(assigns, :event_type, event_type)
    assigns = assign(assigns, :content, content || "")

    ~H"""
    <%= case @event_type do %>
      <% "message" -> %>
        <div class="setup-event setup-event-message">
          <div class="setup-event-icon">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" />
            </svg>
          </div>
          <div class="setup-event-content">
            <p>{@content}</p>
          </div>
        </div>
      <% "thought" -> %>
        <div class="setup-event session-event-thought">
          <div class="setup-event-icon">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
            </svg>
          </div>
          <div class="setup-event-content">
            <p>{@content}</p>
          </div>
        </div>
      <% event_kind when event_kind in ["tool_call", "tool_result"] -> %>
        <div class={"setup-event setup-event-#{@event_type}"}>
          <div class="setup-event-icon">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <polyline points="4 17 10 11 4 5" /><line x1="12" y1="19" x2="20" y2="19" />
            </svg>
          </div>
          <div class="setup-event-content">
            <div class="setup-event-tool-header">
              <span class="setup-event-tool-name">{extract_session_tool_name(@event)}</span>
            </div>
            <%= if @content != "" do %>
              <pre class="setup-event-code">{@content}</pre>
            <% end %>
          </div>
        </div>
      <% "plan" -> %>
        <div class="setup-event session-event-plan">
          <div class="setup-event-icon">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M9 11l3 3L22 4" /><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11" />
            </svg>
          </div>
          <div class="setup-event-content">
            <div class="session-plan">
              <%= for step <- parse_plan_entries(@event) do %>
                <div class="session-plan-step" data-status={step["status"]}>
                  <%= case step["status"] do %>
                    <% "completed" -> %>
                      <span class="session-plan-icon">&check;</span>
                    <% "in_progress" -> %>
                      <span class="session-plan-icon">&bull;</span>
                    <% _ -> %>
                      <span class="session-plan-icon">&cir;</span>
                  <% end %>
                  <span>{step["label"]}</span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% _ -> %>
        <%= if @content != "" do %>
          <div class="setup-event">
            <div class="setup-event-content">
              <p>{@content}</p>
            </div>
          </div>
        <% end %>
    <% end %>
    """
  end

  defp extract_session_tool_name(event) do
    metadata = event[:metadata] || Map.get(event, :metadata, "")

    case metadata do
      m when is_binary(m) and m != "" ->
        case JSON.decode(m) do
          {:ok, %{"tool_name" => name}} -> name
          {:ok, %{"title" => title}} -> title
          _ -> metadata
        end

      _ ->
        ""
    end
  end

  defp parse_plan_entries(event) do
    metadata = event[:metadata] || Map.get(event, :metadata, "")

    case metadata do
      m when is_binary(m) and m != "" ->
        case JSON.decode(m) do
          {:ok, %{"entries" => entries}} when is_list(entries) -> entries
          _ -> []
        end

      _ ->
        []
    end
  end

  defp first_line(nil), do: ""

  defp first_line(message) do
    message |> String.split("\n", parts: 2) |> List.first() |> String.trim()
  end

  defp relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> gettext("just now")
      diff < 3600 -> gettext("%{count}m ago", count: div(diff, 60))
      diff < 86400 -> gettext("%{count}h ago", count: div(diff, 3600))
      diff < 604_800 -> gettext("%{count}d ago", count: div(diff, 86400))
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end

  defp setup_event_item(%{event: event} = assigns) do
    event_type = Map.get(event, :event_type, "")
    content = (Map.get(event, :content, "") || "") |> to_string()
    metadata = setup_event_metadata(event)
    tool_name = setup_event_tool_name(event_type, content, metadata)

    if skip_setup_event?(event_type, content) or
         not setup_event_has_visible_content?(event_type, content, tool_name) do
      ~H""
    else
      assigns =
        assigns
        |> assign(:content, content)
        |> assign(:event_type, event_type)
        |> assign(:tool_name, tool_name)
        |> assign(:variant, setup_event_variant(event_type))
        |> assign(:badge, setup_event_badge(event_type))

      ~H"""
      <div class={[
        "setup-event",
        "setup-event-#{@event_type}",
        "setup-event-variant-#{@variant}"
      ]}>
        <div class={["setup-event-icon", @variant == "error" && "setup-event-icon-error"]}>
          <%= case @event_type do %>
            <% "error" -> %>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <circle cx="12" cy="12" r="10" />
                <line x1="15" y1="9" x2="9" y2="15" />
                <line x1="9" y1="9" x2="15" y2="15" />
              </svg>
            <% "prompt" -> %>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <path d="M14 2H6a2 2 0 0 0-2 2v16l4-2 4 2 4-2 4 2V8z" />
                <line x1="10" y1="8" x2="10" y2="14" />
                <line x1="7" y1="11" x2="13" y2="11" />
              </svg>
            <% "pr_created" -> %>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07L12 4" />
                <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07L12 20" />
              </svg>
            <% event_kind when event_kind in ["tool_call", "tool_execution_start"] -> %>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <polyline points="4 17 10 11 4 5" /><line x1="12" y1="19" x2="20" y2="19" />
              </svg>
            <% event_kind when event_kind in ["tool_result", "tool_execution_end"] -> %>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <polyline points="20 6 9 17 4 12" />
              </svg>
            <% _ -> %>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
              </svg>
          <% end %>
        </div>

        <div class={["setup-event-content", @variant == "error" && "setup-event-content-error"]}>
          <div class="setup-event-meta">
            <span class={["setup-event-badge", "setup-event-badge-#{@variant}"]}>{@badge}</span>
            <%= if @tool_name != "" do %>
              <span class="setup-event-tool-name">{@tool_name}</span>
            <% end %>
          </div>

          <%= case @event_type do %>
            <% "pr_created" -> %>
              <p>{gettext("Pull request ready for review and merge.")}</p>
              <a href={@content} target="_blank" rel="noopener noreferrer" class="setup-pr-link">
                {gettext("Open pull request")}
              </a>
            <% "prompt" -> %>
              <p>{gettext("Setup brief sent to the agent.")}</p>
              <%= if @content != "" do %>
                <details class="setup-feed-details">
                  <summary>{gettext("View prompt")}</summary>
                  <pre class="setup-event-code setup-event-code-prompt">{@content}</pre>
                </details>
              <% end %>
            <% event_kind when event_kind in ["tool_call", "tool_execution_start"] -> %>
              <%= if @content != "" and @content != @tool_name do %>
                <p>{@content}</p>
              <% end %>
            <% event_kind when event_kind in ["tool_result", "tool_execution_end"] -> %>
              <%= if @content != "" do %>
                <pre class="setup-event-code">{@content}</pre>
              <% end %>
            <% _ -> %>
              <%= if @content != "" do %>
                <p>{@content}</p>
              <% end %>
          <% end %>
        </div>
      </div>
      """
    end
  end

  defp setup_event_has_visible_content?(event_type, content, tool_name) do
    content = String.trim(content || "")
    tool_name = String.trim(tool_name || "")

    case event_type do
      "prompt" ->
        true

      "pr_created" ->
        content != ""

      event_kind when event_kind in ["tool_call", "tool_execution_start"] ->
        content != "" and content != tool_name

      event_kind when event_kind in ["tool_result", "tool_execution_end"] ->
        content != ""

      _ ->
        content != ""
    end
  end

  defp setup_event_metadata(event) do
    metadata = Map.get(event, :metadata, "")

    case metadata do
      m when is_binary(m) and m != "" ->
        case JSON.decode(m) do
          {:ok, decoded} when is_map(decoded) -> decoded
          _ -> %{}
        end

      m when is_map(m) ->
        m

      _ ->
        %{}
    end
  end

  defp setup_event_tool_name(event_type, content, metadata) do
    values =
      case event_type do
        event_kind when event_kind in ["tool_call", "tool_execution_start"] ->
          [metadata["tool_name"], metadata["title"], metadata["name"], content]

        event_kind when event_kind in ["tool_result", "tool_execution_end"] ->
          [metadata["tool_name"], metadata["title"], metadata["name"]]

        _ ->
          []
      end

    first_present_string(values)
  end

  defp skip_setup_event?(event_type, content) do
    content = String.trim(content || "")

    event_type in [
      "agent_start",
      "agent_end",
      "turn_start",
      "turn_end",
      "message_end",
      "message_start",
      "message_update",
      "thought",
      "text",
      "update",
      "tool_call",
      "tool_result",
      "tool_execution_start",
      "tool_execution_end",
      "plan"
    ] or
      (content == "" and event_type == "status") or
      (event_type == "status" and setup_internal_status?(content))
  end

  defp setup_event_badge(event_type) do
    case event_type do
      "error" ->
        gettext("Error")

      "prompt" ->
        gettext("Prompt")

      "pr_created" ->
        gettext("Pull request")

      event_kind when event_kind in ["tool_call", "tool_execution_start"] ->
        gettext("Tool")

      event_kind when event_kind in ["tool_result", "tool_execution_end"] ->
        gettext("Tool output")

      "status" ->
        gettext("Status")

      "plan" ->
        gettext("Plan")

      event_kind when event_kind in ["text", "message_start", "message_update"] ->
        gettext("Agent")

      _ ->
        gettext("Update")
    end
  end

  defp setup_event_variant(event_type) do
    case event_type do
      "error" -> "error"
      "pr_created" -> "success"
      "prompt" -> "info"
      event_kind when event_kind in ["tool_call", "tool_execution_start"] -> "tool"
      "status" -> "info"
      _ -> "neutral"
    end
  end

  defp first_present_string(values) do
    Enum.find_value(values, "", fn
      value when is_binary(value) ->
        trimmed = String.trim(value)
        if trimmed == "", do: nil, else: trimmed

      _ ->
        nil
    end)
  end

  defp setup_internal_status?(content) do
    String.starts_with?(content, [
      "Agent connected",
      "Connected to agent:",
      "Preparing repository",
      "Cloning repository",
      "Installing OpenCode",
      "Session created",
      "Setup agent started",
      "Starting OpenCode agent",
      "Sending prompt to agent",
      "Agent finished (reason:"
    ]) or
      String.ends_with?(content, " completed")
  end

  defp setup_pr_url(events) when is_list(events) do
    Enum.find_value(Enum.reverse(events), fn event ->
      event_type = Map.get(event, :event_type, "")
      content = Map.get(event, :content, "")

      cond do
        event_type == "pr_created" and is_binary(content) and content != "" ->
          content

        is_binary(content) ->
          case Regex.run(~r/https?:\/\/github\.com\/[^\s]+\/pull\/\d+/, content) do
            [url | _] -> url
            _ -> nil
          end

        true ->
          nil
      end
    end)
  end

  defp setup_pr_url(_events), do: nil

  defp setup_pr_url_from_audit(nil, _project), do: nil
  defp setup_pr_url_from_audit(_account, nil), do: nil

  defp setup_pr_url_from_audit(account, project) do
    project_path = "/#{account.handle}/#{project.handle}"

    account.id
    |> Glossia.Auditing.list_events(limit: 200)
    |> Enum.find_value(fn event ->
      if event.name == "project.setup_completed" and event.resource_path == project_path do
        extract_setup_pr_url(event.summary || "")
      end
    end)
  rescue
    _ -> nil
  end

  defp extract_setup_pr_url(text) when is_binary(text) do
    case Regex.run(~r/https?:\/\/github\.com\/[^\s]+\/pull\/\d+/, text) do
      [url | _] -> url
      _ -> nil
    end
  end

  defp extract_setup_pr_url(_), do: nil

  # ---------------------------------------------------------------------------
  # Page: New Project (wizard)
  # ---------------------------------------------------------------------------

  defp project_new_wizard(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("New project")}
        description={gettext("Import a GitHub repository and set up localization.")}
      />

      <div class="wizard-step-nav">
        <div class={[
          "wizard-step-dot",
          @step == "repo" && "wizard-step-active",
          @step in ["languages", "setup"] && "wizard-step-completed"
        ]}>
          <span class="wizard-step-number">1</span>
          <span class="wizard-step-label">{gettext("Repository")}</span>
        </div>
        <div class="wizard-step-connector"></div>
        <div class={[
          "wizard-step-dot",
          @step == "languages" && "wizard-step-active",
          @step == "setup" && "wizard-step-completed"
        ]}>
          <span class="wizard-step-number">2</span>
          <span class="wizard-step-label">{gettext("Languages")}</span>
        </div>
        <div class="wizard-step-connector"></div>
        <div class={["wizard-step-dot", @step == "setup" && "wizard-step-active"]}>
          <span class="wizard-step-number">3</span>
          <span class="wizard-step-label">{gettext("Setup")}</span>
        </div>
      </div>

      <%= case @step do %>
        <% "repo" -> %>
          <.wizard_repo_step
            handle={@handle}
            github_repos={@github_repos}
            github_repos_search={@github_repos_search}
            github_configured?={@github_configured?}
          />
        <% "languages" -> %>
          <.wizard_languages_step
            handle={@handle}
            selected_repo={@selected_repo}
            selected_languages={@selected_languages}
            language_search={@language_search}
          />
        <% "setup" -> %>
          <.wizard_setup_step
            handle={@handle}
            account={@account}
            wizard_project={@wizard_project}
            setup_events={@setup_events}
          />
        <% _ -> %>
          <.wizard_repo_step
            handle={@handle}
            github_repos={@github_repos}
            github_repos_search={@github_repos_search}
            github_configured?={@github_configured?}
          />
      <% end %>
    </div>
    """
  end

  defp wizard_repo_step(assigns) do
    assigns =
      assign(
        assigns,
        :filtered_repos,
        filtered_repos(assigns.github_repos, assigns.github_repos_search)
      )

    ~H"""
    <%= cond do %>
      <% @github_configured? and @github_repos != [] -> %>
        <div class="resource-index" id="repo-picker">
          <div class="resource-toolbar">
            <form phx-change="search_repos" class="resource-search-form">
              <div class="resource-search-wrap">
                <svg
                  class="resource-search-icon"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  aria-hidden="true"
                >
                  <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                <input
                  type="search"
                  name="value"
                  value={@github_repos_search}
                  placeholder={gettext("Search repositories...")}
                  phx-debounce="300"
                  class="resource-search"
                />
              </div>
            </form>
          </div>

          <div class="resource-table-wrap">
            <table class="resource-table">
              <thead>
                <tr>
                  <th>{gettext("Repository")}</th>
                  <th>{gettext("Language")}</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= if @filtered_repos == [] do %>
                  <tr>
                    <td colspan="3" class="resource-table-empty">
                      <div class="dash-empty-state">
                        <h2>{gettext("No matching repositories")}</h2>
                        <p>{gettext("Try adjusting your search query.")}</p>
                      </div>
                    </td>
                  </tr>
                <% else %>
                  <%= for repo <- @filtered_repos do %>
                    <tr>
                      <td>
                        <div class="repo-cell-name">
                          <span class="repo-full-name">{repo["full_name"]}</span>
                          <%= if repo["description"] do %>
                            <span class="repo-description muted">{repo["description"]}</span>
                          <% end %>
                        </div>
                      </td>
                      <td>
                        <%= if repo["language"] do %>
                          <span class="mono muted">{repo["language"]}</span>
                        <% end %>
                      </td>
                      <td class="resource-action-cell">
                        <button
                          class="dash-btn dash-btn-primary dash-btn-sm"
                          phx-click="select_repo"
                          phx-value-repo-id={repo["id"]}
                          phx-value-full-name={repo["full_name"]}
                          phx-value-name={repo["name"]}
                          phx-value-default-branch={repo["default_branch"]}
                          phx-value-description={repo["description"]}
                          phx-value-owner-login={get_in(repo, ["owner", "login"])}
                        >
                          {gettext("Select")}
                        </button>
                      </td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>

          <p class="wizard-repo-hint muted">
            {gettext("Don't see your repository?")}
            <a
              href={"/" <> @handle <> "/-/projects/install-github"}
              class="wizard-repo-hint-link"
            >
              {gettext("Configure repository access")}
            </a>
          </p>
        </div>
      <% @github_configured? -> %>
        <div class="dash-empty-state">
          <svg
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" />
          </svg>
          <h2>{gettext("No repositories accessible")}</h2>
          <p>
            {gettext(
              "The GitHub App is installed but has no accessible repositories. Configure the installation to grant access to the repositories you want to import."
            )}
          </p>
          <a
            href={"/" <> @handle <> "/-/projects/install-github"}
            class="dash-btn dash-btn-primary"
          >
            {gettext("Configure repository access")}
          </a>
        </div>
      <% true -> %>
        <div class="dash-empty-state">
          <svg
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="currentColor"
            aria-hidden="true"
          >
            <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
          </svg>
          <h2>{gettext("Connect a Git provider")}</h2>
          <p>
            {gettext("Install the Glossia GitHub App to import repositories and set up localization.")}
          </p>
          <a
            href={"/" <> @handle <> "/-/projects/install-github"}
            class="dash-btn dash-btn-primary"
          >
            {gettext("Install GitHub App")}
          </a>
        </div>
    <% end %>
    """
  end

  defp wizard_languages_step(assigns) do
    search = String.downcase(assigns.language_search || "")

    filtered =
      if search == "" do
        @wizard_languages
      else
        Enum.filter(@wizard_languages, fn lang ->
          String.contains?(String.downcase(lang.name), search) or
            String.contains?(String.downcase(lang.native), search) or
            String.contains?(String.downcase(lang.code), search)
        end)
      end

    assigns = assign(assigns, :filtered_languages, filtered)
    selected_count = length(assigns.selected_languages)
    assigns = assign(assigns, :selected_count, selected_count)

    ~H"""
    <div class="wizard-lang-header">
      <div class="wizard-lang-header-left">
        <div class="wizard-selected-repo">
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" />
          </svg>
          <span>{@selected_repo["full_name"]}</span>
        </div>
        <%= if @selected_count > 0 do %>
          <span class="wizard-lang-count">
            {ngettext("%{count} language selected", "%{count} languages selected", @selected_count,
              count: @selected_count
            )}
          </span>
        <% end %>
      </div>
      <div class="wizard-lang-header-right">
        <button
          class="dash-btn dash-btn-secondary"
          phx-click="wizard_back"
          phx-value-step="repo"
          type="button"
        >
          {gettext("Back")}
        </button>
        <button
          class="dash-btn dash-btn-primary"
          phx-click="start_setup"
          disabled={@selected_count == 0}
          type="button"
        >
          {gettext("Set up project")}
        </button>
      </div>
    </div>

    <div class="resource-index" id="language-picker">
      <div class="resource-toolbar">
        <form phx-change="search_languages" class="resource-search-form">
          <div class="resource-search-wrap">
            <svg
              class="resource-search-icon"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              type="search"
              name="value"
              value={@language_search}
              placeholder={gettext("Search languages...")}
              phx-debounce="200"
              class="resource-search"
            />
          </div>
        </form>
      </div>

      <div class="resource-table-wrap">
        <table class="resource-table">
          <thead>
            <tr>
              <th></th>
              <th>{gettext("Language")}</th>
              <th>{gettext("Native name")}</th>
              <th>{gettext("Code")}</th>
            </tr>
          </thead>
          <tbody>
            <%= if @filtered_languages == [] do %>
              <tr>
                <td colspan="4" class="resource-table-empty">
                  <div class="dash-empty-state">
                    <h2>{gettext("No matching languages")}</h2>
                    <p>{gettext("Try adjusting your search query.")}</p>
                  </div>
                </td>
              </tr>
            <% else %>
              <%= for lang <- @filtered_languages do %>
                <tr
                  class={[
                    "wizard-lang-row",
                    lang.code in @selected_languages && "wizard-lang-row-selected"
                  ]}
                  phx-click="toggle_language"
                  phx-value-code={lang.code}
                  style="cursor: pointer;"
                >
                  <td style="width: 40px;">
                    <span class={[
                      "wizard-lang-check",
                      lang.code in @selected_languages && "wizard-lang-check-active"
                    ]}>
                      <%= if lang.code in @selected_languages do %>
                        <svg
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="3"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          aria-hidden="true"
                        >
                          <polyline points="20 6 9 17 4 12" />
                        </svg>
                      <% end %>
                    </span>
                  </td>
                  <td>{lang.name}</td>
                  <td><span class="muted">{lang.native}</span></td>
                  <td><span class="mono muted">{lang.code}</span></td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp wizard_setup_step(assigns) do
    project = assigns.wizard_project
    status = if project, do: project.setup_status, else: nil

    assigns =
      assigns
      |> assign(:status, status)
      |> assign(
        :pr_url,
        setup_pr_url(assigns[:setup_events] || []) ||
          setup_pr_url_from_audit(assigns[:account], project)
      )

    ~H"""
    <div class="wizard-setup-container">
      <%= cond do %>
        <% @status in ["pending", "running"] -> %>
          <div class="setup-feed">
            <div class="setup-feed-header">
              <span class="setup-feed-pulse"></span>
              <div class="setup-feed-header-copy">
                <h3>{gettext("Setting up localization...")}</h3>
                <p>
                  {gettext("Building a minimal GLOSSIA.md baseline that your team can reuse.")}
                </p>
              </div>
            </div>
            <div class="setup-feed-events" id="wizard-setup-events" phx-hook=".SetupFeedScroll">
              <%= for event <- @setup_events do %>
                <.setup_event_item event={event} />
              <% end %>
            </div>
          </div>
          <script :type={Phoenix.LiveView.ColocatedHook} name=".SetupFeedScroll">
            export default {
              mounted() {
                this.scrollToBottom()
              },
              updated() {
                this.scrollToBottom()
              },
              scrollToBottom() {
                this.el.scrollTop = this.el.scrollHeight
              }
            }
          </script>
        <% @status == "completed" -> %>
          <div class="setup-feed">
            <div class="setup-feed-header setup-feed-header-success">
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <path d="M22 11.08V12a10 10 0 11-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" />
              </svg>
              <div class="setup-feed-header-copy">
                <h3>{gettext("Setup complete")}</h3>
                <p>{gettext("Your localization baseline is ready for review.")}</p>
              </div>
            </div>
            <%= if @pr_url do %>
              <div class="setup-pr-card">
                <span class="setup-pr-card-label">{gettext("Pull request ready")}</span>
                <a href={@pr_url} target="_blank" rel="noopener noreferrer" class="setup-pr-link">
                  {gettext("Open pull request")}
                </a>
              </div>
            <% else %>
              <div class="setup-pr-card">
                <span class="setup-pr-card-label">{gettext("Pull request unavailable")}</span>
                <p>
                  {gettext(
                    "Setup finished without a pull request link. Check setup events for details."
                  )}
                </p>
              </div>
            <% end %>
            <%= if @setup_events != [] do %>
              <div class="setup-feed-events" id="wizard-setup-events">
                <%= for event <- @setup_events do %>
                  <.setup_event_item event={event} />
                <% end %>
              </div>
            <% end %>
          </div>
          <div class="wizard-footer">
            <button
              class="dash-btn dash-btn-primary"
              phx-click="finish_setup"
              type="button"
            >
              {gettext("Go to project")}
            </button>
          </div>
        <% @status == "failed" -> %>
          <div class="setup-feed">
            <div class="setup-feed-header setup-feed-header-error">
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line
                  x1="9"
                  y1="9"
                  x2="15"
                  y2="15"
                />
              </svg>
              <div class="setup-feed-header-copy">
                <h3>{gettext("Setup failed")}</h3>
                <p class="setup-feed-error-msg">
                  {(@wizard_project && @wizard_project.setup_error) ||
                    gettext("An error occurred during setup.")}
                </p>
              </div>
            </div>
            <%= if @setup_events != [] do %>
              <details class="setup-feed-details">
                <summary>{gettext("View agent session")}</summary>
                <div class="setup-feed-events" id="wizard-setup-events">
                  <%= for event <- @setup_events do %>
                    <.setup_event_item event={event} />
                  <% end %>
                </div>
              </details>
            <% end %>
          </div>
          <div class="wizard-footer">
            <button
              class="dash-btn dash-btn-primary"
              phx-click="finish_setup"
              type="button"
            >
              {gettext("Go to project")}
            </button>
          </div>
        <% true -> %>
          <div class="dash-empty-state">
            <h2>{gettext("Preparing...")}</h2>
          </div>
      <% end %>
    </div>
    """
  end

  attr :voice, :map, default: nil
  attr :original_voice, :map, default: nil
  attr :voice_form_params, :map, default: %{}
  attr :overrides, :list, default: []
  attr :original_overrides, :list, default: []
  attr :target_countries, :list, default: []
  attr :cultural_notes, :map, default: %{}

  defp voice_suggestion_changes(assigns) do
    proposed = %{
      description:
        Map.get(assigns.voice_form_params || %{}, "description") ||
          ((assigns.voice && assigns.voice.description) || ""),
      tone:
        Map.get(assigns.voice_form_params || %{}, "tone") ||
          ((assigns.voice && assigns.voice.tone) || ""),
      formality:
        Map.get(assigns.voice_form_params || %{}, "formality") ||
          ((assigns.voice && assigns.voice.formality) || ""),
      target_audience:
        Map.get(assigns.voice_form_params || %{}, "target_audience") ||
          ((assigns.voice && assigns.voice.target_audience) || ""),
      guidelines:
        Map.get(assigns.voice_form_params || %{}, "guidelines") ||
          ((assigns.voice && assigns.voice.guidelines) || ""),
      target_countries: Enum.sort(assigns.target_countries || []),
      cultural_notes: assigns.cultural_notes || %{}
    }

    original = %{
      description: (assigns.original_voice && assigns.original_voice.description) || "",
      tone: (assigns.original_voice && assigns.original_voice.tone) || "",
      formality: (assigns.original_voice && assigns.original_voice.formality) || "",
      target_audience: (assigns.original_voice && assigns.original_voice.target_audience) || "",
      guidelines: (assigns.original_voice && assigns.original_voice.guidelines) || "",
      target_countries:
        Enum.sort((assigns.original_voice && assigns.original_voice.target_countries) || []),
      cultural_notes: (assigns.original_voice && assigns.original_voice.cultural_notes) || %{}
    }

    notes_changed_for =
      changed_cultural_note_codes(proposed.cultural_notes, original.cultural_notes)

    overrides_changed? =
      overrides_signature(assigns.overrides || []) !=
        overrides_signature(assigns.original_overrides || [])

    has_changes? =
      proposed.description != original.description or
        proposed.tone != original.tone or
        proposed.formality != original.formality or
        proposed.target_audience != original.target_audience or
        proposed.guidelines != original.guidelines or
        proposed.target_countries != original.target_countries or
        notes_changed_for != [] or overrides_changed?

    assigns =
      assign(assigns,
        proposed: proposed,
        original: original,
        notes_changed_for: notes_changed_for,
        overrides_changed?: overrides_changed?,
        has_changes?: has_changes?
      )

    ~H"""
    <div class="voice-section">
      <div class="voice-section-info">
        <h2>{gettext("Proposed changes")}</h2>
        <p>{gettext("This review is read-only. Go back to continue editing your draft.")}</p>
      </div>
      <div class="voice-card">
        <div class="voice-card-fields">
          <%= if @has_changes? do %>
            <.diff_field
              :if={@proposed.description != @original.description}
              label={gettext("Description")}
              current={@proposed.description}
              previous={@original.description}
              formatter={&identity_text/1}
            />
            <.diff_field
              :if={@proposed.tone != @original.tone}
              label={gettext("Tone")}
              current={@proposed.tone}
              previous={@original.tone}
              formatter={&identity_text/1}
            />
            <.diff_field
              :if={@proposed.formality != @original.formality}
              label={gettext("Formality")}
              current={@proposed.formality}
              previous={@original.formality}
              formatter={&identity_text/1}
            />
            <.diff_field
              :if={@proposed.target_audience != @original.target_audience}
              label={gettext("Target audience")}
              current={@proposed.target_audience}
              previous={@original.target_audience}
              formatter={&identity_text/1}
            />
            <.diff_field
              :if={@proposed.guidelines != @original.guidelines}
              label={gettext("Guidelines")}
              current={@proposed.guidelines}
              previous={@original.guidelines}
              formatter={&identity_text/1}
            />
            <.diff_field
              :if={@proposed.target_countries != @original.target_countries}
              label={gettext("Target countries")}
              current={countries_to_text(@proposed.target_countries)}
              previous={countries_to_text(@original.target_countries)}
              formatter={&identity_text/1}
            />
            <div :if={@notes_changed_for != []} class="voice-diff-field">
              <span class="voice-diff-label">{gettext("Cultural notes")}</span>
              <span class="voice-diff-new">
                {gettext("Updated for: %{countries}", countries: Enum.join(@notes_changed_for, ", "))}
              </span>
            </div>
            <.diff_field
              :if={@overrides_changed?}
              label={gettext("Language overrides")}
              current={overrides_to_text(@overrides)}
              previous={overrides_to_text(@original_overrides)}
              formatter={&identity_text/1}
            />
          <% else %>
            <p class="muted">{gettext("No proposed changes detected.")}</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :glossary_entries, :list, default: []
  attr :original_glossary_entries, :list, default: []

  defp glossary_suggestion_changes(assigns) do
    assigns =
      assign(
        assigns,
        :change_details,
        glossary_change_details(assigns.glossary_entries, assigns.original_glossary_entries)
      )

    ~H"""
    <div class="voice-section">
      <div class="voice-section-info">
        <h2>{gettext("Proposed changes")}</h2>
        <p>
          {gettext(
            "This review is read-only and mirrors the glossary editor layout. Go back to continue editing your draft."
          )}
        </p>
      </div>
      <div class="voice-card">
        <div class="voice-card-fields">
          <%= if @change_details == [] do %>
            <p class="muted">{gettext("No proposed glossary changes detected.")}</p>
          <% else %>
            <div class="glossary-suggestion-list">
              <%= for change <- @change_details do %>
                <% entry = glossary_change_display_entry(change) %>
                <% term_class = glossary_change_field_class(change, @original_glossary_entries, :term) %>
                <% case_sensitive_class =
                  glossary_change_field_class(change, @original_glossary_entries, :case_sensitive) %>
                <% definition_class =
                  glossary_change_field_class(change, @original_glossary_entries, :definition) %>
                <% translation_rows =
                  glossary_change_translation_rows(change, @original_glossary_entries) %>
                <% single_header_field? =
                  (not is_nil(term_class) and is_nil(case_sensitive_class)) or
                    (is_nil(term_class) and not is_nil(case_sensitive_class)) %>
                <div class={[
                  "glossary-entry-block",
                  glossary_suggestion_change_block_class(change.kind)
                ]}>
                  <div class="voice-override-header">
                    <span class="voice-override-locale">{change.term}</span>
                    <span class={glossary_change_badge_class(change.kind)}>
                      {glossary_change_kind_label(change.kind)}
                    </span>
                  </div>
                  <div class="voice-override-fields">
                    <div class={["voice-field-row", single_header_field? && "voice-field-row-single"]}>
                      <div :if={term_class} class={["voice-field", term_class]}>
                        <label>{gettext("Term")}</label>
                        <div class="glossary-readonly-value">
                          {glossary_readonly_text(map_get(entry, :term, ""))}
                        </div>
                      </div>
                      <div :if={case_sensitive_class} class={["voice-field", case_sensitive_class]}>
                        <label>{gettext("Case sensitive")}</label>
                        <div class="glossary-readonly-value">
                          <%= if map_get(entry, :case_sensitive, false) do %>
                            {gettext("Yes")}
                          <% else %>
                            {gettext("No")}
                          <% end %>
                        </div>
                      </div>
                    </div>
                    <div :if={definition_class} class={["voice-field", definition_class]}>
                      <label>{gettext("Definition")}</label>
                      <div class="glossary-readonly-value multiline">
                        {glossary_readonly_text(map_get(entry, :definition, ""))}
                      </div>
                    </div>

                    <div :if={translation_rows != []} class="glossary-translations-section">
                      <div class="glossary-translations-header">
                        <span class="voice-diff-label">{gettext("Translations")}</span>
                      </div>

                      <%= for row <- translation_rows do %>
                        <div class={["glossary-translation-row", row.class]}>
                          <div class="voice-field">
                            <div class="glossary-readonly-value">
                              {glossary_readonly_text(map_get(row.translation, :locale, ""))}
                            </div>
                          </div>
                          <div class="voice-field" style="flex: 1;">
                            <div class="glossary-readonly-value">
                              {glossary_readonly_text(map_get(row.translation, :translation, ""))}
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp glossary_change_details(entries, original_entries) do
    current_entries = glossary_entries_term_map(entries)
    previous_entries = glossary_entries_term_map(original_entries)

    glossary_change_items(entries, original_entries)
    |> Enum.map(fn change ->
      Map.merge(change, %{
        current: Map.get(current_entries, change.term),
        previous: Map.get(previous_entries, change.term)
      })
    end)
  end

  defp glossary_entries_term_map(entries) do
    entries
    |> List.wrap()
    |> Enum.reduce(%{}, fn entry, acc ->
      term = map_get(entry, :term, "")

      if term in [nil, ""] do
        acc
      else
        Map.put(acc, term, entry)
      end
    end)
  end

  defp glossary_change_display_entry(%{kind: :removed, previous: previous}), do: previous || %{}
  defp glossary_change_display_entry(%{current: current}), do: current || %{}

  defp glossary_suggestion_change_block_class(:added), do: "glossary-entry-block-added"
  defp glossary_suggestion_change_block_class(:removed), do: "glossary-entry-block-removed"
  defp glossary_suggestion_change_block_class(:updated), do: "glossary-entry-block-changed"
  defp glossary_suggestion_change_block_class(_), do: "glossary-entry-block-changed"

  defp glossary_change_badge_class(:added), do: "voice-diff-badge voice-diff-badge-added"
  defp glossary_change_badge_class(:removed), do: "voice-diff-badge voice-diff-badge-removed"
  defp glossary_change_badge_class(:updated), do: "voice-diff-badge voice-diff-badge-updated"
  defp glossary_change_badge_class(_), do: "voice-diff-badge"

  defp glossary_change_field_class(%{kind: :added}, _original_entries, _field),
    do: "voice-field-added"

  defp glossary_change_field_class(%{kind: :removed}, _original_entries, _field),
    do: "voice-field-removed"

  defp glossary_change_field_class(
         %{kind: :updated, current: current},
         original_entries,
         field
       ) do
    if glossary_entry_field_changed?(current || %{}, original_entries, field) do
      "voice-field-changed"
    end
  end

  defp glossary_change_field_class(_change, _original_entries, _field), do: nil

  defp glossary_change_translation_rows(%{kind: :added, current: current}, _original_entries) do
    current
    |> glossary_translation_pairs()
    |> Enum.sort()
    |> Enum.map(fn pair ->
      %{
        translation: glossary_translation_from_pair(pair),
        class: "glossary-translation-row-added"
      }
    end)
  end

  defp glossary_change_translation_rows(%{kind: :removed, previous: previous}, _original_entries) do
    previous
    |> glossary_translation_pairs()
    |> Enum.sort()
    |> Enum.map(fn pair ->
      %{
        translation: glossary_translation_from_pair(pair),
        class: "glossary-translation-row-removed"
      }
    end)
  end

  defp glossary_change_translation_rows(
         %{kind: :updated, current: current, previous: previous},
         _original_entries
       ) do
    current_pairs =
      current
      |> glossary_translation_pairs()
      |> Enum.sort()

    previous_pairs =
      previous
      |> glossary_translation_pairs()
      |> Enum.sort()

    added_rows =
      current_pairs
      |> Kernel.--(previous_pairs)
      |> Enum.map(fn pair ->
        %{
          translation: glossary_translation_from_pair(pair),
          class: "glossary-translation-row-added"
        }
      end)

    removed_rows =
      previous_pairs
      |> Kernel.--(current_pairs)
      |> Enum.map(fn pair ->
        %{
          translation: glossary_translation_from_pair(pair),
          class: "glossary-translation-row-removed"
        }
      end)

    added_rows ++ removed_rows
  end

  defp glossary_change_translation_rows(_change, _original_entries), do: []

  defp glossary_translation_pairs(entry) do
    entry
    |> map_get(:translations, [])
    |> List.wrap()
    |> Enum.map(fn translation ->
      {map_get(translation, :locale, ""), map_get(translation, :translation, "")}
    end)
    |> Enum.reject(fn {locale, translation} -> locale == "" and translation == "" end)
  end

  defp glossary_translation_from_pair({locale, translation}) do
    %{locale: locale, translation: translation}
  end

  defp glossary_readonly_text(nil), do: "-"
  defp glossary_readonly_text(""), do: "-"
  defp glossary_readonly_text(value), do: to_string(value)

  # ---------------------------------------------------------------------------
  # Shared: Diff field component
  # ---------------------------------------------------------------------------

  attr :label, :string, required: true
  attr :current, :string, default: nil
  attr :previous, :string, default: nil
  attr :formatter, :any, default: nil

  defp diff_field(assigns) do
    ~H"""
    <div class="voice-diff-field">
      <span class="voice-diff-label">{@label}</span>
      <%= if @previous && @previous != @current do %>
        <div class="voice-diff-change">
          <span class="voice-diff-old">{format_field(@previous, @formatter)}</span>
          <svg
            class="voice-diff-arrow"
            width="14"
            height="14"
            viewBox="0 0 20 20"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            aria-hidden="true"
          >
            <line x1="4" y1="10" x2="16" y2="10" /><polyline points="11 5 16 10 11 15" />
          </svg>
          <span class="voice-diff-new">{format_field(@current, @formatter)}</span>
        </div>
      <% else %>
        <span class="voice-diff-unchanged">{format_field(@current || @previous, @formatter)}</span>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp fetch_github_repos_via_installation(installation) do
    with {:ok, token} <-
           Glossia.Github.App.installation_token(installation.github_installation_id),
         {:ok, %{repositories: repos}} <-
           Glossia.Github.Client.list_installation_repos(token) do
      {:ok, repos}
    end
  end

  defp fetch_github_repos_via_oauth(user) do
    case Glossia.Accounts.get_github_token_for_user(user.id) do
      nil ->
        {:error, :no_github_token}

      token ->
        case Glossia.Github.Client.list_user_repos(token) do
          {:ok, %{repositories: repos}} -> {:ok, repos}
          {:error, _} = err -> err
        end
    end
  end

  defp filtered_repos(repos, ""), do: repos
  defp filtered_repos(repos, nil), do: repos

  defp filtered_repos(repos, query) do
    q = String.downcase(query)

    Enum.filter(repos, fn repo ->
      String.contains?(String.downcase(repo["name"] || ""), q) or
        String.contains?(String.downcase(repo["full_name"] || ""), q) or
        String.contains?(String.downcase(repo["description"] || ""), q)
    end)
  end

  defp filter_imported_repositories(repos, imported_repositories) do
    imported_repo_ids =
      imported_repositories
      |> Enum.map(&repo_id_key(&1.github_repo_id))
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    imported_full_names =
      imported_repositories
      |> Enum.map(&repo_full_name_key(&1.github_repo_full_name))
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    Enum.reject(repos, fn repo ->
      repo_id = repo_id_key(repo["id"])
      repo_full_name = repo_full_name_key(repo["full_name"])

      (repo_id && MapSet.member?(imported_repo_ids, repo_id)) ||
        (repo_full_name && MapSet.member?(imported_full_names, repo_full_name))
    end)
  end

  defp repo_id_key(nil), do: nil
  defp repo_id_key(id) when is_integer(id), do: Integer.to_string(id)

  defp repo_id_key(id) when is_binary(id) do
    trimmed = String.trim(id)
    if trimmed == "", do: nil, else: trimmed
  end

  defp repo_id_key(id), do: id |> to_string() |> repo_id_key()

  defp repo_full_name_key(nil), do: nil

  defp repo_full_name_key(full_name) when is_binary(full_name) do
    normalized = full_name |> String.trim() |> String.downcase()
    if normalized == "", do: nil, else: normalized
  end

  defp repo_full_name_key(full_name), do: full_name |> to_string() |> repo_full_name_key()

  defp format_field(nil, _formatter), do: "-"
  defp format_field(val, nil), do: val |> String.capitalize()
  defp format_field(val, fun), do: fun.(val)

  defp identity_text(nil), do: "-"
  defp identity_text(""), do: "-"
  defp identity_text(val), do: to_string(val)

  defp humanize_formality(val), do: val |> String.replace("_", " ") |> String.capitalize()

  defp countries_to_text([]), do: gettext("None")
  defp countries_to_text(countries), do: Enum.join(countries, ", ")

  defp overrides_to_text(overrides) do
    locales =
      overrides
      |> List.wrap()
      |> Enum.map(&map_get(&1, :locale, ""))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.sort()

    if locales == [], do: gettext("None"), else: Enum.join(locales, ", ")
  end

  defp changed_cultural_note_codes(current_notes, original_notes) do
    current_notes = if is_map(current_notes), do: current_notes, else: %{}
    original_notes = if is_map(original_notes), do: original_notes, else: %{}

    current_notes
    |> Map.keys()
    |> Kernel.++(Map.keys(original_notes))
    |> Enum.uniq()
    |> Enum.filter(fn code ->
      Map.get(current_notes, code, "") != Map.get(original_notes, code, "")
    end)
    |> Enum.sort()
  end

  defp overrides_signature(overrides) do
    overrides
    |> List.wrap()
    |> Enum.map(fn override ->
      {map_get(override, :locale, ""), map_get(override, :tone, ""),
       map_get(override, :formality, ""), map_get(override, :target_audience, ""),
       map_get(override, :guidelines, "")}
    end)
    |> Enum.reject(fn {locale, _tone, _formality, _audience, _guidelines} -> locale == "" end)
    |> Enum.sort()
  end

  defp glossary_change_items(entries, original_entries) do
    current = glossary_entries_index(entries)
    previous = glossary_entries_index(original_entries)

    current
    |> Map.keys()
    |> Kernel.++(Map.keys(previous))
    |> Enum.uniq()
    |> Enum.reject(&(&1 == ""))
    |> Enum.sort()
    |> Enum.reduce([], fn term, acc ->
      case {Map.get(previous, term), Map.get(current, term)} do
        {nil, _present} ->
          [%{term: term, kind: :added} | acc]

        {_present, nil} ->
          [%{term: term, kind: :removed} | acc]

        {prev, cur} when prev != cur ->
          [%{term: term, kind: :updated} | acc]

        _ ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp glossary_entries_index(entries) do
    entries
    |> List.wrap()
    |> Enum.reduce(%{}, fn entry, acc ->
      term = map_get(entry, :term, "")

      if term in [nil, ""] do
        acc
      else
        Map.put(acc, term, glossary_entry_signature(entry))
      end
    end)
  end

  defp glossary_entry_signature(entry) do
    translations =
      entry
      |> map_get(:translations, [])
      |> List.wrap()
      |> Enum.map(fn translation ->
        {map_get(translation, :locale, ""), map_get(translation, :translation, "")}
      end)
      |> Enum.reject(fn {locale, translation} -> locale == "" and translation == "" end)
      |> Enum.sort()

    %{
      definition: map_get(entry, :definition, nil),
      case_sensitive: map_get(entry, :case_sensitive, false),
      translations: translations
    }
  end

  defp glossary_change_kind_label(:added), do: gettext("Added")
  defp glossary_change_kind_label(:removed), do: gettext("Removed")
  defp glossary_change_kind_label(:updated), do: gettext("Updated")
  defp glossary_change_kind_label(_), do: gettext("Changed")

  defp map_get(nil, _key, default), do: default

  defp map_get(map, key, default) when is_map(map) and is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        value

      :error ->
        Map.get(map, Atom.to_string(key), default)
    end
  end

  defp gravatar_url(email, size \\ 24) do
    hash =
      :crypto.hash(:md5, String.downcase(String.trim(email)))
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=mp"
  end

  defp user_avatar_url(user) do
    user.avatar_url || gravatar_url(user.email)
  end

  defp non_empty(""), do: nil
  defp non_empty(val), do: val

  defp humanize_event_name(name) do
    name
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  # Normalize legacy resource paths that predate the /:handle/-/ URL restructure.
  # Paths like "/dev/voice/3" become "/dev/-/voice/3".
  # Paths already containing "/-/" or starting with "/admin" are left unchanged.
  @legacy_path_segments ~w(voice glossary discussions tickets members logs settings)
  defp normalize_resource_path(""), do: ""

  defp normalize_resource_path(path) when is_binary(path) do
    if String.contains?(path, "/-/") or String.starts_with?(path, "/admin") do
      path
    else
      case String.split(path, "/", parts: 4) do
        ["", handle, segment | rest] ->
          if segment in @legacy_path_segments do
            "/" <> handle <> "/-/" <> segment <> if(rest != [], do: "/" <> hd(rest), else: "")
          else
            path
          end

        _ ->
          path
      end
    end
  end

  defp list_suggestion_discussions(account, kind) do
    params = %{
      "order_by" => ["inserted_at"],
      "order_directions" => ["desc"],
      "page_size" => 10,
      "filters" => [
        %{"field" => "kind", "op" => "==", "value" => kind},
        %{"field" => "status", "op" => "==", "value" => "open"}
      ]
    }

    case Discussions.list_discussions(account, params) do
      {:ok, {tickets, _meta}} -> tickets
      _ -> []
    end
  end

  defp parse_glossary_entries_from_params(params, fallback_entries) do
    case params["entries"] do
      nil ->
        fallback_entries

      entries_map ->
        entries_map
        |> Enum.sort_by(fn {idx, _} -> String.to_integer(idx) end)
        |> Enum.map(fn {_idx, e} ->
          translations =
            (e["translations"] || %{})
            |> Enum.sort_by(fn {tidx, _} -> String.to_integer(tidx) end)
            |> Enum.map(fn {_tidx, t} ->
              %{locale: t["locale"] || "", translation: t["translation"] || ""}
            end)

          %{
            term: e["term"] || "",
            definition: non_empty(e["definition"]),
            case_sensitive: e["case_sensitive"] == "true",
            translations: translations
          }
        end)
    end
  end

  defp parse_voice_overrides_from_params(params, fallback_overrides) do
    case params["overrides"] do
      nil ->
        fallback_overrides

      overrides_map ->
        overrides_map
        |> Enum.sort_by(fn {idx, _} -> String.to_integer(idx) end)
        |> Enum.map(fn {_idx, override} ->
          %{
            locale: override["locale"] || "",
            tone: non_empty(override["tone"] || ""),
            formality: non_empty(override["formality"] || ""),
            target_audience: non_empty(override["target_audience"] || ""),
            guidelines: non_empty(override["guidelines"] || "")
          }
        end)
    end
  end

  defp sanitize_voice_form_params(params) do
    %{
      "description" => Map.get(params, "description", ""),
      "tone" => Map.get(params, "tone", ""),
      "formality" => Map.get(params, "formality", ""),
      "target_audience" => Map.get(params, "target_audience", ""),
      "guidelines" => Map.get(params, "guidelines", ""),
      "overrides" => sanitize_voice_overrides(Map.get(params, "overrides", %{})),
      "suggestion_title" => suggestion_param_value(params, "suggestion_title", "request_title"),
      "suggestion_body" => suggestion_param_value(params, "suggestion_body", "request_body")
    }
  end

  defp sanitize_voice_overrides(overrides) when is_map(overrides) do
    overrides
    |> Enum.reduce(%{}, fn {idx, override}, acc ->
      Map.put(acc, to_string(idx), %{
        "locale" => Map.get(override, "locale", ""),
        "tone" => Map.get(override, "tone", ""),
        "formality" => Map.get(override, "formality", ""),
        "target_audience" => Map.get(override, "target_audience", ""),
        "guidelines" => Map.get(override, "guidelines", "")
      })
    end)
  end

  defp sanitize_voice_overrides(_), do: %{}

  defp sanitize_glossary_form_params(params) do
    %{
      "entries" => sanitize_glossary_entries(Map.get(params, "entries", %{})),
      "suggestion_title" => suggestion_param_value(params, "suggestion_title", "request_title"),
      "suggestion_body" => suggestion_param_value(params, "suggestion_body", "request_body"),
      "change_note" => Map.get(params, "change_note", "")
    }
  end

  defp suggestion_param_value(params, new_key, old_key) do
    Map.get(params, new_key, Map.get(params, old_key, ""))
  end

  defp suggestion_text_param(params, new_key, old_key) do
    params
    |> suggestion_param_value(new_key, old_key)
    |> to_string()
    |> String.trim()
  end

  defp sanitize_glossary_entries(entries) when is_map(entries) do
    entries
    |> Enum.reduce(%{}, fn {idx, entry}, acc ->
      Map.put(acc, to_string(idx), %{
        "term" => Map.get(entry, "term", ""),
        "definition" => Map.get(entry, "definition", ""),
        "case_sensitive" => Map.get(entry, "case_sensitive", "false"),
        "translations" => sanitize_glossary_translations(Map.get(entry, "translations", %{}))
      })
    end)
  end

  defp sanitize_glossary_entries(_), do: %{}

  defp sanitize_glossary_translations(translations) when is_map(translations) do
    translations
    |> Enum.reduce(%{}, fn {idx, translation}, acc ->
      Map.put(acc, to_string(idx), %{
        "locale" => Map.get(translation, "locale", ""),
        "translation" => Map.get(translation, "translation", "")
      })
    end)
  end

  defp sanitize_glossary_translations(_), do: %{}

  defp merge_suggestion_params(base_params, submit_params) do
    Map.merge(base_params, submit_params, fn _key, old, new ->
      if new in [nil, ""], do: old, else: new
    end)
  end

  defp encode_draft_token(data) when is_map(data) do
    data
    |> JSON.encode!()
    |> Base.url_encode64(padding: false)
  end

  defp decode_draft_token(nil), do: nil
  defp decode_draft_token(""), do: nil

  defp decode_draft_token(token) when is_binary(token) do
    with {:ok, decoded} <- Base.url_decode64(token, padding: false),
         {:ok, data} <- JSON.decode(decoded),
         true <- is_map(data) do
      data
    else
      _ -> nil
    end
  end

  defp maybe_with_draft_param(path, nil), do: path
  defp maybe_with_draft_param(path, ""), do: path

  defp maybe_with_draft_param(path, token) do
    path <> "?" <> URI.encode_query(%{"draft" => token})
  end

  defp existing_token_from_assign(socket, key) when is_atom(key) do
    case socket.assigns[key] do
      token when is_binary(token) and token != "" -> token
      _ -> nil
    end
  end

  defp maybe_redirect_to_suggestion_finalize(socket, params) do
    handle = socket.assigns.handle

    cond do
      socket.assigns.live_action == :voice and
          (socket.assigns[:pending_voice_suggestion_redirect] || false) ->
        token = socket.assigns[:voice_draft_token] || Map.get(params, "draft")

        if is_binary(token) and token != "" do
          socket
          |> assign(pending_voice_suggestion_redirect: false)
          |> push_patch(to: maybe_with_draft_param("/#{handle}/-/voice/suggestion/new", token))
        else
          assign(socket, pending_voice_suggestion_redirect: false)
        end

      socket.assigns.live_action == :glossary and
          (socket.assigns[:pending_glossary_suggestion_redirect] || false) ->
        token = socket.assigns[:glossary_draft_token] || Map.get(params, "draft")

        if is_binary(token) and token != "" do
          socket
          |> assign(pending_glossary_suggestion_redirect: false)
          |> push_patch(to: maybe_with_draft_param("/#{handle}/-/glossary/suggestion/new", token))
        else
          assign(socket, pending_glossary_suggestion_redirect: false)
        end

      true ->
        socket
    end
  end

  defp voice_suggestion_draft_from_token(
         token,
         baseline_voice,
         baseline_overrides,
         baseline_countries,
         baseline_notes
       ) do
    case decode_draft_token(token) do
      %{"voice_form_params" => params} = decoded ->
        draft_params = sanitize_voice_form_params(params)

        target_countries =
          normalize_draft_string_list(decoded["target_countries"], baseline_countries)

        cultural_notes = normalize_draft_string_map(decoded["cultural_notes"], baseline_notes)
        overrides = parse_voice_overrides_from_params(draft_params, baseline_overrides)

        %{
          voice: baseline_voice,
          original_voice: baseline_voice,
          overrides: overrides,
          original_overrides: baseline_overrides,
          target_countries: target_countries,
          cultural_notes: cultural_notes,
          voice_form_params: draft_params,
          change_summary: to_string(decoded["change_summary"] || "")
        }

      _ ->
        nil
    end
  end

  defp glossary_suggestion_draft_from_token(token, baseline_glossary, baseline_entries) do
    case decode_draft_token(token) do
      %{"glossary_form_params" => params} = decoded ->
        draft_params = sanitize_glossary_form_params(params)
        entries = parse_glossary_entries_from_params(draft_params, baseline_entries)

        %{
          glossary: baseline_glossary,
          original_glossary: baseline_glossary,
          glossary_entries: entries,
          original_glossary_entries: baseline_entries,
          glossary_form_params: draft_params,
          change_summary: to_string(decoded["change_summary"] || "")
        }

      _ ->
        nil
    end
  end

  defp normalize_draft_string_list(nil, fallback), do: fallback

  defp normalize_draft_string_list(list, _fallback) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_draft_string_list(_, fallback), do: fallback

  defp normalize_draft_string_map(nil, fallback), do: fallback

  defp normalize_draft_string_map(map, _fallback) when is_map(map) do
    map
    |> Enum.into(%{}, fn {k, v} -> {to_string(k), to_string(v || "")} end)
  end

  defp normalize_draft_string_map(_, fallback), do: fallback

  defp begin_voice_suggestion(params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    can_propose = socket.assigns[:can_voice_propose] || false

    if not (can_discussion_write and can_propose) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      existing_params = socket.assigns[:voice_form_params] || %{}

      merged_params =
        Map.merge(existing_params, params, fn _key, old, new ->
          if new in [nil, ""], do: old, else: new
        end)

      cultural_notes =
        case merged_params["cultural_notes"] do
          notes when is_map(notes) -> Map.merge(socket.assigns.cultural_notes, notes)
          _ -> socket.assigns.cultural_notes
        end

      overrides = parse_voice_overrides_from_params(merged_params, socket.assigns.overrides)

      draft_params =
        merged_params
        |> Map.put_new("suggestion_title", "")
        |> Map.put_new("suggestion_body", "")

      draft_params = sanitize_voice_form_params(draft_params)

      draft_token =
        encode_draft_token(%{
          "voice_form_params" => draft_params,
          "target_countries" => socket.assigns.target_countries || [],
          "cultural_notes" => cultural_notes || %{},
          "change_summary" => socket.assigns.change_summary || ""
        })

      handle = socket.assigns.handle
      voice_draft_path = maybe_with_draft_param("/#{handle}/-/voice", draft_token)

      {:noreply,
       socket
       |> assign(
         overrides: overrides,
         cultural_notes: cultural_notes,
         voice_form_params: draft_params,
         voice_suggestion_draft: %{
           voice: socket.assigns.voice,
           original_voice: socket.assigns.original_voice,
           overrides: overrides,
           original_overrides: socket.assigns.original_overrides,
           target_countries: socket.assigns.target_countries,
           cultural_notes: cultural_notes,
           voice_form_params: draft_params,
           change_summary: socket.assigns.change_summary
         },
         voice_draft_token: draft_token,
         pending_voice_suggestion_redirect: true,
         voice_back_path: maybe_with_draft_param("/#{handle}/-/voice", draft_token)
       )
       |> push_patch(to: voice_draft_path)}
    end
  end

  defp begin_glossary_suggestion(params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    can_propose = socket.assigns[:can_glossary_propose] || false

    if not (can_discussion_write and can_propose) do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      existing_params = socket.assigns[:glossary_form_params] || %{}

      merged_params =
        Map.merge(existing_params, params, fn _key, old, new ->
          if new in [nil, ""], do: old, else: new
        end)

      entries = parse_glossary_entries_from_params(merged_params, socket.assigns.glossary_entries)
      change_note = socket.assigns[:change_summary] || ""

      draft_params =
        merged_params
        |> Map.put_new("suggestion_title", "")
        |> Map.put_new("suggestion_body", "")
        |> Map.put("change_note", change_note)

      draft_params = sanitize_glossary_form_params(draft_params)

      draft_token =
        encode_draft_token(%{
          "glossary_form_params" => draft_params,
          "change_summary" => socket.assigns.change_summary || ""
        })

      handle = socket.assigns.handle
      glossary_draft_path = maybe_with_draft_param("/#{handle}/-/glossary", draft_token)

      {:noreply,
       socket
       |> assign(
         glossary_entries: entries,
         glossary_form_params: draft_params,
         glossary_suggestion_draft: %{
           glossary: socket.assigns.glossary,
           original_glossary: socket.assigns.original_glossary,
           glossary_entries: entries,
           original_glossary_entries: socket.assigns.original_glossary_entries,
           glossary_form_params: draft_params,
           change_summary: socket.assigns.change_summary
         },
         glossary_draft_token: draft_token,
         pending_glossary_suggestion_redirect: true,
         glossary_back_path: maybe_with_draft_param("/#{handle}/-/glossary", draft_token)
       )
       |> push_patch(to: glossary_draft_path)}
    end
  end

  defp form_changed?(_params, nil, _original_overrides), do: true

  defp form_changed?(params, original_voice, original_overrides) do
    base_changed? =
      params["tone"] != (original_voice.tone || "") or
        params["formality"] != (original_voice.formality || "") or
        params["target_audience"] != (original_voice.target_audience || "") or
        params["guidelines"] != (original_voice.guidelines || "") or
        params["description"] != (original_voice.description || "")

    params_overrides =
      (params["overrides"] || %{})
      |> Enum.reject(fn {_idx, o} -> o["locale"] == "" or is_nil(o["locale"]) end)
      |> Enum.map(fn {_idx, o} -> normalize_override(o) end)
      |> MapSet.new()

    orig_overrides =
      original_overrides
      |> Enum.map(&normalize_override_struct/1)
      |> MapSet.new()

    base_changed? or params_overrides != orig_overrides
  end

  defp voice_field_changed?(params, original_voice, field) do
    original_value = voice_original_value(original_voice, field)
    current_value = Map.get(params || %{}, field, original_value)
    current_value != original_value
  end

  defp voice_target_countries_changed?(target_countries, nil), do: target_countries != []

  defp voice_target_countries_changed?(target_countries, original_voice) do
    target_countries != (original_voice.target_countries || [])
  end

  defp voice_cultural_notes_changed?(cultural_notes, nil), do: cultural_notes != %{}

  defp voice_cultural_notes_changed?(cultural_notes, original_voice) do
    cultural_notes != (original_voice.cultural_notes || %{})
  end

  defp voice_country_note_changed?(country_code, cultural_notes, nil) do
    Map.get(cultural_notes || %{}, country_code, "") != ""
  end

  defp voice_country_note_changed?(country_code, cultural_notes, original_voice) do
    current_note = Map.get(cultural_notes || %{}, country_code, "")
    original_note = Map.get(original_voice.cultural_notes || %{}, country_code, "")
    current_note != original_note
  end

  defp voice_override_changed?(override, original_overrides) do
    current_override = normalize_override_struct(override)

    original_overrides
    |> List.wrap()
    |> Enum.map(&normalize_override_struct/1)
    |> MapSet.new()
    |> MapSet.member?(current_override)
    |> Kernel.not()
  end

  defp voice_original_value(nil, _field), do: ""

  defp voice_original_value(voice, "description"), do: voice.description || ""
  defp voice_original_value(voice, "tone"), do: voice.tone || ""
  defp voice_original_value(voice, "formality"), do: voice.formality || ""
  defp voice_original_value(voice, "target_audience"), do: voice.target_audience || ""
  defp voice_original_value(voice, "guidelines"), do: voice.guidelines || ""
  defp voice_original_value(_voice, _field), do: ""

  defp glossary_entry_changed?(entry, original_entries) do
    case glossary_original_entry(entry, original_entries) do
      nil ->
        true

      original_entry ->
        glossary_entry_signature(entry) != glossary_entry_signature(original_entry)
    end
  end

  defp glossary_entry_field_changed?(entry, original_entries, :term) do
    case glossary_original_entry(entry, original_entries) do
      nil -> map_get(entry, :term, "") != ""
      _ -> false
    end
  end

  defp glossary_entry_field_changed?(entry, original_entries, :case_sensitive) do
    current_value = map_get(entry, :case_sensitive, false)

    case glossary_original_entry(entry, original_entries) do
      nil ->
        current_value

      original_entry ->
        current_value != map_get(original_entry, :case_sensitive, false)
    end
  end

  defp glossary_entry_field_changed?(entry, original_entries, :definition) do
    current_value = map_get(entry, :definition, "") || ""

    case glossary_original_entry(entry, original_entries) do
      nil ->
        current_value != ""

      original_entry ->
        current_value != (map_get(original_entry, :definition, "") || "")
    end
  end

  defp glossary_entry_field_changed?(_entry, _original_entries, _field), do: false

  defp glossary_translation_changed?(entry, translation, original_entries) do
    current_pair = {
      map_get(translation, :locale, ""),
      map_get(translation, :translation, "")
    }

    case glossary_original_entry(entry, original_entries) do
      nil ->
        current_pair != {"", ""}

      original_entry ->
        original_translation_pairs =
          original_entry
          |> map_get(:translations, [])
          |> List.wrap()
          |> Enum.map(fn original_translation ->
            {
              map_get(original_translation, :locale, ""),
              map_get(original_translation, :translation, "")
            }
          end)
          |> MapSet.new()

        not MapSet.member?(original_translation_pairs, current_pair)
    end
  end

  defp glossary_original_entry(entry, original_entries) do
    term = map_get(entry, :term, "")

    if term in [nil, ""] do
      nil
    else
      Enum.find(List.wrap(original_entries), fn original_entry ->
        map_get(original_entry, :term, "") == term
      end)
    end
  end

  defp form_changed_overrides?(overrides, original_overrides) do
    current =
      overrides
      |> Enum.reject(fn o -> (o.locale || "") == "" end)
      |> Enum.map(&normalize_override_struct/1)
      |> MapSet.new()

    original =
      original_overrides
      |> Enum.map(&normalize_override_struct/1)
      |> MapSet.new()

    current != original
  end

  defp normalize_override(o) do
    {o["locale"], o["tone"] || "", o["formality"] || "", o["target_audience"] || "",
     o["guidelines"] || ""}
  end

  defp normalize_override_struct(o) do
    {o.locale, o.tone || "", o.formality || "", o.target_audience || "", o.guidelines || ""}
  end

  defp voice_countries_changed?(target_countries, cultural_notes, nil),
    do: target_countries != [] or cultural_notes != %{}

  defp voice_countries_changed?(target_countries, cultural_notes, original_voice) do
    target_countries != (original_voice.target_countries || []) or
      cultural_notes != (original_voice.cultural_notes || %{})
  end

  # ---------------------------------------------------------------------------
  # Save form helpers (extracted to avoid splitting handle_event clauses)

  defp submit_voice_suggestion(params, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle

    merged_params = merge_suggestion_params(socket.assigns[:voice_form_params] || %{}, params)
    payload = voice_payload_from_params(merged_params, socket)
    base_version = socket.assigns.original_voice && socket.assigns.original_voice.version
    suggestion_title_text = suggestion_text_param(params, "suggestion_title", "request_title")
    suggestion_body_text = suggestion_text_param(params, "suggestion_body", "request_body")

    attrs = %{
      title: suggestion_title_text,
      body: suggestion_body_text,
      kind: "voice_suggestion",
      metadata: %{
        "resource" => "voice",
        "base_version" => base_version,
        "payload" => payload
      }
    }

    case Discussions.create_discussion(account, user, attrs) do
      {:ok, ticket} ->
        Auditing.record("voice.suggested", account, user,
          resource_type: "discussion",
          resource_id: to_string(ticket.id),
          resource_path: "/#{handle}/-/discussions/#{ticket.number}",
          summary: suggestion_title_text
        )

        {:noreply,
         socket
         |> assign(
           voice_suggestion_draft: nil,
           voice_draft_token: nil,
           pending_voice_suggestion_redirect: false,
           voice_back_path: "/#{handle}/-/voice"
         )
         |> put_flash(
           :info,
           gettext("Voice suggestion submitted as discussion #%{number}.", number: ticket.number)
         )
         |> push_patch(to: "/#{handle}/-/discussions/#{ticket.number}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit voice suggestion."))}
    end
  end

  defp submit_glossary_suggestion(params, change_note, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle

    merged_params = merge_suggestion_params(socket.assigns[:glossary_form_params] || %{}, params)
    payload = glossary_payload_from_params(merged_params)
    base_version = socket.assigns.original_glossary && socket.assigns.original_glossary.version
    suggestion_title_text = suggestion_text_param(params, "suggestion_title", "request_title")
    suggestion_body_text = suggestion_text_param(params, "suggestion_body", "request_body")

    attrs = %{
      title:
        if(suggestion_title_text != "",
          do: suggestion_title_text,
          else: suggestion_title(gettext("Glossary"), change_note)
        ),
      body:
        if(suggestion_body_text != "",
          do: suggestion_body_text,
          else: suggestion_body(gettext("glossary"), change_note)
        ),
      kind: "glossary_suggestion",
      metadata: %{
        "resource" => "glossary",
        "change_note" => change_note,
        "base_version" => base_version,
        "payload" => payload
      }
    }

    case Discussions.create_discussion(account, user, attrs) do
      {:ok, ticket} ->
        Auditing.record("glossary.suggested", account, user,
          resource_type: "discussion",
          resource_id: to_string(ticket.id),
          resource_path: "/#{handle}/-/discussions/#{ticket.number}",
          summary: change_note
        )

        {:noreply,
         socket
         |> assign(
           glossary_suggestion_draft: nil,
           glossary_draft_token: nil,
           pending_glossary_suggestion_redirect: false,
           glossary_back_path: "/#{handle}/-/glossary"
         )
         |> put_flash(
           :info,
           gettext("Glossary suggestion submitted as discussion #%{number}.",
             number: ticket.number
           )
         )
         |> push_patch(to: "/#{handle}/-/discussions/#{ticket.number}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit glossary suggestion."))}
    end
  end

  defp glossary_suggestion_change_note(params, socket) do
    suggestion_title_text = suggestion_text_param(params, "suggestion_title", "request_title")
    summary = String.trim(socket.assigns[:change_summary] || "")
    draft_note = String.trim((socket.assigns[:glossary_form_params] || %{})["change_note"] || "")

    cond do
      suggestion_title_text != "" -> suggestion_title_text
      summary != "" -> summary
      draft_note != "" -> draft_note
      true -> gettext("Glossary suggestion")
    end
  end

  defp voice_payload_from_params(params, socket) do
    voice_attrs = %{
      tone: params["tone"],
      formality: params["formality"],
      target_audience: params["target_audience"],
      guidelines: params["guidelines"],
      description: non_empty(params["description"]),
      target_countries: socket.assigns.target_countries,
      cultural_notes: socket.assigns.cultural_notes
    }

    overrides =
      (params["overrides"] || %{})
      |> Enum.reject(fn {_idx, o} -> o["locale"] == "" or is_nil(o["locale"]) end)
      |> Enum.map(fn {_idx, o} ->
        %{
          locale: o["locale"],
          tone: non_empty(o["tone"]),
          formality: non_empty(o["formality"]),
          target_audience: non_empty(o["target_audience"]),
          guidelines: non_empty(o["guidelines"])
        }
      end)

    Map.put(voice_attrs, :overrides, overrides)
  end

  defp glossary_payload_from_params(params) do
    entries =
      (params["entries"] || %{})
      |> Enum.sort_by(fn {idx, _} -> String.to_integer(idx) end)
      |> Enum.reject(fn {_idx, e} -> (e["term"] || "") == "" end)
      |> Enum.map(fn {_idx, e} ->
        translations =
          (e["translations"] || %{})
          |> Enum.sort_by(fn {tidx, _} -> String.to_integer(tidx) end)
          |> Enum.reject(fn {_tidx, t} ->
            (t["locale"] || "") == "" or (t["translation"] || "") == ""
          end)
          |> Enum.map(fn {_tidx, t} ->
            %{locale: t["locale"], translation: t["translation"]}
          end)

        %{
          term: e["term"],
          definition: non_empty(e["definition"]),
          case_sensitive: e["case_sensitive"] == "true",
          translations: translations
        }
      end)

    %{entries: entries}
  end

  defp suggestion_title(resource_name, change_note) do
    truncated = change_note |> String.trim() |> String.slice(0, 80)
    "#{resource_name} #{gettext("suggestion")}: #{truncated}"
  end

  defp suggestion_body(resource_name, change_note) do
    gettext(
      "Proposed %{resource} update.\n\nChange note: %{note}\n\nUse the discussion action to apply this suggestion when ready.",
      resource: resource_name,
      note: change_note
    )
  end

  defp apply_discussion_suggestion(ticket, account, user, handle) do
    cond do
      is_nil(user) ->
        {:error, :not_allowed}

      ticket.status != "open" ->
        {:error, :invalid_ticket}

      ticket.kind == "voice_suggestion" ->
        apply_voice_suggestion(ticket, account, user, handle)

      ticket.kind == "glossary_suggestion" ->
        apply_glossary_suggestion(ticket, account, user, handle)

      true ->
        {:error, :invalid_ticket}
    end
  end

  defp apply_voice_suggestion(ticket, account, user, handle) do
    if not Glossia.Policy.authorize?(:voice_write, user, account) do
      {:error, :not_allowed}
    else
      metadata = ticket.metadata || %{}
      payload = metadata["payload"]

      if not is_map(payload) do
        {:error, :invalid_payload}
      else
        case Voices.create_voice(account, payload, user) do
          {:ok, %{voice: voice}} ->
            maybe_close_discussion(ticket, user)

            _ =
              Discussions.add_comment(ticket, user, %{
                body: applied_comment(:voice, voice.version)
              })

            Auditing.record("voice.suggestion.applied", account, user,
              resource_type: "discussion",
              resource_id: to_string(ticket.id),
              resource_path: "/#{handle}/-/discussions/#{ticket.number}",
              summary: "Applied voice suggestion ##{ticket.number} as version ##{voice.version}"
            )

            {:ok,
             gettext("Applied voice suggestion as version #%{version}.", version: voice.version)}

          {:error, _step, _changeset, _changes} ->
            {:error, :invalid_payload}
        end
      end
    end
  end

  defp apply_glossary_suggestion(ticket, account, user, handle) do
    if not Glossia.Policy.authorize?(:glossary_write, user, account) do
      {:error, :not_allowed}
    else
      metadata = ticket.metadata || %{}
      payload = metadata["payload"]
      change_note = metadata["change_note"]

      if not is_map(payload) or not is_binary(change_note) or change_note == "" do
        {:error, :invalid_payload}
      else
        attrs = Map.put(payload, "change_note", change_note)

        case Glossaries.create_glossary(account, attrs, user) do
          {:ok, %{glossary: glossary}} ->
            maybe_close_discussion(ticket, user)

            _ =
              Discussions.add_comment(ticket, user, %{
                body: applied_comment(:glossary, glossary.version)
              })

            Auditing.record("glossary.suggestion.applied", account, user,
              resource_type: "discussion",
              resource_id: to_string(ticket.id),
              resource_path: "/#{handle}/-/discussions/#{ticket.number}",
              summary:
                "Applied glossary suggestion ##{ticket.number} as version ##{glossary.version}"
            )

            {:ok,
             gettext("Applied glossary suggestion as version #%{version}.",
               version: glossary.version
             )}

          {:error, _step, _changeset, _changes} ->
            {:error, :invalid_payload}
        end
      end
    end
  end

  defp maybe_close_discussion(%{status: "open"} = ticket, user) do
    _ = Discussions.close_discussion(ticket, user)
    :ok
  end

  defp maybe_close_discussion(_ticket, _user), do: :ok

  defp applied_comment(:voice, version),
    do: gettext("Applied this suggestion as voice version #%{version}.", version: version)

  defp applied_comment(:glossary, version),
    do: gettext("Applied this suggestion as glossary version #%{version}.", version: version)

  # LLM summary helpers
  # ---------------------------------------------------------------------------

  defp schedule_summary_generation(socket, context) do
    if timer = socket.assigns[:summary_timer_ref] do
      Process.cancel_timer(timer)
    end

    generation = (socket.assigns[:summary_generation] || 0) + 1
    timer_ref = Process.send_after(self(), {:generate_summary, context, generation}, 1_500)

    assign(socket,
      summary_generation: generation,
      summary_timer_ref: timer_ref
    )
  end

  defp cancel_summary_generation(socket) do
    if timer = socket.assigns[:summary_timer_ref] do
      Process.cancel_timer(timer)
    end

    assign(socket, summary_timer_ref: nil)
  end

  defp schedule_title_generation(socket, body) do
    if timer = socket.assigns[:ticket_title_timer_ref] do
      Process.cancel_timer(timer)
    end

    generation = (socket.assigns[:ticket_title_generation] || 0) + 1
    timer_ref = Process.send_after(self(), {:generate_ticket_title, generation}, 1_500)

    assign(socket,
      ticket_title_generation: generation,
      ticket_title_timer_ref: timer_ref,
      ticket_body_for_title: body
    )
  end

  defp cancel_title_generation(socket) do
    if timer = socket.assigns[:ticket_title_timer_ref] do
      Process.cancel_timer(timer)
    end

    assign(socket, ticket_title_timer_ref: nil)
  end

  # Country context generation (debounced)

  defp schedule_context_generation(socket) do
    if timer = socket.assigns[:context_timer_ref] do
      Process.cancel_timer(timer)
    end

    generation = (socket.assigns[:context_generation] || 0) + 1
    timer_ref = Process.send_after(self(), {:generate_cultural_notes, generation}, 2_000)

    assign(socket,
      context_generation: generation,
      context_timer_ref: timer_ref
    )
  end

  defp maybe_schedule_context_generation(socket, _code) do
    description = socket.assigns.voice_form_params["description"] || ""

    description =
      if description == "",
        do: if(socket.assigns.voice, do: socket.assigns.voice.description || "", else: ""),
        else: description

    if String.length(description) >= 20 do
      schedule_context_generation(socket)
    else
      socket
    end
  end

  defp save_bar_id(socket) do
    case socket.assigns.live_action do
      :voice -> "voice-save-bar"
      :glossary -> "glossary-save-bar"
      _ -> "save-bar"
    end
  end

  # ---------------------------------------------------------------------------
  # URL param encoding/decoding
  # ---------------------------------------------------------------------------

  # Table ID -> param prefix mapping
  @table_prefixes %{
    "projects-table" => "p",
    "activity-table" => "",
    "members-table" => "m",
    "invitations-table" => "i",
    "tokens-table" => "t",
    "oauth-apps-table" => "a",
    "discussions-table" => "k",
    "kits-table" => "kt",
    "translations-table" => "ts",
    "commits-table" => "c"
  }

  defp push_table_params(socket, table_id, overrides) do
    prefix = Map.get(@table_prefixes, table_id, "")
    handle = socket.assigns.handle
    action = socket.assigns.live_action

    current = current_table_state(socket, table_id)
    merged = Map.merge(current, overrides)

    query_params =
      []
      |> maybe_add_param(prefix <> "q", merged[:search], "")
      |> maybe_add_param(prefix <> "sort", merged[:sort], default_sort_key(table_id))
      |> maybe_add_param(prefix <> "dir", merged[:dir], default_sort_dir(table_id))
      |> maybe_add_param(prefix <> "page", merged[:page], 1)
      |> add_filter_params(prefix, merged[:filters] || %{})
      |> merge_other_table_params(socket, table_id)

    project_handle =
      if action in [:project_translations, :project_activity],
        do: socket.assigns.project.handle,
        else: nil

    path =
      case action do
        :logs -> "/#{handle}/-/logs"
        :members -> "/#{handle}/-/members"
        :api_tokens -> "/#{handle}/-/settings/tokens"
        :api_apps -> "/#{handle}/-/settings/apps"
        :kits -> "/#{handle}/-/kits"
        :discussions -> "/#{handle}/-/discussions"
        :project_translations -> "/#{handle}/#{project_handle}/-/translations"
        :project_activity -> "/#{handle}/#{project_handle}/-/activity"
        _ -> "/#{handle}"
      end

    url =
      if query_params == [] do
        path
      else
        path <> "?" <> URI.encode_query(query_params)
      end

    socket
    |> push_event("filters_updated:" <> table_id, %{active: merged[:filters] || %{}})
    |> push_patch(to: url)
  end

  defp maybe_add_param(params, _key, value, default) when value == default, do: params
  defp maybe_add_param(params, key, value, _default), do: params ++ [{key, to_string(value)}]

  defp maybe_add_flop_filters(params, filters, _filter_types) when map_size(filters) == 0,
    do: params

  defp maybe_add_flop_filters(params, filters, filter_types) do
    flop_filters =
      Enum.flat_map(filters, fn {field, values} ->
        type = Map.get(filter_types, field, "select")
        values = List.wrap(values)
        build_flop_filter(field, values, type)
      end)

    Map.put(params, "filters", flop_filters)
  end

  defp build_flop_filter(field, [range], "date_range") do
    case String.split(range, "..", parts: 2) do
      [from, to] ->
        filters = []

        filters =
          if from != "" do
            from_val =
              if String.contains?(from, "T"), do: from <> ":00", else: from <> "T00:00:00"

            filters ++ [%{"field" => field, "op" => ">=", "value" => from_val}]
          else
            filters
          end

        filters =
          if to != "" do
            to_val =
              if String.contains?(to, "T"), do: to <> ":59", else: to <> "T23:59:59"

            filters ++ [%{"field" => field, "op" => "<=", "value" => to_val}]
          else
            filters
          end

        filters

      _ ->
        []
    end
  end

  defp build_flop_filter(field, [text], "text") when text != "" do
    [%{"field" => field, "op" => "ilike", "value" => "%" <> text <> "%"}]
  end

  defp build_flop_filter(_field, _values, "text"), do: []

  defp build_flop_filter(field, [single], _type) do
    [%{"field" => field, "op" => "==", "value" => single}]
  end

  defp build_flop_filter(field, multiple, _type) do
    [%{"field" => field, "op" => "in", "value" => multiple}]
  end

  defp add_filter_params(params, _prefix, filters) when map_size(filters) == 0, do: params

  defp add_filter_params(params, prefix, filters) do
    Enum.reduce(filters, params, fn {key, values}, acc ->
      joined = values |> List.wrap() |> Enum.join(",")
      if joined == "", do: acc, else: acc ++ [{prefix <> "f_" <> key, joined}]
    end)
  end

  defp merge_other_table_params(params, socket, current_table_id) do
    case socket.assigns.live_action do
      :members ->
        tables = ["members-table", "invitations-table"]

        Enum.reduce(tables, params, fn tid, acc ->
          if tid == current_table_id do
            acc
          else
            prefix = Map.get(@table_prefixes, tid, "")
            state = current_table_state(socket, tid)

            acc
            |> maybe_add_param(prefix <> "q", state[:search], "")
            |> maybe_add_param(prefix <> "sort", state[:sort], default_sort_key(tid))
            |> maybe_add_param(prefix <> "dir", state[:dir], default_sort_dir(tid))
            |> maybe_add_param(prefix <> "page", state[:page], 1)
            |> add_filter_params(prefix, state[:filters] || %{})
          end
        end)

      _ ->
        params
    end
  end

  defp current_table_state(socket, "activity-table") do
    %{
      search: socket.assigns[:events_search] || "",
      sort: socket.assigns[:events_sort_key] || "date",
      dir: socket.assigns[:events_sort_dir] || "desc",
      page: socket.assigns[:events_page] || 1,
      filters: socket.assigns[:events_filters] || %{}
    }
  end

  defp current_table_state(socket, "members-table") do
    %{
      search: socket.assigns[:members_search] || "",
      sort: socket.assigns[:members_sort_key] || "name",
      dir: socket.assigns[:members_sort_dir] || "asc",
      page: socket.assigns[:members_page] || 1,
      filters: socket.assigns[:members_filters] || %{}
    }
  end

  defp current_table_state(socket, "invitations-table") do
    %{
      search: socket.assigns[:invitations_search] || "",
      sort: socket.assigns[:invitations_sort_key] || "email",
      dir: socket.assigns[:invitations_sort_dir] || "asc",
      page: 1,
      filters: %{}
    }
  end

  defp current_table_state(socket, "tokens-table") do
    %{
      search: socket.assigns[:tokens_search] || "",
      sort: socket.assigns[:tokens_sort_key] || "name",
      dir: socket.assigns[:tokens_sort_dir] || "asc",
      page: 1,
      filters: %{}
    }
  end

  defp current_table_state(socket, "oauth-apps-table") do
    %{
      search: socket.assigns[:apps_search] || "",
      sort: socket.assigns[:apps_sort_key] || "name",
      dir: socket.assigns[:apps_sort_dir] || "asc",
      page: 1,
      filters: %{}
    }
  end

  defp current_table_state(socket, "discussions-table") do
    %{
      search: "",
      sort: socket.assigns[:discussions_sort_key] || "inserted_at",
      dir: socket.assigns[:discussions_sort_dir] || "desc",
      page: 1,
      filters: socket.assigns[:discussions_active_filters] || %{}
    }
  end

  defp current_table_state(socket, "projects-table") do
    %{
      search: socket.assigns[:projects_search] || "",
      sort: socket.assigns[:projects_sort_key] || "name",
      dir: socket.assigns[:projects_sort_dir] || "asc",
      page: socket.assigns[:projects_page] || 1,
      filters: %{}
    }
  end

  defp current_table_state(socket, "translations-table") do
    %{
      search: socket.assigns[:translations_search] || "",
      sort: socket.assigns[:translations_sort_key] || "inserted_at",
      dir: socket.assigns[:translations_sort_dir] || "desc",
      page: socket.assigns[:translations_page] || 1,
      filters: socket.assigns[:translations_active_filters] || %{}
    }
  end

  defp current_table_state(socket, "commits-table") do
    %{
      search: socket.assigns[:commits_search] || "",
      sort: socket.assigns[:commits_sort_key] || "date",
      dir: socket.assigns[:commits_sort_dir] || "desc",
      page: 1,
      filters: %{}
    }
  end

  defp current_table_state(socket, "kits-table") do
    %{
      sort: socket.assigns[:kits_sort_key] || "inserted_at",
      dir: socket.assigns[:kits_sort_dir] || "desc",
      filters: socket.assigns[:kits_active_filters] || %{}
    }
  end

  defp current_table_state(_socket, _id),
    do: %{search: "", sort: "", dir: "asc", page: 1, filters: %{}}

  defp default_sort_key("commits-table"), do: "date"
  defp default_sort_key("projects-table"), do: "name"
  defp default_sort_key("activity-table"), do: "date"
  defp default_sort_key("members-table"), do: "name"
  defp default_sort_key("invitations-table"), do: "email"
  defp default_sort_key("tokens-table"), do: "name"
  defp default_sort_key("oauth-apps-table"), do: "name"
  defp default_sort_key("kits-table"), do: "inserted_at"
  defp default_sort_key("discussions-table"), do: "inserted_at"
  defp default_sort_key("translations-table"), do: "inserted_at"
  defp default_sort_key(_), do: ""

  defp default_sort_dir("activity-table"), do: "desc"
  defp default_sort_dir("kits-table"), do: "desc"
  defp default_sort_dir("discussions-table"), do: "desc"
  defp default_sort_dir("translations-table"), do: "desc"
  defp default_sort_dir("commits-table"), do: "desc"
  defp default_sort_dir(_), do: "asc"

  defp current_sort(socket, "activity-table"),
    do: {socket.assigns.events_sort_key, socket.assigns.events_sort_dir}

  defp current_sort(socket, "members-table"),
    do: {socket.assigns.members_sort_key, socket.assigns.members_sort_dir}

  defp current_sort(socket, "invitations-table"),
    do: {socket.assigns.invitations_sort_key, socket.assigns.invitations_sort_dir}

  defp current_sort(socket, "tokens-table"),
    do: {socket.assigns[:tokens_sort_key] || "name", socket.assigns[:tokens_sort_dir] || "asc"}

  defp current_sort(socket, "oauth-apps-table"),
    do: {socket.assigns[:apps_sort_key] || "name", socket.assigns[:apps_sort_dir] || "asc"}

  defp current_sort(socket, "kits-table"),
    do:
      {socket.assigns[:kits_sort_key] || "inserted_at", socket.assigns[:kits_sort_dir] || "desc"}

  defp current_sort(socket, "discussions-table"),
    do:
      {socket.assigns[:discussions_sort_key] || "inserted_at",
       socket.assigns[:discussions_sort_dir] || "desc"}

  defp current_sort(socket, "projects-table"),
    do:
      {socket.assigns[:projects_sort_key] || "name", socket.assigns[:projects_sort_dir] || "asc"}

  defp current_sort(socket, "translations-table"),
    do:
      {socket.assigns[:translations_sort_key] || "inserted_at",
       socket.assigns[:translations_sort_dir] || "desc"}

  defp current_sort(socket, "commits-table"),
    do: {socket.assigns[:commits_sort_key] || "date", socket.assigns[:commits_sort_dir] || "desc"}

  defp current_sort(_socket, _), do: {"", "asc"}

  defp current_filters(socket, "activity-table"), do: socket.assigns.events_filters
  defp current_filters(socket, "members-table"), do: socket.assigns.members_filters

  defp current_filters(socket, "discussions-table"),
    do: socket.assigns[:discussions_active_filters] || %{}

  defp current_filters(socket, "translations-table"),
    do: socket.assigns[:translations_active_filters] || %{}

  defp current_filters(_socket, _), do: %{}

  defp apply_url_params_activity(socket, params) do
    prefix = "c"
    search = Map.get(params, prefix <> "q", "")
    sort_key = Map.get(params, prefix <> "sort", "date")
    sort_dir = Map.get(params, prefix <> "dir", "desc")

    all_commits = socket.assigns[:all_commits] || []

    filtered =
      if search == "" do
        all_commits
      else
        needle = String.downcase(search)

        Enum.filter(all_commits, fn commit ->
          String.contains?(String.downcase(commit.message || ""), needle) ||
            String.contains?(String.downcase(commit.author_name || ""), needle) ||
            String.contains?(String.downcase(commit.short_sha || ""), needle)
        end)
      end

    sorted = sort_commits(filtered, sort_key, sort_dir)

    assign(socket,
      commits_search: search,
      commits_sort_key: sort_key,
      commits_sort_dir: sort_dir,
      commits: sorted
    )
  end

  defp sort_commits(commits, "author", dir) do
    Enum.sort_by(commits, &String.downcase(&1.author_name || ""), sort_direction(dir))
  end

  defp sort_commits(commits, "message", dir) do
    Enum.sort_by(commits, &String.downcase(&1.message || ""), sort_direction(dir))
  end

  defp sort_commits(commits, _key, dir) do
    Enum.sort_by(commits, & &1.date, {sort_direction(dir), DateTime})
  end

  defp sort_direction("asc"), do: :asc
  defp sort_direction(_), do: :desc

  defp apply_url_params_translations(socket, params) do
    prefix = "ts"
    search = Map.get(params, prefix <> "q", "")
    sort_key = Map.get(params, prefix <> "sort", "inserted_at")
    sort_dir = Map.get(params, prefix <> "dir", "desc")
    page = parse_int(Map.get(params, prefix <> "page"), 1)
    active_filters = extract_filters(params, prefix)

    order_dir = if sort_dir == "desc", do: :desc, else: :asc
    order_by = if sort_key == "status", do: :status, else: :inserted_at

    flop_params =
      %{
        "page" => page,
        "page_size" => 25,
        "order_by" => [Atom.to_string(order_by)],
        "order_directions" => [Atom.to_string(order_dir)]
      }
      |> maybe_add_flop_filters(active_filters, @translations_filter_types)

    project = socket.assigns.project

    {sessions, total} =
      case Glossia.TranslationSessions.list_project_sessions(project, flop_params) do
        {:ok, {sessions, meta}} -> {sessions, meta.total_count}
        _ -> {[], 0}
      end

    assign(socket,
      translations: sessions,
      translations_total: total,
      translations_search: search,
      translations_sort_key: sort_key,
      translations_sort_dir: sort_dir,
      translations_page: page,
      translations_active_filters: active_filters
    )
  end

  defp apply_url_params_project_new(socket, params) do
    step = Map.get(params, "step", "repo")

    case step do
      "languages" ->
        if socket.assigns[:wizard_selected_repo] do
          assign(socket, wizard_step: "languages", wizard_language_search: "")
        else
          assign(socket, wizard_step: "repo")
        end

      "setup" ->
        project = socket.assigns[:wizard_project]

        if project do
          # Re-fetch from DB to get current setup_status (may have changed via Oban worker)
          project = Glossia.Repo.get(Glossia.Accounts.Project, project.id) || project
          setup_events = Glossia.Ingestion.list_setup_events(project.id)

          socket =
            if connected?(socket) and project.setup_status in ["pending", "running"] do
              Glossia.Projects.subscribe_setup_events(project)
              socket
            else
              socket
            end

          socket
          |> assign(wizard_project: project)
          |> assign(wizard_step: "setup", setup_events: setup_events)
        else
          assign(socket, wizard_step: "repo")
        end

      _ ->
        assign(socket, wizard_step: "repo")
    end
  end

  defp apply_url_params_projects(socket, params) do
    prefix = "p"
    search = Map.get(params, prefix <> "q", "")
    sort_key = Map.get(params, prefix <> "sort", "name")
    sort_dir = Map.get(params, prefix <> "dir", "asc")
    page = parse_int(Map.get(params, prefix <> "page"), 1)

    socket
    |> assign(
      projects_search: search,
      projects_sort_key: sort_key,
      projects_sort_dir: sort_dir,
      projects_page: page
    )
    |> reload_projects()
  end

  defp reload_projects(socket) do
    account = socket.assigns.account
    search = socket.assigns.projects_search
    sort_key = socket.assigns.projects_sort_key
    sort_dir = socket.assigns.projects_sort_dir
    page = socket.assigns.projects_page

    order_dir = if sort_dir == "desc", do: :desc, else: :asc

    order_by =
      case sort_key do
        "handle" -> :handle
        "inserted_at" -> :inserted_at
        _ -> :name
      end

    flop_params = %{
      page: page,
      page_size: 25,
      order_by: [order_by],
      order_directions: [order_dir]
    }

    flop_params =
      if search != "" do
        Map.put(flop_params, :filters, [%{field: :name, op: :ilike_and, value: search}])
      else
        flop_params
      end

    {projects, total} =
      case Glossia.Projects.list_projects(account, flop_params) do
        {:ok, {projects, meta}} -> {projects, meta.total_count}
        _ -> {[], 0}
      end

    assign(socket, projects: projects, projects_total: total)
  end

  defp apply_url_params_kits(socket, params) do
    prefix = "kt"
    sort_key = Map.get(params, prefix <> "sort", "inserted_at")
    sort_dir = Map.get(params, prefix <> "dir", "desc")
    active_filters = extract_filters(params, prefix)

    flop_params =
      %{
        "order_by" => [sort_key],
        "order_directions" => [sort_dir]
      }
      |> maybe_add_flop_filters(active_filters, %{})

    {:ok, {kits, _meta}} = Kits.list_kits(socket.assigns.account, flop_params)

    assign(socket,
      kits: kits,
      kits_sort_key: sort_key,
      kits_sort_dir: sort_dir,
      kits_active_filters: active_filters
    )
  end

  defp apply_url_params_logs(socket, params) do
    socket
    |> assign(
      events_search: Map.get(params, "q", ""),
      events_sort_key: Map.get(params, "sort", "date"),
      events_sort_dir: Map.get(params, "dir", "desc"),
      events_page: parse_int(Map.get(params, "page"), 1),
      events_filters: extract_filters(params, "")
    )
    |> apply_events_filters()
  end

  defp apply_url_params_members(socket, params) do
    socket
    |> assign(
      members_search: Map.get(params, "mq", ""),
      members_sort_key: Map.get(params, "msort", "name"),
      members_sort_dir: Map.get(params, "mdir", "asc"),
      members_page: parse_int(Map.get(params, "mpage"), 1),
      members_filters: extract_filters(params, "m"),
      invitations_search: Map.get(params, "iq", ""),
      invitations_sort_key: Map.get(params, "isort", "email"),
      invitations_sort_dir: Map.get(params, "idir", "asc")
    )
    |> apply_members_filters()
    |> apply_invitations_filters()
  end

  defp apply_url_params_voice(socket, params) do
    token = Map.get(params, "draft")
    handle = socket.assigns.handle

    case decode_draft_token(token) do
      %{"voice_form_params" => form_params} = decoded ->
        draft_params = sanitize_voice_form_params(form_params)

        target_countries =
          normalize_draft_string_list(
            decoded["target_countries"],
            socket.assigns.target_countries
          )

        cultural_notes =
          normalize_draft_string_map(decoded["cultural_notes"], socket.assigns.cultural_notes)

        overrides = parse_voice_overrides_from_params(draft_params, socket.assigns.overrides)

        base_changed? =
          form_changed?(
            draft_params,
            socket.assigns.original_voice,
            socket.assigns.original_overrides
          )

        countries_changed? =
          voice_countries_changed?(
            target_countries,
            cultural_notes,
            socket.assigns.original_voice
          )

        assign(socket,
          voice_form_params: draft_params,
          overrides: overrides,
          target_countries: target_countries,
          cultural_notes: cultural_notes,
          changed?: base_changed? or countries_changed?,
          change_summary: to_string(decoded["change_summary"] || ""),
          voice_draft_token: token,
          voice_back_path: maybe_with_draft_param("/#{handle}/-/voice", token)
        )

      _ ->
        case socket.assigns[:voice_suggestion_draft] do
          %{
            voice_form_params: draft_params,
            overrides: draft_overrides,
            target_countries: draft_countries,
            cultural_notes: draft_notes
          } = draft ->
            fallback_token =
              existing_token_from_assign(socket, :voice_draft_token) ||
                encode_draft_token(%{
                  "voice_form_params" => sanitize_voice_form_params(draft_params || %{}),
                  "target_countries" => draft_countries || [],
                  "cultural_notes" => draft_notes || %{},
                  "change_summary" => draft[:change_summary] || ""
                })

            base_changed? =
              form_changed?(
                draft_params,
                socket.assigns.original_voice,
                socket.assigns.original_overrides
              )

            countries_changed? =
              voice_countries_changed?(
                draft_countries || [],
                draft_notes || %{},
                socket.assigns.original_voice
              )

            assign(socket,
              voice_form_params: draft_params || %{},
              overrides: draft_overrides || socket.assigns.overrides,
              target_countries: draft_countries || socket.assigns.target_countries,
              cultural_notes: draft_notes || socket.assigns.cultural_notes,
              changed?: base_changed? or countries_changed?,
              change_summary: draft[:change_summary] || "",
              voice_draft_token: fallback_token,
              voice_back_path: maybe_with_draft_param("/#{handle}/-/voice", fallback_token)
            )

          _ ->
            assign(socket,
              voice_draft_token: nil,
              voice_back_path: "/#{handle}/-/voice"
            )
        end
    end
  end

  defp apply_url_params_glossary(socket, params) do
    token = Map.get(params, "draft")
    handle = socket.assigns.handle

    case decode_draft_token(token) do
      %{"glossary_form_params" => form_params} = decoded ->
        draft_params = sanitize_glossary_form_params(form_params)

        entries =
          parse_glossary_entries_from_params(draft_params, socket.assigns.glossary_entries)

        changed? =
          glossary_entries_index(entries) !=
            glossary_entries_index(socket.assigns.original_glossary_entries)

        assign(socket,
          glossary_form_params: draft_params,
          glossary_entries: entries,
          glossary_changed?: changed?,
          change_summary: to_string(decoded["change_summary"] || ""),
          glossary_draft_token: token,
          glossary_back_path: maybe_with_draft_param("/#{handle}/-/glossary", token)
        )

      _ ->
        case socket.assigns[:glossary_suggestion_draft] do
          %{glossary_form_params: draft_params, glossary_entries: draft_entries} = draft ->
            fallback_token =
              existing_token_from_assign(socket, :glossary_draft_token) ||
                encode_draft_token(%{
                  "glossary_form_params" => sanitize_glossary_form_params(draft_params || %{}),
                  "change_summary" => draft[:change_summary] || ""
                })

            changed? =
              glossary_entries_index(draft_entries || []) !=
                glossary_entries_index(socket.assigns.original_glossary_entries)

            assign(socket,
              glossary_form_params: draft_params || %{},
              glossary_entries: draft_entries || socket.assigns.glossary_entries,
              glossary_changed?: changed?,
              change_summary: draft[:change_summary] || "",
              glossary_draft_token: fallback_token,
              glossary_back_path: maybe_with_draft_param("/#{handle}/-/glossary", fallback_token)
            )

          _ ->
            assign(socket,
              glossary_draft_token: nil,
              glossary_back_path: "/#{handle}/-/glossary"
            )
        end
    end
  end

  defp extract_filters(params, prefix) do
    filter_prefix = prefix <> "f_"

    params
    |> Enum.filter(fn {k, v} -> String.starts_with?(k, filter_prefix) && v != "" end)
    |> Enum.into(%{}, fn {k, v} ->
      key = String.replace_prefix(k, filter_prefix, "")
      {key, String.split(v, ",", trim: true)}
    end)
  end

  defp parse_int(nil, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> max(1, n)
      :error -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val

  # ---------------------------------------------------------------------------
  # Activity event filtering / sorting / pagination
  # ---------------------------------------------------------------------------

  @events_per_page 25

  defp apply_events_filters(socket) do
    %{
      all_events: all,
      events_search: search,
      events_sort_key: sort_key,
      events_sort_dir: sort_dir,
      events_filters: filters,
      events_page: page
    } = socket.assigns

    filtered =
      all
      |> filter_events_by_search(search)
      |> filter_events_by_filters(filters)
      |> sort_events(sort_key, sort_dir)

    total = length(filtered)
    max_page = max(1, ceil(total / @events_per_page))
    clamped_page = min(max(1, page), max_page)
    events = Enum.slice(filtered, (clamped_page - 1) * @events_per_page, @events_per_page)

    assign(socket, events: events, events_total: total, events_page: clamped_page)
  end

  defp filter_events_by_search(events, ""), do: events

  defp filter_events_by_search(events, query) do
    q = String.downcase(query)

    Enum.filter(events, fn e ->
      String.contains?(String.downcase(e.summary), q) or
        String.contains?(String.downcase(e.name), q) or
        String.contains?(String.downcase(e.actor_handle), q) or
        String.contains?(String.downcase(e.actor_email), q)
    end)
  end

  defp filter_events_by_filters(events, filters) when map_size(filters) == 0, do: events

  defp filter_events_by_filters(events, filters) do
    Enum.filter(events, fn e ->
      Enum.all?(filters, fn
        {"type", values} -> e.name in List.wrap(values)
        _ -> true
      end)
    end)
  end

  defp sort_events(events, key, dir) do
    sorter =
      case key do
        "summary" -> & &1.summary
        "actor" -> & &1.actor_handle
        "date" -> & &1.inserted_at
        _ -> & &1.inserted_at
      end

    sorted = Enum.sort_by(events, sorter)
    if dir == "desc", do: Enum.reverse(sorted), else: sorted
  end

  # ---------------------------------------------------------------------------
  # Members filtering / sorting / pagination
  # ---------------------------------------------------------------------------

  @members_per_page 10

  defp apply_members_filters(socket) do
    %{
      all_members: all,
      members_search: search,
      members_sort_key: sort_key,
      members_sort_dir: sort_dir,
      members_filters: filters,
      members_page: page
    } = socket.assigns

    filtered =
      all
      |> filter_members_by_search(search)
      |> filter_members_by_role(filters)
      |> sort_members(sort_key, sort_dir)

    total = length(filtered)
    max_page = max(1, ceil(total / @members_per_page))
    clamped_page = min(max(1, page), max_page)
    members = Enum.slice(filtered, (clamped_page - 1) * @members_per_page, @members_per_page)

    assign(socket, members: members, members_total: total, members_page: clamped_page)
  end

  defp filter_members_by_search(members, ""), do: members

  defp filter_members_by_search(members, query) do
    q = String.downcase(query)

    Enum.filter(members, fn m ->
      name = String.downcase(m.user.name || "")
      email = String.downcase(m.user.email)
      String.contains?(name, q) or String.contains?(email, q)
    end)
  end

  defp filter_members_by_role(members, filters) when map_size(filters) == 0, do: members

  defp filter_members_by_role(members, filters) do
    case Map.get(filters, "role") do
      nil ->
        members

      [] ->
        members

      roles ->
        roles = List.wrap(roles)
        Enum.filter(members, &(&1.role in roles))
    end
  end

  defp sort_members(members, key, dir) do
    sorter =
      case key do
        "name" -> fn m -> String.downcase(m.user.name || m.user.email) end
        "email" -> fn m -> String.downcase(m.user.email) end
        "role" -> fn m -> m.role end
        "joined" -> fn m -> m.inserted_at end
        _ -> fn m -> String.downcase(m.user.name || m.user.email) end
      end

    sorted = Enum.sort_by(members, sorter)
    if dir == "desc", do: Enum.reverse(sorted), else: sorted
  end

  # ---------------------------------------------------------------------------
  # Invitations filtering / sorting
  # ---------------------------------------------------------------------------

  defp apply_invitations_filters(socket) do
    %{
      all_invitations: all,
      invitations_search: search,
      invitations_sort_key: sort_key,
      invitations_sort_dir: sort_dir
    } = socket.assigns

    filtered =
      all
      |> filter_invitations_by_search(search)
      |> sort_invitations(sort_key, sort_dir)

    assign(socket, pending_invitations: filtered)
  end

  defp filter_invitations_by_search(invitations, ""), do: invitations

  defp filter_invitations_by_search(invitations, query) do
    q = String.downcase(query)

    Enum.filter(invitations, fn inv ->
      String.contains?(String.downcase(inv.email), q)
    end)
  end

  defp sort_invitations(invitations, key, dir) do
    sorter =
      case key do
        "email" ->
          fn inv -> String.downcase(inv.email) end

        "role" ->
          fn inv -> inv.role end

        "invited_by" ->
          fn inv ->
            (inv.invited_by && String.downcase(inv.invited_by.name || inv.invited_by.email)) || ""
          end

        "expires" ->
          fn inv -> inv.expires_at end

        _ ->
          fn inv -> String.downcase(inv.email) end
      end

    sorted = Enum.sort_by(invitations, sorter)
    if dir == "desc", do: Enum.reverse(sorted), else: sorted
  end

  # ---------------------------------------------------------------------------
  # Page: Kits
  # ---------------------------------------------------------------------------

  defp kits_page(assigns) do
    case assigns.live_action do
      :kits -> kits_list_page(assigns)
      :kit_new -> kit_new_page(assigns)
      :kit_show -> kit_show_page(assigns)
      :kit_edit -> kit_edit_page(assigns)
      :kit_term_new -> kit_term_new_page(assigns)
      :kit_term_edit -> kit_term_edit_page(assigns)
    end
  end

  defp kits_list_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Kits")}
        description={gettext("Shareable translation terminology bundles.")}
      >
        <:actions>
          <%= if @can_kit_write do %>
            <.link patch={"/" <> @handle <> "/-/kits/new"} class="dash-btn dash-btn-primary">
              {gettext("New kit")}
            </.link>
          <% end %>
        </:actions>
      </.page_header>
      <.resource_table
        id="kits-table"
        rows={@kits}
        sort_key={@kits_sort_key}
        sort_dir={@kits_sort_dir}
      >
        <:col :let={kit} label={gettext("Name")} key="name" sortable>
          <.link
            patch={"/" <> @handle <> "/-/kits/" <> kit.handle}
            class="resource-link"
          >
            {kit.name}
          </.link>
        </:col>
        <:col :let={kit} label={gettext("Source")} key="source_language" sortable>
          {kit.source_language}
        </:col>
        <:col :let={kit} label={gettext("Targets")}>
          {Enum.join(kit.target_languages, ", ")}
        </:col>
        <:col :let={kit} label={gettext("Visibility")}>
          <.badge variant={if kit.visibility == "public", do: "info", else: "default"}>
            {kit.visibility}
          </.badge>
        </:col>
        <:col :let={kit} label={gettext("Stars")}>
          {kit.stars_count}
        </:col>
        <:col :let={kit} label={gettext("Created")} key="inserted_at" sortable>
          {Calendar.strftime(kit.inserted_at, "%b %d, %Y")}
        </:col>
        <:empty>
          <div class="dash-empty-state">
            <svg
              width="32"
              height="32"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="m7.5 4.27 9 5.15" /><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" /><path d="m3.3 7 8.7 5 8.7-5" /><path d="M12 22V12" />
            </svg>
            <h2>{gettext("No kits yet")}</h2>
            <p>{gettext("Create a kit to bundle translation terminology for sharing.")}</p>
          </div>
        </:empty>
      </.resource_table>
    </div>
    """
  end

  defp kit_new_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.form for={@kit_form} id="kit-form" phx-change="kit_validate" phx-submit="create_kit">
        <div class="dash-form-section">
          <h2 class="dash-form-section-title">{gettext("Kit details")}</h2>
          <div class="dash-form-grid">
            <.input
              field={@kit_form[:handle]}
              type="text"
              label={gettext("Handle")}
              placeholder="e.g. medical-terms"
            />
            <.input
              field={@kit_form[:name]}
              type="text"
              label={gettext("Name")}
              placeholder="e.g. Medical Terminology"
            />
          </div>
          <.input field={@kit_form[:description]} type="textarea" label={gettext("Description")} />
          <div class="dash-form-grid">
            <.input
              field={@kit_form[:source_language]}
              type="text"
              label={gettext("Source language")}
              placeholder="e.g. en"
            />
            <.input
              field={@kit_form[:visibility]}
              type="select"
              label={gettext("Visibility")}
              options={[{gettext("Public"), "public"}, {gettext("Private"), "private"}]}
            />
          </div>
        </div>
        <.form_save_bar
          id="kit-save-bar"
          visible={@kit_form_valid?}
          cancel_path={"/" <> @handle <> "/-/kits"}
        />
      </.form>
    </div>
    """
  end

  defp kit_show_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header title={@kit.name} description={@kit.description}>
        <:actions>
          <%= if @current_user do %>
            <%= if @kit_starred? do %>
              <button phx-click="unstar_kit" class="dash-btn dash-btn-secondary">
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  aria-hidden="true"
                >
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                </svg>
                <span>{@kit.stars_count}</span>
              </button>
            <% else %>
              <button phx-click="star_kit" class="dash-btn dash-btn-secondary">
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  aria-hidden="true"
                >
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                </svg>
                <span>{@kit.stars_count}</span>
              </button>
            <% end %>
          <% end %>
          <%= if @can_kit_write do %>
            <.link
              patch={"/" <> @handle <> "/-/kits/" <> @kit.handle <> "/edit"}
              class="dash-btn dash-btn-secondary"
            >
              {gettext("Edit")}
            </.link>
            <.link
              patch={"/" <> @handle <> "/-/kits/" <> @kit.handle <> "/terms/new"}
              class="dash-btn dash-btn-primary"
            >
              {gettext("Add term")}
            </.link>
          <% end %>
        </:actions>
      </.page_header>

      <div
        class="dash-metadata"
        style="margin-bottom: var(--space-6); display: flex; gap: var(--space-4); flex-wrap: wrap;"
      >
        <.badge variant="info">{@kit.source_language}</.badge>
        <span style="color: var(--color-text-muted);">&rarr;</span>
        <%= for lang <- @kit.target_languages do %>
          <.badge>{lang}</.badge>
        <% end %>
        <%= if @kit.visibility == "private" do %>
          <.badge variant="warning">{gettext("Private")}</.badge>
        <% end %>
      </div>

      <%= if @kit.terms != [] do %>
        <table class="dash-table" id="kit-terms-table">
          <thead>
            <tr>
              <th>{gettext("Term")}</th>
              <th>{gettext("Definition")}</th>
              <th>{gettext("Translations")}</th>
              <%= if @can_kit_write do %>
                <th style="width: 100px;">{gettext("Actions")}</th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= for term <- @kit.terms do %>
              <tr id={"term-#{term.id}"}>
                <td>
                  <%= if @can_kit_write do %>
                    <.link
                      patch={"/" <> @handle <> "/-/kits/" <> @kit.handle <> "/terms/" <> term.id}
                      class="resource-link"
                    >
                      {term.source_term}
                    </.link>
                  <% else %>
                    {term.source_term}
                  <% end %>
                </td>
                <td style="color: var(--color-text-muted);">{term.definition || "-"}</td>
                <td>
                  <%= for t <- term.translations do %>
                    <span style="display: inline-block; margin-right: var(--space-2);">
                      <strong>{t.language}:</strong> {t.translated_term}
                    </span>
                  <% end %>
                </td>
                <%= if @can_kit_write do %>
                  <td>
                    <button
                      phx-click="delete_kit_term"
                      phx-value-term-id={term.id}
                      data-confirm={gettext("Are you sure you want to delete this term?")}
                      class="dash-btn dash-btn-danger dash-btn-sm"
                    >
                      {gettext("Delete")}
                    </button>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% else %>
        <div class="dash-empty-state">
          <svg
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="m7.5 4.27 9 5.15" /><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" /><path d="m3.3 7 8.7 5 8.7-5" /><path d="M12 22V12" />
          </svg>
          <h2>{gettext("No terms yet")}</h2>
          <p>{gettext("Add terms to this kit.")}</p>
        </div>
      <% end %>

      <%= if @can_kit_write do %>
        <div style="margin-top: var(--space-8); padding-top: var(--space-6); border-top: 1px solid var(--color-border);">
          <h3 style="color: var(--color-danger); margin-bottom: var(--space-4);">
            {gettext("Danger zone")}
          </h3>
          <button
            phx-click="delete_kit"
            data-confirm={
              gettext("Are you sure you want to delete this kit? This action cannot be undone.")
            }
            class="dash-btn dash-btn-danger"
          >
            {gettext("Delete kit")}
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp kit_edit_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.form for={@kit_form} id="kit-edit-form" phx-change="kit_validate" phx-submit="update_kit">
        <div class="dash-form-section">
          <h2 class="dash-form-section-title">{gettext("Edit kit")}</h2>
          <div class="dash-form-grid">
            <.input field={@kit_form[:handle]} type="text" label={gettext("Handle")} />
            <.input field={@kit_form[:name]} type="text" label={gettext("Name")} />
          </div>
          <.input field={@kit_form[:description]} type="textarea" label={gettext("Description")} />
          <div class="dash-form-grid">
            <.input
              field={@kit_form[:source_language]}
              type="text"
              label={gettext("Source language")}
            />
            <.input
              field={@kit_form[:visibility]}
              type="select"
              label={gettext("Visibility")}
              options={[{gettext("Public"), "public"}, {gettext("Private"), "private"}]}
            />
          </div>
        </div>
        <.form_save_bar
          id="kit-edit-save-bar"
          visible={@kit_form_valid? and @kit_edit_changed?}
          cancel_path={"/" <> @handle <> "/-/kits/" <> @kit.handle}
        />
      </.form>
    </div>
    """
  end

  defp kit_term_new_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.form
        for={@term_form}
        id="term-form"
        phx-change="term_validate"
        phx-submit="create_kit_term"
      >
        <div class="dash-form-section">
          <h2 class="dash-form-section-title">{gettext("New term")}</h2>
          <.input
            field={@term_form[:source_term]}
            type="text"
            label={gettext("Source term")}
            placeholder="e.g. diagnosis"
          />
          <.input field={@term_form[:definition]} type="textarea" label={gettext("Definition")} />
        </div>

        <div class="dash-form-section">
          <h2 class="dash-form-section-title">{gettext("Translations")}</h2>
          <%= for {t, idx} <- Enum.with_index(@kit.target_languages) do %>
            <div class="dash-form-grid" style="align-items: end;">
              <input type="hidden" name={"term[translations][#{idx}][language]"} value={t} />
              <div>
                <label class="dash-label">{gettext("Language")}</label>
                <input
                  type="text"
                  value={t}
                  disabled
                  class="dash-input"
                  style="opacity: 0.6; cursor: not-allowed;"
                />
              </div>
              <div>
                <label class="dash-label">{gettext("Translation")}</label>
                <input
                  type="text"
                  name={"term[translations][#{idx}][translated_term]"}
                  class="dash-input"
                />
              </div>
              <div>
                <label class="dash-label">{gettext("Usage note")}</label>
                <input
                  type="text"
                  name={"term[translations][#{idx}][usage_note]"}
                  class="dash-input"
                />
              </div>
            </div>
          <% end %>
        </div>

        <.form_save_bar
          id="term-save-bar"
          visible={@term_form_valid?}
          cancel_path={"/" <> @handle <> "/-/kits/" <> @kit.handle}
        />
      </.form>
    </div>
    """
  end

  defp kit_term_edit_page(assigns) do
    assigns =
      assign(
        assigns,
        :translations_by_lang,
        Map.new(assigns.term.translations || [], fn t -> {t.language, t} end)
      )

    ~H"""
    <div class="dash-page">
      <.form
        for={@term_form}
        id="term-edit-form"
        phx-change="term_validate"
        phx-submit="update_kit_term"
      >
        <div class="dash-form-section">
          <h2 class="dash-form-section-title">{gettext("Edit term")}</h2>
          <.input field={@term_form[:source_term]} type="text" label={gettext("Source term")} />
          <.input field={@term_form[:definition]} type="textarea" label={gettext("Definition")} />
        </div>

        <div class="dash-form-section">
          <h2 class="dash-form-section-title">{gettext("Translations")}</h2>
          <%= for {lang, idx} <- Enum.with_index(@kit.target_languages) do %>
            <% t = Map.get(@translations_by_lang, lang) %>
            <div class="dash-form-grid" style="align-items: end;">
              <input type="hidden" name={"term[translations][#{idx}][language]"} value={lang} />
              <div>
                <label class="dash-label">{gettext("Language")}</label>
                <input
                  type="text"
                  value={lang}
                  disabled
                  class="dash-input"
                  style="opacity: 0.6; cursor: not-allowed;"
                />
              </div>
              <div>
                <label class="dash-label">{gettext("Translation")}</label>
                <input
                  type="text"
                  name={"term[translations][#{idx}][translated_term]"}
                  value={if(t, do: t.translated_term, else: "")}
                  class="dash-input"
                />
              </div>
              <div>
                <label class="dash-label">{gettext("Usage note")}</label>
                <input
                  type="text"
                  name={"term[translations][#{idx}][usage_note]"}
                  value={if(t, do: t.usage_note || "", else: "")}
                  class="dash-input"
                />
              </div>
            </div>
          <% end %>
        </div>

        <.form_save_bar
          id="term-edit-save-bar"
          visible={@term_form_valid? and @term_edit_changed?}
          cancel_path={"/" <> @handle <> "/-/kits/" <> @kit.handle}
        />
      </.form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Tickets
  # ---------------------------------------------------------------------------

  defp discussions_page(assigns) do
    case assigns.live_action do
      :discussions -> discussions_list_page(assigns)
      :discussion_new -> ticket_new_page(assigns)
      :discussion_show -> ticket_show_page(assigns)
    end
  end

  defp discussions_list_page(assigns) do
    assigns =
      assign(assigns,
        ticket_filters: [
          %{key: "title", label: gettext("Title"), type: "text"},
          %{
            key: "status",
            label: gettext("Status"),
            type: "select",
            options: [
              %{value: "open", label: gettext("Open")},
              %{value: "closed", label: gettext("Closed")}
            ]
          },
          %{
            key: "kind",
            label: gettext("Type"),
            type: "select",
            options: [
              %{value: "general", label: gettext("General")},
              %{value: "voice_suggestion", label: gettext("Voice suggestion")},
              %{value: "glossary_suggestion", label: gettext("Glossary suggestion")}
            ]
          },
          %{key: "inserted_at", label: gettext("Created"), type: "date_range"}
        ]
      )

    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Discussions")}
        description={gettext("Track bugs, suggestions, and discussions.")}
      >
        <:actions>
          <%= if @current_user do %>
            <.link patch={"/" <> @handle <> "/-/discussions/new"} class="dash-btn dash-btn-primary">
              {gettext("New discussion")}
            </.link>
          <% end %>
        </:actions>
      </.page_header>
      <.resource_table
        id="discussions-table"
        rows={@tickets}
        sort_key={@discussions_sort_key}
        sort_dir={@discussions_sort_dir}
        filters={@ticket_filters}
        active_filters={@discussions_active_filters}
      >
        <:col :let={ticket} label={gettext("Number")} key="number" sortable>
          <.link
            patch={"/" <> @handle <> "/-/discussions/" <> Integer.to_string(ticket.number)}
            class="resource-link"
          >
            {"##{ticket.number}"}
          </.link>
        </:col>
        <:col :let={ticket} label={gettext("Title")} key="title" sortable>
          <.link
            patch={"/" <> @handle <> "/-/discussions/" <> Integer.to_string(ticket.number)}
            class="resource-link"
          >
            {ticket.title}
          </.link>
          <%= if ticket.kind != "general" do %>
            <span style="margin-left: var(--space-2);">
              <.badge variant={ticket_kind_variant(ticket.kind)}>
                {ticket_kind_label(ticket.kind)}
              </.badge>
            </span>
          <% end %>
        </:col>
        <:col :let={ticket} label={gettext("Status")} key="status" sortable>
          <.badge variant={ticket_status_variant(ticket.status)}>
            {ticket_status_label(ticket.status)}
          </.badge>
        </:col>
        <:col :let={ticket} label={gettext("Created")} key="inserted_at" sortable>
          {Calendar.strftime(ticket.inserted_at, "%b %d, %Y")}
        </:col>
        <:action :let={ticket}>
          <.link
            patch={"/" <> @handle <> "/-/discussions/" <> Integer.to_string(ticket.number)}
            class="dash-btn dash-btn-secondary dash-btn-sm"
          >
            {gettext("View")}
          </.link>
        </:action>
        <:empty>
          <div class="dash-empty-state">
            <svg
              width="32"
              height="32"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <h2>{gettext("No discussions yet")}</h2>
            <p>{gettext("Create one to track a bug, suggestion, or discussion.")}</p>
          </div>
        </:empty>
      </.resource_table>
    </div>
    """
  end

  defp ticket_new_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("New discussion")}
        description={gettext("Describe what you want to report or discuss.")}
      />
      <.form
        for={@ticket_form}
        id="ticket-form"
        phx-submit="create_discussion"
        phx-change="discussion_validate"
        class="ticket-form"
      >
        <div class="ticket-form-field">
          <label for="ticket_title">{gettext("Title")}</label>
          <div class={["ticket-title-wrapper", @generating_title? && "generating"]}>
            <input
              type="text"
              name="ticket[title]"
              id="ticket_title"
              value={@ticket_form[:title].value}
              placeholder={
                if @generating_title?,
                  do: gettext("Generating..."),
                  else: gettext("Brief summary...")
              }
              phx-hook=".TicketTitle"
              required
              disabled={@generating_title?}
            />
          </div>
        </div>
        <div class="ticket-form-field">
          <label>{gettext("Description")}</label>
          <.markdown_editor
            id="ticket-body-editor"
            name="ticket[body]"
            value={@ticket_form[:body].value}
            placeholder={gettext("Provide details...")}
            rows={6}
            required
            upload={get_in(assigns, [:uploads, :ticket_images])}
          />
        </div>
        <div class="ticket-form-actions">
          <.link patch={"/" <> @handle <> "/-/discussions"} class="dash-btn dash-btn-secondary">
            {gettext("Cancel")}
          </.link>
          <button type="submit" class="dash-btn dash-btn-primary">
            {gettext("Submit new discussion")}
          </button>
        </div>
      </.form>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".TicketTitle">
        export default {
          mounted() {
            this.handleEvent("title_generated", ({title}) => {
              this.el.value = title;
            });
          }
        }
      </script>
    </div>
    """
  end

  defp ticket_show_page(assigns) do
    ~H"""
    <div class="dash-page">
      <div class="ticket-detail-header">
        <div>
          <h1 class="ticket-detail-title">
            {@ticket.title}
            <span class="ticket-detail-number">{"##{@ticket.number}"}</span>
          </h1>
          <div class="ticket-detail-meta">
            <.badge variant={ticket_status_variant(@ticket.status)}>
              {ticket_status_label(@ticket.status)}
            </.badge>
            <%= if @ticket.kind != "general" do %>
              <.badge variant={ticket_kind_variant(@ticket.kind)}>
                {ticket_kind_label(@ticket.kind)}
              </.badge>
            <% end %>
            <span class="ticket-detail-date">
              {gettext("Opened by %{author} on %{date}",
                author: @ticket.user.name || @ticket.user.email,
                date: Calendar.strftime(@ticket.inserted_at, "%b %d, %Y")
              )}
            </span>
          </div>
        </div>
        <%= if @can_write or can_apply_suggestion?(@ticket, @can_voice_write, @can_glossary_write) do %>
          <div class="ticket-detail-actions">
            <%= if can_apply_suggestion?(@ticket, @can_voice_write, @can_glossary_write) and
                  @ticket.status == "open" do %>
              <button phx-click="apply_suggestion" class="dash-btn dash-btn-primary">
                {gettext("Apply suggestion")}
              </button>
            <% end %>
            <%= if @ticket.status == "open" do %>
              <%= if @can_write do %>
                <button phx-click="close_discussion" class="dash-btn dash-btn-secondary">
                  {gettext("Close discussion")}
                </button>
              <% end %>
            <% else %>
              <%= if @can_write do %>
                <button phx-click="reopen_discussion" class="dash-btn dash-btn-secondary">
                  {gettext("Reopen discussion")}
                </button>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>
      <div class="ticket-body-section" id="ticket-body">
        <div class="ticket-body-content prose">{raw(render_markdown(@ticket.body))}</div>
      </div>
      <div class="ticket-conversation-label">
        {gettext("Comments (%{count})", count: length(@ticket.comments))}
      </div>
      <div class="ticket-conversation">
        <div
          :for={comment <- @ticket.comments}
          class="ticket-comment"
          id={"comment-" <> comment.id}
        >
          <div class="ticket-comment-header">
            <a href={"/" <> comment.user.account.handle} class="ticket-comment-author">
              <img
                src={user_avatar_url(comment.user)}
                alt=""
                width="20"
                height="20"
                class="ticket-comment-avatar"
              />
              {"@#{comment.user.account.handle}"}
            </a>
            <div class="ticket-comment-header-right">
              <a href={"#comment-" <> comment.id} class="ticket-comment-time">
                {Calendar.strftime(comment.inserted_at, "%b %d, %Y at %H:%M")}
              </a>
              <%= if @current_user do %>
                <button
                  type="button"
                  class="ticket-comment-quote-btn"
                  phx-click="quote_reply"
                  phx-value-body={comment.body}
                  title={gettext("Quote reply")}
                >
                  <svg
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                  >
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
                  </svg>
                </button>
              <% end %>
            </div>
          </div>
          <div class="ticket-comment-body prose">{raw(render_markdown(comment.body))}</div>
        </div>
      </div>
      <%= if @current_user do %>
        <.form
          for={@comment_form}
          id="comment-form"
          phx-submit="add_discussion_comment"
          class="ticket-reply-form"
        >
          <.markdown_editor
            id="comment-body-editor"
            name="comment[body]"
            value={@comment_form[:body].value}
            placeholder={gettext("Leave a comment...")}
            rows={3}
            required
            upload={get_in(assigns, [:uploads, :comment_images])}
          />
          <div class="ticket-reply-actions">
            <.link patch={"/" <> @handle <> "/-/discussions"} class="dash-btn dash-btn-secondary">
              {gettext("Cancel")}
            </.link>
            <button type="submit" class="dash-btn dash-btn-primary">
              {gettext("Comment")}
            </button>
          </div>
        </.form>
      <% end %>
    </div>
    """
  end

  defp ticket_status_variant("open"), do: "success"
  defp ticket_status_variant("closed"), do: "neutral"
  defp ticket_status_variant(_), do: "neutral"

  defp ticket_status_label("open"), do: gettext("Open")
  defp ticket_status_label("closed"), do: gettext("Closed")
  defp ticket_status_label(other), do: other

  defp ticket_kind_variant("voice_suggestion"), do: "info"
  defp ticket_kind_variant("glossary_suggestion"), do: "warning"
  defp ticket_kind_variant(_), do: "neutral"

  defp ticket_kind_label("voice_suggestion"), do: gettext("Voice suggestion")
  defp ticket_kind_label("glossary_suggestion"), do: gettext("Glossary suggestion")
  defp ticket_kind_label("general"), do: gettext("General")
  defp ticket_kind_label(other), do: other

  defp can_apply_suggestion?(ticket, can_voice_write, can_glossary_write) do
    ticket.status == "open" and
      ((ticket.kind == "voice_suggestion" and can_voice_write) or
         (ticket.kind == "glossary_suggestion" and can_glossary_write))
  end

  defp render_markdown(nil), do: ""
  defp render_markdown(""), do: ""

  defp render_markdown(text) do
    case Earmark.as_html(text, %Earmark.Options{code_class_prefix: "language-"}) do
      {:ok, html, _} -> html
      {:error, html, _} -> html
    end
    |> String.replace(~r/<script[\s\S]*?<\/script>/i, "")
  end

  defp maybe_allow_upload(socket, name) do
    cond do
      not connected?(socket) ->
        socket

      Map.has_key?(socket.assigns, :uploads) and Map.has_key?(socket.assigns.uploads, name) ->
        socket

      true ->
        allow_upload(socket, name,
          accept: ~w(.jpg .jpeg .png .gif .webp),
          max_entries: 5,
          max_file_size: 10_000_000,
          auto_upload: true,
          progress: &handle_upload_progress/3
        )
    end
  end

  defp handle_upload_progress(_upload_name, entry, socket) do
    if entry.done? do
      uploaded_url =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          content = File.read!(path)
          ext = upload_entry_extension(entry)
          uuid = Uniq.UUID.uuid7()
          account_id = socket.assigns.account.id

          context_id =
            if Map.has_key?(socket.assigns, :upload_context_id),
              do: socket.assigns.upload_context_id,
              else: socket.assigns.ticket.id

          s3_path = "uploads/#{account_id}/discussions/#{context_id}/#{uuid}.#{ext}"
          {:ok, _} = Glossia.Storage.upload(s3_path, content, content_type: entry.client_type)
          {:ok, url} = Glossia.Storage.presigned_url(s3_path, expires_in: 604_800)
          {:ok, url}
        end)

      editor_id =
        if Map.has_key?(socket.assigns, :upload_context_id),
          do: "ticket-body-editor",
          else: "comment-body-editor"

      {:noreply,
       push_event(socket, "image_uploaded:#{editor_id}", %{
         url: uploaded_url,
         filename: entry.client_name
       })}
    else
      {:noreply, socket}
    end
  end

  defp upload_entry_extension(entry) do
    case entry.client_type do
      "image/jpeg" -> "jpg"
      "image/png" -> "png"
      "image/gif" -> "gif"
      "image/webp" -> "webp"
      _ -> "bin"
    end
  end
end
