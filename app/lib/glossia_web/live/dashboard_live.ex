defmodule GlossiaWeb.DashboardLive do
  use GlossiaWeb, :live_view

  require Logger

  import GlossiaWeb.DashboardComponents

  alias Glossia.Accounts
  alias Glossia.ChangeSummary
  alias Glossia.AccountTokens
  alias Glossia.Glossaries
  alias Glossia.Organizations
  alias Glossia.Discussions
  alias Glossia.LLMModels
  alias Glossia.TranslationSessions.Progress
  alias Glossia.Translations.Failure
  alias Glossia.Voices
  alias Noora.Filter

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
        :account ->
          apply_url_params_projects(socket, params)

        :members ->
          apply_url_params_members(socket, params)

        :voice ->
          apply_url_params_voice(socket, params)

        action when action in [:glossary, :glossary_entry, :glossary_entry_new] ->
          apply_url_params_glossary(socket, params)

        :project ->
          apply_url_params_activity(socket, params)

        :project_translations ->
          apply_url_params_translations(socket, params)

        :project_new ->
          apply_url_params_project_new(socket, params)

        _ ->
          socket
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

    assign(socket,
      page_title: socket.assigns.handle,
      projects: projects,
      projects_total: total,
      projects_search: "",
      projects_sort_key: "name",
      projects_sort_dir: "asc",
      projects_page: 1,
      breadcrumb_items: []
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
      page_title: gettext("Terminology"),
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
      terminology_entry_index: nil,
      pending_glossary_suggestion_redirect:
        socket.assigns[:pending_glossary_suggestion_redirect] || false,
      glossary_back_path: maybe_with_draft_param("/#{handle}/-/terminology", existing_token),
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      breadcrumb_items: [{gettext("Terminology"), "/" <> handle <> "/-/terminology"}]
    )
  end

  defp apply_action(socket, :glossary_entry_new, _params) do
    require_action!(socket, :glossary_read)
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle
    can_glossary_write = socket.assigns[:can_glossary_write] || false
    can_glossary_propose = socket.assigns[:can_glossary_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    unless can_discussion_write and (can_glossary_propose or can_glossary_write) do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end

    glossary = Glossaries.get_latest_glossary(account)
    entries = if glossary, do: glossary.entries || [], else: []
    new_entry = %{term: "", definition: nil, case_sensitive: false, translations: []}
    editable_entries = entries ++ [new_entry]
    entry_index = length(entries)

    socket
    |> assign_terminology_entry_state(
      glossary: glossary,
      original_entries: entries,
      editable_entries: editable_entries,
      entry_index: entry_index,
      page_title: gettext("New term"),
      glossary_changed?: true,
      can_glossary_write: can_glossary_write,
      can_glossary_propose: can_glossary_propose,
      can_discussion_write: can_discussion_write,
      breadcrumb_items: [
        {gettext("Terminology"), "/" <> handle <> "/-/terminology"},
        {gettext("New term"), nil}
      ]
    )
  end

  defp apply_action(socket, :glossary_entry, %{"entry_index" => entry_index_str}) do
    require_action!(socket, :glossary_read)
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle
    can_glossary_write = socket.assigns[:can_glossary_write] || false
    can_glossary_propose = socket.assigns[:can_glossary_propose] || false

    can_discussion_write =
      not is_nil(user) and Glossia.Policy.authorize?(:discussion_write, user, account)

    glossary = Glossaries.get_latest_glossary(account)
    entries = if glossary, do: glossary.entries || [], else: []
    entry_index = String.to_integer(entry_index_str)
    entry = Enum.at(entries, entry_index)

    unless entry do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.GlossaryEntry
    end

    socket
    |> assign_terminology_entry_state(
      glossary: glossary,
      original_entries: entries,
      editable_entries: entries,
      entry_index: entry_index,
      page_title: terminology_term_label(entry),
      glossary_changed?: false,
      can_glossary_write: can_glossary_write,
      can_glossary_propose: can_glossary_propose,
      can_discussion_write: can_discussion_write,
      breadcrumb_items: [
        {gettext("Terminology"), "/" <> handle <> "/-/terminology"},
        {terminology_term_label(entry), nil}
      ]
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
      page_title: gettext("Suggest terminology changes"),
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
      glossary_back_path: maybe_with_draft_param("/#{handle}/-/terminology", draft_token),
      change_summary: change_summary,
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      breadcrumb_items: [
        {gettext("Terminology"),
         maybe_with_draft_param("/" <> handle <> "/-/terminology", draft_token)},
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
      page_title: gettext("Terminology #%{version}", version: version),
      glossary: glossary,
      previous_glossary: previous,
      can_glossary_write: socket.assigns[:can_glossary_write] || false,
      breadcrumb_items: [
        {gettext("Terminology"), "/" <> handle <> "/-/terminology"},
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

        unless socket.assigns.is_admin do
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

    available_filters = settings_available_filters(:tokens)
    active_filters = Filter.Operations.decode_filters_from_query(params, available_filters)
    search = Map.get(params, "tq", "")
    sort_key = Map.get(params, "tsort", "name")
    sort_dir = Map.get(params, "tdir", "asc")

    flop_params =
      %{
        "order_by" => [sort_key],
        "order_directions" => [sort_dir]
      }
      |> maybe_add_flop_filters(
        if(search == "", do: %{}, else: %{"name" => search}),
        %{"name" => "text"}
      )
      |> add_noora_flop_filters(Filter.Operations.convert_filters_to_flop(active_filters))

    {:ok, {tokens, _meta}} = AccountTokens.list_account_tokens(account, flop_params)
    available_scopes = available_scopes()

    assign(socket,
      page_title: gettext("Tokens"),
      api_tokens: tokens,
      available_scopes: available_scopes,
      newly_created_token: nil,
      tokens_search: search,
      tokens_sort_key: sort_key,
      tokens_sort_dir: sort_dir,
      available_filters: available_filters,
      active_filters: active_filters,
      settings_query_params: params,
      settings_filter_path: "/" <> handle <> "/-/settings/tokens",
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Tokens"), "/" <> handle <> "/-/settings/tokens"}
      ]
    )
  end

  defp apply_action(socket, :api_tokens_new, _params) do
    require_admin!(socket)
    handle = socket.assigns.handle

    assign(socket,
      page_title: gettext("New token"),
      available_scopes: available_scopes(),
      token_form:
        to_form(%{"name" => "", "description" => "", "scopes" => [], "expiration" => "90"},
          as: :token
        ),
      newly_created_token: nil,
      token_form_valid?: false,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Tokens"), "/" <> handle <> "/-/settings/tokens"},
        {gettext("New token"), nil}
      ]
    )
  end

  defp apply_action(socket, :api_token_edit, params) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle
    token = AccountTokens.get_account_token!(params["token_id"], account.id)
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
        {gettext("Tokens"), "/" <> handle <> "/-/settings/tokens"},
        {token.name, nil}
      ]
    )
  end

  defp apply_action(socket, :api_apps, params) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle

    available_filters = settings_available_filters(:oauth_apps)
    active_filters = Filter.Operations.decode_filters_from_query(params, available_filters)
    search = Map.get(params, "aq", "")
    sort_key = Map.get(params, "asort", "name")
    sort_dir = Map.get(params, "adir", "asc")

    flop_params =
      %{
        "order_by" => [sort_key],
        "order_directions" => [sort_dir]
      }
      |> maybe_add_flop_filters(
        if(search == "", do: %{}, else: %{"name" => search}),
        %{"name" => "text"}
      )
      |> add_noora_flop_filters(Filter.Operations.convert_filters_to_flop(active_filters))

    {:ok, {apps, _meta}} = AccountTokens.list_oauth_applications(account, flop_params)

    assign(socket,
      page_title: gettext("OAuth Apps"),
      oauth_apps: apps,
      newly_created_secret: nil,
      apps_search: search,
      apps_sort_key: sort_key,
      apps_sort_dir: sort_dir,
      available_filters: available_filters,
      active_filters: active_filters,
      settings_query_params: params,
      settings_filter_path: "/" <> handle <> "/-/settings/apps",
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
    app = AccountTokens.get_oauth_application!(app_id, account.id)
    client = AccountTokens.get_boruta_client_for_app(app)

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

  defp apply_action(socket, :llm_models, params) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle

    available_filters = settings_available_filters(:llm_models)
    active_filters = Filter.Operations.decode_filters_from_query(params, available_filters)
    search = Map.get(params, "mdq", Map.get(params, "mq", ""))
    sort_key = Map.get(params, "mdsort", Map.get(params, "msort", "handle"))
    sort_dir = Map.get(params, "mddir", Map.get(params, "mdir", "asc"))

    flop_params =
      %{
        "order_by" => [sort_key],
        "order_directions" => [sort_dir]
      }
      |> maybe_add_flop_filters(
        if(search == "", do: %{}, else: %{"handle" => search}),
        %{"handle" => "text"}
      )
      |> add_noora_flop_filters(Filter.Operations.convert_filters_to_flop(active_filters))

    {:ok, {models, _meta}} = LLMModels.list_models(account, flop_params)

    assign(socket,
      page_title: gettext("Models"),
      llm_models: models,
      models_search: search,
      models_sort_key: sort_key,
      models_sort_dir: sort_dir,
      available_filters: available_filters,
      active_filters: active_filters,
      settings_query_params: params,
      settings_filter_path: "/" <> handle <> "/-/settings/models",
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Models"), "/" <> handle <> "/-/settings/models"}
      ]
    )
  end

  defp apply_action(socket, :llm_model_new, _params) do
    require_admin!(socket)
    handle = socket.assigns.handle
    model_picker_options = model_picker_options()

    assign(socket,
      page_title: gettext("New model"),
      model_form:
        to_form(
          %{"handle" => "", "model" => "", "api_key" => ""},
          as: :model
        ),
      model_form_valid?: false,
      model_picker_options_json: JSON.encode!(model_picker_options),
      model_picker_option_count: length(model_picker_options),
      model_picker_selected_label: nil,
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Models"), "/" <> handle <> "/-/settings/models"},
        {gettext("New model"), nil}
      ]
    )
  end

  defp apply_action(socket, :llm_model_edit, %{"model_id" => model_id}) do
    require_admin!(socket)
    account = socket.assigns.account
    handle = socket.assigns.handle
    model = LLMModels.get_model!(model_id, account.id)
    model_picker_options = model_picker_options()

    assign(socket,
      page_title: model.handle,
      editing_model: model,
      model_edit_form:
        to_form(
          %{
            "handle" => model.handle,
            "model" => model.model,
            "api_key" => ""
          },
          as: :model
        ),
      model_edit_original: %{
        "handle" => model.handle,
        "model" => model.model
      },
      model_edit_changed?: false,
      model_picker_options_json: JSON.encode!(model_picker_options),
      model_picker_option_count: length(model_picker_options),
      model_picker_selected_label:
        Enum.find_value(model_picker_options, fn [label, value] ->
          value == model.model && label
        end),
      breadcrumb_items: [
        {gettext("Settings"), nil},
        {gettext("Models"), "/" <> handle <> "/-/settings/models"},
        {model.handle, nil}
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

        if Glossia.Github.App.configured?() do
          case Glossia.Github.Installations.reconcile_for_organization(
                 user,
                 socket.assigns.account
               ) do
            {:ok, _installation} ->
              :ok

            {:error, reason}
            when reason in [
                   :installation_not_found,
                   :github_identity_not_found,
                   :github_access_token_not_found
                 ] ->
              :ok

            {:error, reason} ->
              Logger.warning("Could not reconcile GitHub installation",
                account_id: socket.assigns.account.id,
                reason: inspect(reason)
              )
          end
        end

        installations = Glossia.Github.Installations.list_installations_for_user(user)

        imported_repositories =
          Glossia.Projects.list_imported_github_repositories(socket.assigns.account)

        development_repositories = Glossia.Github.DevelopmentRepositories.list()

        repos =
          (if installations != [] && Glossia.Github.App.configured?() do
             installations
             |> Enum.flat_map(fn installation ->
               case fetch_github_repos_via_installation(installation) do
                 {:ok, repos} -> repos
                 {:error, _} -> []
               end
             end)
           else
             case fetch_github_repos_via_oauth(user) do
               {:ok, repos} -> repos
               {:error, _} -> []
             end
           end ++ development_repositories)
          |> Enum.uniq_by(& &1["id"])
          |> Enum.sort_by(& &1["full_name"])
          |> filter_imported_repositories(imported_repositories)

        github_connected? =
          installations != [] || Glossia.Accounts.get_github_token_for_user(user.id) != nil ||
            development_repositories != []

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

  defp apply_action(socket, :discussion_show, params) do
    account = socket.assigns.account

    number_str =
      Map.get(params, "suggestion_number") ||
        Map.get(params, "discussion_number") ||
        Map.get(params, "ticket_number")

    ticket_number =
      case Integer.parse(number_str || "") do
        {number, ""} -> number
        _ -> raise Ecto.NoResultsError, queryable: Glossia.Discussions.Discussion
      end

    ticket = Discussions.get_discussion_by_number!(ticket_number, account.id)

    socket
    |> maybe_allow_upload(:comment_images)
    |> assign(
      page_title: ticket.title,
      ticket: ticket,
      comment_form: to_form(%{"body" => ""}, as: :comment),
      breadcrumb_items: [{ticket_kind_label(ticket.kind), nil}]
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
    project = maybe_backfill_setup_pull_request(project, setup_events)
    {all_commits, commits_error} = fetch_or_reuse_project_commits(socket, project)
    sessions_by_sha = Glossia.TranslationSessions.sessions_by_commit_sha(project)

    socket =
      if connected?(socket) and
           (project.setup_status in ["pending", "running"] or
              project.setup_pull_request_state == "open") do
        subscribe_to_setup_events(socket, project)
      else
        socket
      end

    assign(socket,
      page_title: project.name,
      project: project,
      project_name: project.name,
      og_image_url: og_image_url,
      all_commits: all_commits,
      all_commits_project_id: project.id,
      commits: all_commits,
      commits_search: "",
      commits_sort_key: "date",
      commits_sort_dir: "desc",
      commits_error: commits_error,
      sessions_by_sha: sessions_by_sha,
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

    session = Glossia.TranslationSessions.get_session!(account, project, session_id)
    events = Glossia.Ingestion.list_translation_session_events(session.id)

    socket =
      if connected?(socket) and session.status in ["pending", "running"] do
        Glossia.TranslationSessions.subscribe_session_events(session)
        socket
      else
        socket
      end

    socket
    |> assign(
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
    |> assign_translation_progress(Glossia.TranslationSessions.Progress.new())
  end

  defp apply_action(socket, :project_translations, %{"project" => project_handle}) do
    account = socket.assigns.account
    handle = socket.assigns.handle
    project = Glossia.Projects.get_project(account, project_handle)
    available_filters = translation_available_filters()

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    assign(socket,
      page_title: gettext("Translations"),
      project: project,
      available_filters: available_filters,
      breadcrumb_items: [
        {project.handle, "/" <> handle <> "/" <> project.handle},
        {gettext("Translations"), nil}
      ],
      sidebar_context: :project,
      sidebar_project: project
    )
  end

  defp assign_terminology_entry_state(socket, opts) do
    handle = socket.assigns.handle
    existing_draft = socket.assigns[:glossary_suggestion_draft]
    existing_token = socket.assigns[:glossary_draft_token]

    assign(socket,
      page_title: Keyword.fetch!(opts, :page_title),
      glossary: Keyword.fetch!(opts, :glossary),
      glossary_versions: [],
      glossary_suggestions: [],
      glossary_entries: Keyword.fetch!(opts, :editable_entries),
      original_glossary: Keyword.fetch!(opts, :glossary),
      original_glossary_entries: Keyword.fetch!(opts, :original_entries),
      terminology_entry_index: Keyword.fetch!(opts, :entry_index),
      can_glossary_write: Keyword.fetch!(opts, :can_glossary_write),
      can_glossary_propose: Keyword.fetch!(opts, :can_glossary_propose),
      can_glossary_suggest?: Keyword.fetch!(opts, :can_discussion_write),
      can_glossary_submit?: Keyword.fetch!(opts, :can_discussion_write),
      glossary_changed?: Keyword.fetch!(opts, :glossary_changed?),
      glossary_form_params: %{},
      glossary_suggestion_draft: existing_draft,
      glossary_draft_token: existing_token,
      pending_glossary_suggestion_redirect:
        socket.assigns[:pending_glossary_suggestion_redirect] || false,
      glossary_back_path: maybe_with_draft_param("/#{handle}/-/terminology", existing_token),
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      breadcrumb_items: Keyword.fetch!(opts, :breadcrumb_items)
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

  defp fetch_or_reuse_project_commits(socket, project) do
    if socket.assigns[:all_commits_project_id] == project.id do
      {socket.assigns[:all_commits] || [], socket.assigns[:commits_error]}
    else
      fetch_project_commits(project)
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
      {"chore: update translation terminology for Spanish locale",
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
    Glossia.Authz.available_scopes()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @acronyms ~w(api llm oauth)

  defp humanize_scope_group("glossary"), do: gettext("Terminology")

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

  defp token_scope_summary(token) do
    scopes = String.split(token.scope || "", " ", trim: true)

    case scopes do
      [] ->
        gettext("No scopes")

      scopes ->
        summary =
          scopes
          |> Enum.take(2)
          |> Enum.map(&humanize_scope/1)
          |> Enum.join(", ")

        if length(scopes) > 2, do: summary <> ", ...", else: summary
    end
  end

  # ---------------------------------------------------------------------------
  # LLM model events
  # ---------------------------------------------------------------------------

  def handle_event("validate_model", %{"model" => params}, socket) do
    changeset = model_form_changeset(params)

    {:noreply,
     assign(socket,
       model_form: to_form(changeset, as: :model),
       model_form_valid?: changeset.valid?
     )}
  end

  def handle_event("select_model", %{"value" => value}, socket) do
    params = put_model_form_value(socket.assigns.model_form, value)
    changeset = model_form_changeset(params)

    {:noreply,
     assign(socket,
       model_form: to_form(changeset, as: :model),
       model_form_valid?: changeset.valid?
     )}
  end

  def handle_event("validate_model_edit", %{"model" => params}, socket) do
    changeset = model_edit_form_changeset(socket.assigns.editing_model, params)

    {:noreply,
     assign(socket,
       model_edit_form: to_form(changeset, as: :model),
       model_edit_changed?:
         changeset.valid? and changed_model_form?(params, socket.assigns.model_edit_original)
     )}
  end

  def handle_event("select_model_edit", %{"value" => value}, socket) do
    params = put_model_form_value(socket.assigns.model_edit_form, value)
    changeset = model_edit_form_changeset(socket.assigns.editing_model, params)

    {:noreply,
     assign(socket,
       model_edit_form: to_form(changeset, as: :model),
       model_edit_changed?:
         changeset.valid? and changed_model_form?(params, socket.assigns.model_edit_original)
     )}
  end

  def handle_event("create_model", %{"model" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user

      case LLMModels.create_model(account, user, params) do
        {:ok, _model} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Model created."))
           |> push_patch(to: ~p"/#{socket.assigns.handle}/-/settings/models")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(model_form: to_form(changeset, as: :model), model_form_valid?: false)
           |> put_flash(:error, gettext("Could not create model."))}
      end
    end
  end

  def handle_event("update_model", %{"model" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user
      model = socket.assigns.editing_model

      # Only include api_key if a new one was provided
      attrs =
        if String.trim(params["api_key"] || "") == "" do
          Map.delete(params, "api_key")
        else
          params
        end

      case LLMModels.update_model(account, user, model, attrs) do
        {:ok, _updated} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Model updated."))
           |> push_patch(to: ~p"/#{socket.assigns.handle}/-/settings/models")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(
             model_edit_form: to_form(changeset, as: :model),
             model_edit_changed?: false
           )
           |> put_flash(:error, gettext("Could not update model."))}
      end
    end
  end

  def handle_event("set_default_model", %{"id" => model_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user

      case LLMModels.get_model(model_id, account.id) do
        nil ->
          {:noreply, put_flash(socket, :error, gettext("Model not found."))}

        model ->
          case LLMModels.update_model(account, user, model, %{"default" => true}) do
            {:ok, updated} ->
              {:noreply,
               socket
               |> assign(editing_model: updated)
               |> put_flash(:info, gettext("Default model updated."))}

            {:error, _changeset} ->
              {:noreply,
               put_flash(socket, :error, gettext("Could not update the default model."))}
          end
      end
    end
  end

  def handle_event("delete_model", %{"id" => model_id}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      account = socket.assigns.account
      user = socket.assigns.current_user

      case LLMModels.get_model(model_id, account.id) do
        nil ->
          {:noreply, put_flash(socket, :error, gettext("Model not found."))}

        model ->
          case LLMModels.delete_model(account, user, model) do
            {:ok, _} ->
              {:ok, {models, _meta}} = LLMModels.list_models(account)

              {:noreply,
               socket
               |> assign(llm_models: models)
               |> put_flash(:info, gettext("Model deleted."))
               |> push_patch(to: ~p"/#{socket.assigns.handle}/-/settings/models")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, gettext("Could not delete model."))}
          end
      end
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

  def handle_event("select_voice_tone", params, socket) do
    handle_voice_select("tone", params, socket)
  end

  def handle_event("select_voice_formality", params, socket) do
    handle_voice_select("formality", params, socket)
  end

  def handle_event("select_voice_country", params, socket) do
    case noora_select_value(params) do
      nil -> {:noreply, socket}
      code -> handle_event("add_country", %{"code" => code}, socket)
    end
  end

  def handle_event("select_voice_override_locale:" <> idx, params, socket) do
    handle_voice_override_select(idx, :locale, params, socket)
  end

  def handle_event("select_voice_override_tone:" <> idx, params, socket) do
    handle_voice_override_select(idx, :tone, params, socket)
  end

  def handle_event("select_voice_override_formality:" <> idx, params, socket) do
    handle_voice_override_select(idx, :formality, params, socket)
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

  def handle_event("remove_country", %{"data" => code}, socket) do
    handle_event("remove_country", %{"code" => code}, socket)
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
  # Terminology events
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

  def handle_event("select_glossary_case_sensitive:" <> idx, params, socket) do
    handle_glossary_entry_select(idx, :case_sensitive, params, socket)
  end

  def handle_event("select_glossary_translation_locale:" <> indexes, params, socket) do
    case String.split(indexes, ":", parts: 2) do
      [entry_idx, translation_idx] ->
        handle_glossary_translation_select(entry_idx, translation_idx, :locale, params, socket)

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("select_terminology_revision", params, socket) do
    case noora_select_value(params) do
      nil ->
        {:noreply, socket}

      version ->
        {:noreply, push_patch(socket, to: "/#{socket.assigns.handle}/-/terminology/#{version}")}
    end
  end

  def handle_event("glossary_discard", _params, socket) do
    socket = cancel_summary_generation(socket)

    socket =
      assign(socket,
        glossary_entries: socket.assigns.original_glossary_entries,
        glossary_changed?: false,
        glossary_form_params: %{},
        change_summary: "",
        generating_summary?: false
      )

    if socket.assigns.live_action == :glossary_entry_new do
      {:noreply, push_patch(socket, to: "/#{socket.assigns.handle}/-/terminology")}
    else
      {:noreply, socket}
    end
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

  def handle_event("add_glossary_translation:" <> entry_idx_str, _params, socket) do
    handle_event("add_glossary_translation", %{"entry-index" => entry_idx_str}, socket)
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

  def handle_event("remove_glossary_translation:" <> indexes, _params, socket) do
    case String.split(indexes, ":", parts: 2) do
      [entry_idx, translation_idx] ->
        handle_event(
          "remove_glossary_translation",
          %{"entry-index" => entry_idx, "translation-index" => translation_idx},
          socket
        )

      _ ->
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

  def handle_event("add_filter", %{"value" => filter_id}, socket) do
    updated_params =
      Filter.Operations.add_filter_to_query(filter_id, socket, settings_decoded_query(socket))

    {:noreply,
     socket
     |> push_patch(to: settings_filter_path(socket, updated_params))
     |> push_event("open-dropdown", %{id: "filter-#{filter_id}-value-dropdown"})
     |> push_event("open-popover", %{id: "filter-#{filter_id}-value-popover"})}
  end

  def handle_event("update_filter", params, socket) do
    updated_params =
      Filter.Operations.update_filters_in_query(params, socket, settings_decoded_query(socket))

    {:noreply,
     socket
     |> push_patch(to: settings_filter_path(socket, updated_params))
     |> push_event("close-dropdown", %{id: "all", all: true})
     |> push_event("close-popover", %{id: "all", all: true})}
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

      case Organizations.create_invitation(org, user, params, via: :dashboard) do
        {:ok, _invitation} ->
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
          case Organizations.revoke_invitation(invitation, actor: user, via: :dashboard) do
            {:ok, _} ->
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
              Organizations.remove_member(org, target_user, actor: current_user, via: :dashboard)

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
      user = socket.assigns.current_user

      new_scopes = List.wrap(params["scopes"]) |> Enum.join(" ")

      attrs = %{
        "name" => params["name"],
        "description" => params["description"],
        "scope" => new_scopes
      }

      case AccountTokens.update_account_token(token, attrs, actor: user, via: :dashboard) do
        {:ok, _updated_token} ->
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

      case AccountTokens.create_account_token(account, user, attrs, via: :dashboard) do
        {:ok, %{token: _token, plain_token: plain_token}} ->
          {:ok, {tokens, _meta}} = AccountTokens.list_account_tokens(account)

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

      case AccountTokens.revoke_account_token(token_id, account.id, actor: user, via: :dashboard) do
        {:ok, _token} ->
          {:ok, {tokens, _meta}} = AccountTokens.list_account_tokens(account)

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

      case AccountTokens.create_oauth_application(account, user, params, via: :dashboard) do
        {:ok, %{app: _app, client_id: client_id, client_secret: client_secret}} ->
          {:ok, {apps, _meta}} = AccountTokens.list_oauth_applications(account)

          {:noreply,
           socket
           |> assign(
             oauth_apps: apps,
             newly_created_secret: %{client_id: client_id, client_secret: client_secret}
           )
           |> push_patch(to: "/#{socket.assigns.handle}/-/settings/apps")}

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
      user = socket.assigns.current_user

      case AccountTokens.update_oauth_application(app, params, actor: user, via: :dashboard) do
        {:ok, _updated_app} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Application updated."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/settings/apps/#{app.id}")}

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
      app = AccountTokens.get_oauth_application!(app_id, account.id)

      case AccountTokens.regenerate_oauth_application_secret(app, actor: user, via: :dashboard) do
        {:ok, %{client_secret: secret}} ->
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
      app = AccountTokens.get_oauth_application!(app_id, account.id)

      case AccountTokens.delete_oauth_application(app, actor: user, via: :dashboard) do
        :ok ->
          {:ok, {apps, _meta}} = AccountTokens.list_oauth_applications(account)

          {:noreply,
           socket
           |> assign(oauth_apps: apps)
           |> put_flash(:info, gettext("Application deleted."))
           |> push_patch(to: "/#{socket.assigns.handle}/-/settings/apps")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not delete application."))}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Suggestion review events
  # ---------------------------------------------------------------------------

  def handle_event("add_discussion_comment", %{"comment" => params}, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user
    account = socket.assigns.account

    cond do
      is_nil(user) or not Glossia.Policy.authorize?(:discussion_write, user, account) ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}

      true ->
        case Discussions.add_comment(ticket, user, params, via: :dashboard) do
          {:ok, _comment} ->
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
      case Discussions.close_discussion(ticket, user, via: :dashboard) do
        {:ok, updated_ticket} ->
          ticket = Discussions.get_discussion_by_number!(updated_ticket.number, account.id)
          {:noreply, assign(socket, ticket: ticket)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not close suggestion."))}
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
      case Discussions.reopen_discussion(ticket, user, via: :dashboard) do
        {:ok, updated_ticket} ->
          ticket = Discussions.get_discussion_by_number!(updated_ticket.number, account.id)
          {:noreply, assign(socket, ticket: ticket)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not reopen suggestion."))}
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
        {:noreply, put_flash(socket, :error, gettext("This item is not a suggestion."))}

      {:error, :invalid_payload} ->
        {:noreply, put_flash(socket, :error, gettext("Invalid suggestion payload."))}
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
    {:reply, %{html: render_markdown(source)}, socket}
  end

  def handle_event("disconnect_github", _params, socket) do
    installation = socket.assigns.github_installation

    case Glossia.Github.Installations.delete_installation(installation,
           actor: socket.assigns.current_user,
           via: :dashboard
         ) do
      {:ok, _} ->
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
      "development" => params["development"] == "true",
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
    with {:ok, repo} <- selected_wizard_repo(socket),
         {:ok, languages} <- selected_wizard_languages(socket) do
      account = socket.assigns.account
      user = socket.assigns.current_user
      installations = socket.assigns[:github_installations] || []
      installation = matching_repo_installation(repo, installations)
      installation_id = if installation, do: installation.id, else: nil

      attrs = %{
        handle: repository_project_handle(repo),
        name: repo["name"] || repo["full_name"],
        github_repo_id: repo["id"],
        github_repo_full_name: repo["full_name"],
        github_repo_default_branch: repo["default_branch"],
        setup_status: "pending",
        setup_target_languages: languages
      }

      result =
        if installation_id do
          Glossia.Projects.create_project_from_github(account, installation_id, attrs,
            actor: user,
            via: :dashboard
          )
        else
          Glossia.Projects.create_project(account, attrs, actor: user, via: :dashboard)
        end

      case result do
        {:ok, project} ->
          socket = subscribe_to_setup_events(socket, project)

          case %{project_id: project.id}
               |> Glossia.Projects.SetupWorker.new()
               |> Oban.insert() do
            {:ok, _job} ->
              {:noreply,
               socket
               |> assign(wizard_project: project)
               |> push_patch(to: "/#{socket.assigns.handle}/-/projects/new?step=setup")}

            {:error, reason} ->
              error = gettext("Project setup could not be queued.")
              _ = Glossia.Projects.discard_pending_project_setup(project)
              Logger.warning("Failed to enqueue project setup", reason: inspect(reason))

              {:noreply,
               socket
               |> put_flash(:error, error)}
          end

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
    else
      {:error, :repo_required} ->
        {:noreply, put_flash(socket, :error, gettext("Select a repository first."))}

      {:error, :languages_required} ->
        {:noreply, put_flash(socket, :error, gettext("Select at least one target language."))}
    end
  end

  def handle_event("retry_setup", _params, socket) do
    project = socket.assigns[:project] || socket.assigns[:wizard_project]

    if socket.assigns.can_write and project do
      case Glossia.Projects.retry_project_setup(project) do
        {:ok, pending_project} ->
          case Glossia.Projects.SetupWorker.retry_now(pending_project.id) do
            {:ok, _job} ->
              socket =
                socket
                |> subscribe_to_setup_events(pending_project)
                |> then(fn socket ->
                  if socket.assigns[:project] do
                    assign(socket, project: pending_project)
                  else
                    assign(socket, wizard_project: pending_project)
                  end
                end)

              {:noreply, socket}

            _error ->
              _ = Glossia.Projects.discard_pending_project_setup(pending_project)

              socket =
                socket
                |> put_flash(:error, gettext("Could not retry project setup."))

              if socket.assigns[:project] do
                {:noreply, push_navigate(socket, to: "/#{socket.assigns.handle}")}
              else
                {:noreply,
                 socket
                 |> assign(wizard_project: nil, setup_events: [])
                 |> push_patch(to: "/#{socket.assigns.handle}/-/projects/new?step=languages")}
              end
          end

        _error ->
          {:noreply, put_flash(socket, :error, gettext("Could not retry project setup."))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("You cannot retry this project setup."))}
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

      case Glossia.Projects.update_project(project, attrs, actor: user, via: :dashboard) do
        {:ok, updated_project} ->
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

  def handle_event("cancel_translation_session", _params, socket) do
    require_write!(socket)

    case Glossia.TranslationSessions.cancel_session(socket.assigns.session) do
      {:ok, session} ->
        {:noreply,
         socket
         |> assign(session: session)
         |> put_flash(:info, gettext("Translation cancelled."))}

      {:error, :not_cancellable} ->
        {:noreply,
         put_flash(socket, :error, gettext("This translation can no longer be cancelled."))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Could not cancel the translation."))}
    end
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
        "target_languages" => translation_target_languages(project)
      })

    %{session_id: session.id}
    |> Glossia.TranslationSessions.TranslateWorker.new()
    |> Oban.insert()

    handle = socket.assigns.handle

    {:noreply,
     push_navigate(socket,
       to: "/" <> handle <> "/" <> project.handle <> "/-/sessions/" <> session.id
     )}
  end

  defp put_model_form_value(form, value) do
    form.params
    |> Map.new(fn {key, field_value} -> {to_string(key), field_value} end)
    |> Map.put("model", value)
  end

  defp model_form_changeset(params) do
    %Glossia.Accounts.LLMModel{}
    |> LLMModels.change_model(params)
    |> Map.put(:action, :validate)
  end

  defp model_edit_form_changeset(model, params) do
    model
    |> LLMModels.change_model(params, require_api_key: false)
    |> Map.put(:action, :validate)
  end

  defp model_field_error(field) do
    case List.first(field.errors) do
      nil -> nil
      error -> translate_error(error)
    end
  end

  defp changed_model_form?(params, original) do
    String.trim(params["handle"] || "") != String.trim(original["handle"] || "") or
      String.trim(params["model"] || "") != String.trim(original["model"] || "") or
      String.trim(params["api_key"] || "") != ""
  end

  # A project's configured locales, falling back to a default so triggering a
  # translation never silently produces an empty locale list (and thus no PR).
  defp translation_target_languages(project) do
    case project.setup_target_languages do
      languages when is_list(languages) and languages != [] -> languages
      _ -> ["es", "fr"]
    end
  end

  defp selected_wizard_repo(socket) do
    case socket.assigns[:wizard_selected_repo] do
      %{"full_name" => full_name} = repo when is_binary(full_name) and full_name != "" ->
        {:ok, repo}

      _ ->
        {:error, :repo_required}
    end
  end

  defp selected_wizard_languages(socket) do
    supported_codes = MapSet.new(Enum.map(@wizard_languages, & &1.code))

    languages =
      socket.assigns[:wizard_selected_languages]
      |> List.wrap()
      |> Enum.filter(&MapSet.member?(supported_codes, &1))
      |> Enum.uniq()

    if languages == [] do
      {:error, :languages_required}
    else
      {:ok, languages}
    end
  end

  defp matching_repo_installation(repo, installations) do
    if repo["development"] do
      nil
    else
      repo_owner_login = get_in(repo, ["owner", "login"])

      Enum.find(installations, fn installation ->
        installation.github_account_login == repo_owner_login
      end)
    end
  end

  defp repository_project_handle(repo) do
    repo_name =
      repo["name"] ||
        (repo["full_name"] && repo["full_name"] |> String.split("/") |> List.last()) ||
        "repository"

    handle =
      repo_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9-]/, "-")
      |> String.trim("-")

    cond do
      String.length(handle) >= 2 ->
        handle

      repo["id"] ->
        "repo-#{repo["id"]}"

      true ->
        "repository"
    end
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

      _description =
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

                      _country_name = country_name
                      # TODO: re-implement with account LLM model system
                      {code, ""}
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

      context_label = if context == :voice, do: "voice configuration", else: "terminology"

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
    if Glossia.TranslationSessions.Progress.progress_event?(event) do
      progress =
        socket.assigns[:translation_progress]
        |> Kernel.||(Glossia.TranslationSessions.Progress.new())
        |> Glossia.TranslationSessions.Progress.apply_event(event)

      {:noreply, assign_translation_progress(socket, progress)}
    else
      session_events = socket.assigns[:session_events] || []
      {:noreply, assign(socket, session_events: session_events ++ [event])}
    end
  end

  def handle_info({:translation_session_status, status}, socket) do
    session = socket.assigns[:session]

    socket =
      if session do
        assign(socket, session: refetch_translation_session(session, status))
      else
        socket
      end

    socket =
      if status == "running" do
        assign_translation_progress(socket, Glossia.TranslationSessions.Progress.new())
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({:translation_session_publication, session}, socket) do
    {:noreply, assign(socket, session: session)}
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

          socket = assign(socket, wizard_project: updated)

          if status == "completed" do
            push_navigate(socket, to: "/#{socket.assigns.handle}/#{updated.handle}")
          else
            socket
          end

        true ->
          socket
      end

    {:noreply, socket}
  end

  def handle_info({:setup_pull_request, updated_project}, socket) do
    project = socket.assigns[:project]

    if project && project.id == updated_project.id do
      {:noreply,
       assign(socket,
         project: updated_project,
         sidebar_project: updated_project
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:setup_failed, project_id, error}, socket) do
    project = socket.assigns[:project]
    wizard_project = socket.assigns[:wizard_project]

    message =
      gettext("Project setup failed, so the project was not created. %{reason}", reason: error)

    cond do
      wizard_project && to_string(wizard_project.id) == to_string(project_id) ->
        {:noreply,
         socket
         |> assign(wizard_project: nil, setup_events: [])
         |> put_flash(:error, message)
         |> push_patch(to: "/#{socket.assigns.handle}/-/projects/new?step=languages")}

      project && to_string(project.id) == to_string(project_id) ->
        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_navigate(to: "/#{socket.assigns.handle}")}

      true ->
        {:noreply, socket}
    end
  end

  defp assign_translation_progress(socket, progress) do
    items =
      progress
      |> Progress.items()
      |> Enum.map(fn item ->
        failure =
          if item.status == :failed,
            do: translation_failure(item.reason, item.index),
            else: nil

        item
        |> Map.put(:failure, failure)
        |> Map.put(
          :file_url,
          translation_file_url(
            socket.assigns[:project],
            item.status,
            item.file_ref,
            item.output_path
          )
        )
      end)

    assign(socket,
      translation_progress: progress,
      translation_progress_items: items,
      translation_progress_summary: Progress.summary(progress),
      translation_progress_failures: translation_failure_groups(items)
    )
  end

  defp refetch_project(project, status) do
    case Glossia.Repo.get(Glossia.Accounts.Project, project.id) do
      nil -> %{project | setup_status: status}
      fresh -> fresh
    end
  end

  defp refetch_translation_session(session, status) do
    case Glossia.Repo.get(Glossia.TranslationSessions.TranslationSession, session.id) do
      nil -> %{session | status: status}
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
      <% action when action in [:glossary_entry, :glossary_entry_new] -> %>
        <.terminology_entry_page
          glossary={@glossary}
          glossary_entries={@glossary_entries}
          original_glossary_entries={@original_glossary_entries}
          terminology_entry_index={@terminology_entry_index}
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
          new_term?={action == :glossary_entry_new}
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
          tokens_search={assigns[:tokens_search] || ""}
          available_filters={assigns[:available_filters] || []}
          active_filters={assigns[:active_filters] || []}
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
          apps_search={assigns[:apps_search] || ""}
          apps_sort_key={assigns[:apps_sort_key] || "inserted_at"}
          apps_sort_dir={assigns[:apps_sort_dir] || "desc"}
          available_filters={assigns[:available_filters] || []}
          active_filters={assigns[:active_filters] || []}
        />
      <% action when action in [:llm_models, :llm_model_new, :llm_model_edit] -> %>
        <.llm_models_page
          live_action={@live_action}
          handle={@handle}
          llm_models={assigns[:llm_models] || []}
          model_form={assigns[:model_form]}
          model_form_valid?={assigns[:model_form_valid?] || false}
          models_search={assigns[:models_search] || ""}
          models_sort_key={assigns[:models_sort_key] || "handle"}
          models_sort_dir={assigns[:models_sort_dir] || "asc"}
          editing_model={assigns[:editing_model]}
          model_edit_form={assigns[:model_edit_form]}
          model_edit_changed?={assigns[:model_edit_changed?] || false}
          model_picker_options_json={assigns[:model_picker_options_json] || "[]"}
          model_picker_option_count={assigns[:model_picker_option_count] || 0}
          model_picker_selected_label={assigns[:model_picker_selected_label]}
          available_filters={assigns[:available_filters] || []}
          active_filters={assigns[:active_filters] || []}
        />
      <% :discussion_show -> %>
        <.ticket_show_page
          handle={@handle}
          ticket={assigns[:ticket]}
          comment_form={assigns[:comment_form]}
          current_user={@current_user}
          can_write={@can_write}
          can_voice_write={assigns[:can_voice_write] || false}
          can_glossary_write={assigns[:can_glossary_write] || false}
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
          translations_active_filters={assigns[:translations_active_filters] || []}
          available_filters={assigns[:available_filters] || []}
          active_filters={assigns[:active_filters] || []}
        />
      <% :project_session -> %>
        <.session_detail_page
          handle={@handle}
          project={@project}
          session={@session}
          session_events={assigns[:session_events] || []}
          translation_progress_items={assigns[:translation_progress_items] || []}
          translation_progress_summary={
            assigns[:translation_progress_summary] ||
              Glossia.TranslationSessions.Progress.summary(Glossia.TranslationSessions.Progress.new())
          }
          translation_progress_failures={assigns[:translation_progress_failures] || []}
        />
      <% :project -> %>
        <.project_page
          handle={@handle}
          account={@account}
          project={assigns[:project]}
          project_name={@project_name}
          setup_events={assigns[:setup_events] || []}
          commits={assigns[:commits] || []}
          sessions_by_sha={assigns[:sessions_by_sha] || %{}}
          commits_error={assigns[:commits_error]}
          commits_search={assigns[:commits_search] || ""}
          commits_sort_key={assigns[:commits_sort_key] || "date"}
          commits_sort_dir={assigns[:commits_sort_dir] || "desc"}
          can_write={@can_write}
        />
    <% end %>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Account (projects list)
  # ---------------------------------------------------------------------------

  defp account_page(assigns) do
    ~H"""
    <div class="dash-page noora-projects-page">
      <div class="noora-page-header">
        <div data-part="copy">
          <h1 data-part="page-title">{gettext("Organization")}</h1>
          <p data-part="page-subtitle">{gettext("Projects connected to this organization.")}</p>
        </div>
        <div :if={@can_write} data-part="actions">
          <Noora.Button.button
            patch={"/" <> @handle <> "/-/projects/new"}
            label={gettext("New project")}
            size="large"
          >
            <:icon_left><Noora.Icon.plus /></:icon_left>
          </Noora.Button.button>
        </div>
      </div>

      <div class="noora-projects-toolbar">
        <.form for={%{}} phx-change="resource_search">
          <input type="hidden" name="table_id" value="projects-table" />
          <Noora.TextInput.text_input
            id="projects-search"
            name="search"
            type="search"
            value={@projects_search}
            placeholder={gettext("Search projects...")}
            show_suffix={false}
            phx-debounce="300"
          />
        </.form>
      </div>

      <Noora.Table.table
        id="projects-table"
        rows={@projects}
        row_key={fn project -> "project-#{project.id}" end}
        row_navigate={fn project -> "/" <> @handle <> "/" <> project.handle end}
      >
        <:col
          :let={project}
          label={gettext("Name")}
          patch={
            projects_sort_patch(
              @handle,
              @projects_search,
              @projects_sort_key,
              @projects_sort_dir,
              @projects_page,
              "name"
            )
          }
          sort_order={if(@projects_sort_key == "name", do: @projects_sort_dir)}
        >
          <Noora.Table.text_and_description_cell
            icon="folder"
            label={project.name}
            description={project_description(project)}
          />
        </:col>
        <:col
          :let={project}
          label={gettext("Handle")}
          patch={
            projects_sort_patch(
              @handle,
              @projects_search,
              @projects_sort_key,
              @projects_sort_dir,
              @projects_page,
              "handle"
            )
          }
          sort_order={if(@projects_sort_key == "handle", do: @projects_sort_dir)}
        >
          <Noora.Table.tag_cell label={project.handle} />
        </:col>
        <:col :let={project} label={gettext("Repository")}>
          <%= if project.github_repo_full_name do %>
            <Noora.Table.text_cell icon="git_branch" label={project.github_repo_full_name} />
          <% else %>
            <Noora.Table.text_cell label={gettext("Not connected")} />
          <% end %>
        </:col>
        <:col
          :let={project}
          label={gettext("Created")}
          patch={
            projects_sort_patch(
              @handle,
              @projects_search,
              @projects_sort_key,
              @projects_sort_dir,
              @projects_page,
              "inserted_at"
            )
          }
          sort_order={if(@projects_sort_key == "inserted_at", do: @projects_sort_dir)}
        >
          <Noora.Table.time_cell time={project.inserted_at} />
        </:col>

        <:empty_state>
          <Noora.Table.table_empty_state>
            <.noora_empty_state
              icon="folder"
              title={gettext("No projects yet")}
              subtitle={gettext("Projects will show up here once you create one.")}
            />
          </Noora.Table.table_empty_state>
        </:empty_state>
      </Noora.Table.table>
    </div>
    """
  end

  defp projects_sort_patch(handle, search, current_sort_key, current_sort_dir, page, sort_key) do
    sort_dir =
      if current_sort_key == sort_key and current_sort_dir == "asc",
        do: "desc",
        else: "asc"

    projects_table_patch(handle, search, sort_key, sort_dir, page)
  end

  defp projects_table_patch(handle, search, sort_key, sort_dir, page) do
    query_params =
      []
      |> maybe_add_param("pq", search, "")
      |> maybe_add_param("psort", sort_key, default_sort_key("projects-table"))
      |> maybe_add_param("pdir", sort_dir, default_sort_dir("projects-table"))
      |> maybe_add_param("ppage", page, 1)

    path = "/" <> handle

    if query_params == [] do
      path
    else
      path <> "?" <> URI.encode_query(query_params)
    end
  end

  defp project_description(project) do
    cond do
      present?(project.description) -> project.description
      present?(project.github_repo_full_name) -> project.github_repo_full_name
      true -> project.handle
    end
  end

  defp project_setup_status("completed"), do: "success"
  defp project_setup_status("failed"), do: "error"
  defp project_setup_status("running"), do: "in_progress"
  defp project_setup_status("pending"), do: "attention"
  defp project_setup_status(_), do: "disabled"

  defp project_setup_status_label("completed"), do: gettext("Completed")
  defp project_setup_status_label("failed"), do: gettext("Failed")
  defp project_setup_status_label("running"), do: gettext("Running")
  defp project_setup_status_label("pending"), do: gettext("Pending")
  defp project_setup_status_label(_), do: gettext("Not started")

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value), do: not is_nil(value)

  # ---------------------------------------------------------------------------
  # Page: Logs
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Page: Voice form
  # ---------------------------------------------------------------------------

  defp voice_page(assigns) do
    assigns =
      assigns
      |> assign_new(:suggestion_mode?, fn -> false end)
      |> Map.put(:tone_options, @tone_options)
      |> Map.put(:formality_options, @formality_options)

    ~H"""
    <div class="dash-page noora-voice-page">
      <div class="noora-page-header">
        <div data-part="copy">
          <h1 data-part="page-title">
            {if @suggestion_mode?, do: gettext("Suggest voice changes"), else: gettext("Voice")}
          </h1>
          <p data-part="page-subtitle">
            <%= if @suggestion_mode? do %>
              {gettext("Create a suggestion with title, description, and proposed voice updates.")}
            <% else %>
              {gettext("Define the tone, formality, and style guidelines for your content.")}
            <% end %>
          </p>
        </div>
      </div>

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
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <Noora.TextInput.text_input
                  id="voice_suggestion_title"
                  name="suggestion_title"
                  value={@voice_form_params["suggestion_title"] || ""}
                  label={gettext("Title")}
                  placeholder={gettext("Short summary of the suggested change")}
                  required
                  show_required
                />
                <div class="voice-field">
                  <Noora.TextArea.text_area
                    id="voice-suggestion-body-editor"
                    name="suggestion_body"
                    value={@voice_form_params["suggestion_body"] || ""}
                    label={gettext("Description")}
                    placeholder={gettext("Explain what should change and why...")}
                    rows={8}
                    max_length={10_000}
                    show_character_count={false}
                    required
                    show_required
                    phx-debounce="300"
                  />
                </div>
              </div>
            </Noora.Card.card_section>
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
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "description") &&
                    "voice-field-changed"
                ]}>
                  <Noora.TextArea.text_area
                    id="voice_description"
                    name="description"
                    label={gettext("Description")}
                    value={voice_current_value(@voice_form_params, @voice, "description")}
                    rows={3}
                    max_length={2_000}
                    show_character_count={false}
                    placeholder={gettext("Briefly describe what you do and who you serve...")}
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                    hint={gettext("Used to generate cultural notes for target countries.")}
                  />
                </div>
              </div>
            </Noora.Card.card_section>
          </div>

          <div class="voice-section-divider"></div>

          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Target countries")}</h2>
              <p>{gettext("Choose markets and tune the cultural context Glossia should use.")}</p>
            </div>
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_target_countries_changed?(@target_countries, @original_voice) &&
                    "voice-field-changed"
                ]}>
                  <Noora.Label.label label={gettext("Target countries")} />
                  <%= if @target_countries != [] do %>
                    <div class="voice-country-tags" id="voice-country-tags">
                      <%= for code <- @target_countries do %>
                        <Noora.Tag.tag
                          label={"#{country_flag(code)} #{code}"}
                          dismissible={@can_voice_submit?}
                          on_dismiss="remove_country"
                          dismiss_value={code}
                          aria-label={country_name(code)}
                        />
                      <% end %>
                    </div>
                  <% end %>
                  <%= if @can_voice_submit? do %>
                    <Noora.Select.select
                      id="voice-country-select"
                      name="country"
                      label={gettext("Search country...")}
                      value=""
                      on_value_change="select_voice_country"
                    >
                      <:item
                        :for={{code, {flag, name}} <- country_options(@target_countries)}
                        value={code}
                        label={"#{flag} #{code} - #{name}"}
                        icon="world"
                      />
                    </Noora.Select.select>
                  <% end %>
                </div>
                <%= if @target_countries != [] do %>
                  <div class={[
                    "voice-field",
                    voice_cultural_notes_changed?(@cultural_notes, @original_voice) &&
                      "voice-field-changed"
                  ]}>
                    <Noora.Label.label label={gettext("Cultural notes")} />
                    <Noora.HintText.hint_text label={
                      if @generating_contexts? do
                        gettext("Generating cultural notes...")
                      else
                        gettext("AI-generated cultural notes per country. You can edit them.")
                      end
                    } />
                    <%= for code <- @target_countries do %>
                      <div
                        class={[
                          "voice-country-context",
                          voice_country_note_changed?(code, @cultural_notes, @original_voice) &&
                            "voice-country-context-changed"
                        ]}
                        id={"country-context-#{code}"}
                      >
                        <Noora.Label.label
                          class="voice-country-context-label"
                          label={"#{country_flag(code)} #{country_name(code)}"}
                        />
                        <Noora.TextArea.text_area
                          name={"cultural_notes[#{code}]"}
                          value={Map.get(@cultural_notes, code, "")}
                          rows={3}
                          max_length={2_000}
                          show_character_count={false}
                          placeholder={
                            gettext("Cultural notes for %{country}...", country: country_name(code))
                          }
                          disabled={!@can_voice_submit?}
                          phx-debounce="300"
                        />
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </Noora.Card.card_section>
          </div>

          <div class="voice-section-divider"></div>

          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Tone and style")}</h2>
              <p>{gettext("Set the overall personality and formality level for your content.")}</p>
            </div>
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "tone") &&
                    "voice-field-changed"
                ]}>
                  <Noora.Label.label label={gettext("Tone")} />
                  <Noora.Select.select
                    id="voice_tone"
                    name="tone"
                    value={voice_current_value(@voice_form_params, @voice, "tone")}
                    label={gettext("Select a tone")}
                    disabled={!@can_voice_submit?}
                    hint={gettext("The general character of your writing.")}
                    on_value_change="select_voice_tone"
                  >
                    <:item
                      :for={opt <- @tone_options}
                      value={opt}
                      label={opt |> String.capitalize()}
                      icon="volume_3"
                    />
                  </Noora.Select.select>
                </div>
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "formality") &&
                    "voice-field-changed"
                ]}>
                  <Noora.Label.label label={gettext("Formality")} />
                  <Noora.Select.select
                    id="voice_formality"
                    name="formality"
                    value={voice_current_value(@voice_form_params, @voice, "formality")}
                    label={gettext("Select a level")}
                    disabled={!@can_voice_submit?}
                    hint={gettext("How casual or formal the language should be.")}
                    on_value_change="select_voice_formality"
                  >
                    <:item
                      :for={opt <- @formality_options}
                      value={opt}
                      label={opt |> String.replace("_", " ") |> String.capitalize()}
                      icon="settings"
                    />
                  </Noora.Select.select>
                </div>
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "target_audience") &&
                    "voice-field-changed"
                ]}>
                  <Noora.TextInput.text_input
                    id="voice_target_audience"
                    name="target_audience"
                    label={gettext("Target audience")}
                    value={voice_current_value(@voice_form_params, @voice, "target_audience")}
                    placeholder={gettext("e.g. Developers, marketing teams, general public")}
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                    hint={gettext("Who you are writing for.")}
                  />
                </div>
              </div>
            </Noora.Card.card_section>
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
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <div class={[
                  "voice-field",
                  voice_field_changed?(@voice_form_params, @original_voice, "guidelines") &&
                    "voice-field-changed"
                ]}>
                  <Noora.TextArea.text_area
                    id="voice_guidelines"
                    name="guidelines"
                    label={gettext("Writing guidelines")}
                    value={voice_current_value(@voice_form_params, @voice, "guidelines")}
                    rows={10}
                    max_length={8_000}
                    show_character_count={false}
                    placeholder={gettext("Write your brand voice guidelines here...")}
                    disabled={!@can_voice_submit?}
                    phx-debounce="300"
                  />
                </div>
              </div>
            </Noora.Card.card_section>
          </div>

          <div class="voice-section-divider"></div>

          <div class="voice-section" id="voice-overrides">
            <div class="voice-section-info voice-section-info-with-action">
              <div data-part="copy">
                <h2>{gettext("Language overrides")}</h2>
                <p>
                  {gettext(
                    "Customize the voice for specific languages. Fields left empty will fall back to the base voice above."
                  )}
                </p>
              </div>
              <%= if @can_voice_submit? do %>
                <div data-part="actions">
                  <Noora.Button.button
                    type="button"
                    label={gettext("Add language override")}
                    variant="secondary"
                    size="medium"
                    phx-click="add_override"
                  >
                    <:icon_left><Noora.Icon.plus /></:icon_left>
                  </Noora.Button.button>
                </div>
              <% end %>
            </div>
            <div class="voice-overrides-list" id="override-list">
              <%= for {override, idx} <- Enum.with_index(@overrides) do %>
                <% override_changed? = voice_override_changed?(override, @original_overrides) %>
                <% override_locale = voice_override_value(override, :locale) %>
                <Noora.Card.card_section
                  class="voice-override-panel"
                  data-override-index={idx}
                  data-changed={override_changed?}
                >
                  <div data-part="header">
                    <div data-part="title-group">
                      <span data-part="title">
                        {if override_locale != "", do: override_locale, else: gettext("New override")}
                      </span>
                      <Noora.Badge.badge
                        :if={override_changed?}
                        label={gettext("Changed")}
                        color="primary"
                        style="light-fill"
                      />
                    </div>
                    <%= if @can_voice_submit? do %>
                      <div data-part="actions">
                        <Noora.Button.button
                          type="button"
                          label={gettext("Remove")}
                          variant="secondary"
                          size="small"
                          phx-click="remove_override"
                          phx-value-index={idx}
                        />
                      </div>
                    <% end %>
                  </div>
                  <div data-part="content">
                    <div class="voice-override-fields">
                      <div class="voice-field">
                        <Noora.Label.label label={gettext("Language")} />
                        <Noora.Select.select
                          id={"voice-override-locale-#{idx}"}
                          name={"overrides[#{idx}][locale]"}
                          value={voice_override_value(override, :locale)}
                          label={gettext("Select a language")}
                          disabled={!@can_voice_submit?}
                          on_value_change={"select_voice_override_locale:#{idx}"}
                        >
                          <:item
                            :for={{code, name} <- locale_options()}
                            value={code}
                            label={"#{code} - #{name}"}
                            icon="language"
                          />
                        </Noora.Select.select>
                      </div>
                      <div class="voice-field-row">
                        <div class="voice-field">
                          <Noora.Label.label label={gettext("Tone")} />
                          <Noora.Select.select
                            id={"voice-override-tone-#{idx}"}
                            name={"overrides[#{idx}][tone]"}
                            value={voice_override_select_value(override, :tone)}
                            label={gettext("Use base")}
                            disabled={!@can_voice_submit?}
                            on_value_change={"select_voice_override_tone:#{idx}"}
                          >
                            <:item value="__base__" label={gettext("Use base")} icon="volume_3" />
                            <:item
                              :for={opt <- @tone_options}
                              value={opt}
                              label={opt |> String.capitalize()}
                              icon="volume_3"
                            />
                          </Noora.Select.select>
                        </div>
                        <div class="voice-field">
                          <Noora.Label.label label={gettext("Formality")} />
                          <Noora.Select.select
                            id={"voice-override-formality-#{idx}"}
                            name={"overrides[#{idx}][formality]"}
                            value={voice_override_select_value(override, :formality)}
                            label={gettext("Use base")}
                            disabled={!@can_voice_submit?}
                            on_value_change={"select_voice_override_formality:#{idx}"}
                          >
                            <:item value="__base__" label={gettext("Use base")} icon="settings" />
                            <:item
                              :for={opt <- @formality_options}
                              value={opt}
                              label={opt |> String.replace("_", " ") |> String.capitalize()}
                              icon="settings"
                            />
                          </Noora.Select.select>
                        </div>
                      </div>
                      <div class="voice-field">
                        <Noora.TextInput.text_input
                          id={"voice-override-target-audience-#{idx}"}
                          name={"overrides[#{idx}][target_audience]"}
                          label={gettext("Target audience")}
                          value={voice_override_value(override, :target_audience)}
                          disabled={!@can_voice_submit?}
                          phx-debounce="300"
                        />
                      </div>
                      <div class="voice-field">
                        <Noora.TextArea.text_area
                          id={"voice-override-guidelines-#{idx}"}
                          name={"overrides[#{idx}][guidelines]"}
                          label={gettext("Guidelines")}
                          value={voice_override_value(override, :guidelines)}
                          rows={4}
                          max_length={8_000}
                          show_character_count={false}
                          disabled={!@can_voice_submit?}
                          phx-debounce="300"
                        />
                      </div>
                    </div>
                  </div>
                </Noora.Card.card_section>
              <% end %>
            </div>
          </div>

          <%= if @versions != [] do %>
            <div class="voice-section-divider"></div>

            <Noora.Card.card_section class="noora-resource-table-card">
              <div data-part="header">
                <div data-part="title-group">
                  <h2>{gettext("Version history")}</h2>
                  <p>{gettext("Previous versions of your voice configuration.")}</p>
                </div>
              </div>
              <Noora.Table.table
                id="voice-versions"
                rows={@versions}
                row_key={fn version -> "voice-version-#{version.id}" end}
                row_navigate={
                  fn version -> "/" <> @handle <> "/-/voice/" <> to_string(version.version) end
                }
              >
                <:col :let={version} label={gettext("Version")}>
                  <Noora.Table.text_cell label={"##{version.version}"} />
                </:col>
                <:col :let={version} label={gettext("Date")}>
                  <Noora.Table.time_cell time={version.inserted_at} show_time />
                </:col>
                <:col :let={version} label={gettext("By")}>
                  <%= if version.created_by do %>
                    <Noora.Table.text_and_description_cell
                      label={
                        (version.created_by.account && version.created_by.account.handle) ||
                          version.created_by.email
                      }
                      description={version.created_by.email}
                    >
                      <:image>
                        <Noora.Avatar.avatar
                          id={"voice-version-#{version.id}-author"}
                          name={
                            (version.created_by.account && version.created_by.account.handle) ||
                              version.created_by.email
                          }
                          image_href={gravatar_url(version.created_by.email)}
                          size="small"
                        />
                      </:image>
                    </Noora.Table.text_and_description_cell>
                  <% else %>
                    <Noora.Table.text_cell label="-" />
                  <% end %>
                </:col>
              </Noora.Table.table>
            </Noora.Card.card_section>
          <% end %>

          <%= if @voice_suggestions != [] do %>
            <div class="voice-section-divider"></div>

            <Noora.Card.card_section class="noora-resource-table-card">
              <div data-part="header">
                <div data-part="title-group">
                  <h2>{gettext("Open suggestions")}</h2>
                  <p>{gettext("Pending voice proposals from contributors.")}</p>
                </div>
              </div>
              <Noora.Table.table
                id="voice-suggestions"
                rows={@voice_suggestions}
                row_key={fn ticket -> "voice-suggestion-#{ticket.id}" end}
                row_navigate={
                  fn ticket ->
                    suggestion_path(@handle, ticket)
                  end
                }
              >
                <:col :let={ticket} label={gettext("Suggestion")}>
                  <Noora.Table.text_cell label={"##{ticket.number}"} />
                </:col>
                <:col :let={ticket} label={gettext("Title")}>
                  <Noora.Table.text_cell label={ticket.title} />
                </:col>
                <:col :let={ticket} label={gettext("By")}>
                  <%= if ticket.user do %>
                    <Noora.Table.text_and_description_cell
                      label={(ticket.user.account && ticket.user.account.handle) || ticket.user.email}
                      description={ticket.user.email}
                    >
                      <:image>
                        <Noora.Avatar.avatar
                          id={"voice-suggestion-#{ticket.id}-author"}
                          name={
                            (ticket.user.account && ticket.user.account.handle) || ticket.user.email
                          }
                          image_href={gravatar_url(ticket.user.email)}
                          size="small"
                        />
                      </:image>
                    </Noora.Table.text_and_description_cell>
                  <% else %>
                    <Noora.Table.text_cell label="-" />
                  <% end %>
                </:col>
                <:col :let={ticket} label={gettext("Date")}>
                  <Noora.Table.time_cell time={ticket.inserted_at} show_time />
                </:col>
              </Noora.Table.table>
            </Noora.Card.card_section>
          <% end %>
        <% end %>

        <%= if @suggestion_mode? do %>
          <div class="ticket-form-actions">
            <Noora.Button.button
              patch={@voice_back_path || "/" <> @handle <> "/-/voice"}
              label={gettext("Cancel")}
              variant="secondary"
            >
            </Noora.Button.button>
            <Noora.Button.button label={gettext("Submit suggestion")} />
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
  # Page: Terminology
  # ---------------------------------------------------------------------------

  defp glossary_page(assigns) do
    assigns = assign_new(assigns, :suggestion_mode?, fn -> false end)

    ~H"""
    <div class="dash-page noora-terminology-page">
      <div class="noora-page-header">
        <div data-part="copy">
          <h1 data-part="page-title">
            {if @suggestion_mode?,
              do: gettext("Suggest terminology changes"),
              else: gettext("Terminology")}
          </h1>
          <p data-part="page-subtitle">
            <%= if @suggestion_mode? do %>
              {gettext(
                "Create a suggestion with title, description, and proposed terminology updates."
              )}
            <% else %>
              {gettext("Approved terms and translations to keep your content consistent.")}
            <% end %>
          </p>
        </div>
        <div :if={not @suggestion_mode?} data-part="actions" class="terminology-revision-actions">
          <Noora.Button.button
            :if={@can_glossary_submit?}
            patch={"/" <> @handle <> "/-/terminology/terms/new"}
            label={gettext("Add term")}
            variant="secondary"
            size="medium"
          >
            <:icon_left><Noora.Icon.plus /></:icon_left>
          </Noora.Button.button>
          <Noora.Select.select
            :if={@glossary && @glossary_versions != []}
            id="terminology-revision-select"
            name="terminology_version"
            value={to_string(@glossary.version)}
            label={gettext("Revision")}
            on_value_change="select_terminology_revision"
          >
            <:item
              :for={version <- @glossary_versions}
              value={to_string(version.version)}
              label={gettext("Revision #%{version}", version: version.version)}
              icon="git_commit"
            />
          </Noora.Select.select>
        </div>
      </div>

      <%= if @suggestion_mode? do %>
        <form
          phx-change="glossary_validate"
          phx-submit="create_glossary_suggestion"
          class="voice-form"
          id="glossary-form"
        >
          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Suggestion details")}</h2>
              <p>
                {gettext("Provide a clear title, full context, and a concise summary of intent.")}
              </p>
            </div>
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <Noora.TextInput.text_input
                  id="glossary_suggestion_title"
                  name="suggestion_title"
                  value={@glossary_form_params["suggestion_title"] || ""}
                  label={gettext("Title")}
                  placeholder={gettext("Short summary of the suggested change")}
                  required
                  show_required
                />
                <div class="voice-field">
                  <Noora.TextArea.text_area
                    id="glossary-suggestion-body-editor"
                    name="suggestion_body"
                    value={@glossary_form_params["suggestion_body"] || ""}
                    label={gettext("Description")}
                    placeholder={gettext("Explain what should change and why...")}
                    rows={8}
                    max_length={10_000}
                    show_character_count={false}
                    required
                    show_required
                    phx-debounce="300"
                  />
                </div>
              </div>
            </Noora.Card.card_section>
          </div>

          <div class="voice-section-divider"></div>

          <.glossary_suggestion_changes
            glossary_entries={@glossary_entries}
            original_glossary_entries={@original_glossary_entries}
          />
          <div class="voice-section-divider"></div>

          <div class="ticket-form-actions">
            <Noora.Button.button
              patch={@glossary_back_path || "/" <> @handle <> "/-/terminology"}
              label={gettext("Cancel")}
              variant="secondary"
            >
            </Noora.Button.button>
            <Noora.Button.button label={gettext("Submit suggestion")} />
          </div>
        </form>
      <% else %>
        <div class="noora-resource-list">
          <Noora.Card.card
            id="glossary-entries"
            class="noora-resource-card"
            title={gettext("Terms")}
            icon="file_text"
          >
            <Noora.Card.card_section class="noora-resource-table-card">
              <p data-part="resource-description">
                {gettext(
                  "Canonical terms and their approved translations. Terms are matched during content processing to keep terminology consistent."
                )}
              </p>

              <Noora.Table.table
                id="terminology-terms"
                rows={terminology_table_rows(@glossary_entries)}
                row_key={fn row -> "terminology-term-#{row.index}" end}
                row_navigate={
                  fn row ->
                    "/" <> @handle <> "/-/terminology/terms/" <> to_string(row.index)
                  end
                }
              >
                <:col :let={row} label={gettext("Term")}>
                  <Noora.Table.text_and_description_cell
                    icon="file_text"
                    label={terminology_term_label(row.entry)}
                    description={glossary_entry_value(row.entry, :definition)}
                  />
                </:col>
                <:col :let={row} label={gettext("Translations")}>
                  <Noora.Table.text_cell label={terminology_translations_summary(row.entry)} />
                </:col>
                <:col :let={row} label={gettext("Matching")}>
                  <Noora.Table.status_badge_cell
                    status={
                      if map_get(row.entry, :case_sensitive, false),
                        do: "attention",
                        else: "disabled"
                    }
                    label={
                      if map_get(row.entry, :case_sensitive, false),
                        do: gettext("Case sensitive"),
                        else: gettext("Case insensitive")
                    }
                  />
                </:col>
                <:empty_state>
                  <Noora.Table.table_empty_state>
                    <.noora_empty_state
                      icon="file_text"
                      title={gettext("No terms yet")}
                      subtitle={gettext("Terms will show up here once you add one.")}
                    />
                  </Noora.Table.table_empty_state>
                </:empty_state>
              </Noora.Table.table>
            </Noora.Card.card_section>
          </Noora.Card.card>

          <%= if @glossary_versions != [] do %>
            <Noora.Card.card
              class="noora-resource-card"
              title={gettext("Version history")}
              icon="history"
            >
              <Noora.Card.card_section class="noora-resource-table-card">
                <Noora.Table.table
                  id="glossary-versions"
                  rows={@glossary_versions}
                  row_key={fn version -> "glossary-version-#{version.id}" end}
                  row_navigate={
                    fn version ->
                      "/" <> @handle <> "/-/terminology/" <> to_string(version.version)
                    end
                  }
                >
                  <:col :let={version} label={gettext("Version")}>
                    <Noora.Table.text_cell label={"##{version.version}"} />
                  </:col>
                  <:col :let={version} label={gettext("Note")}>
                    <Noora.Table.text_cell label={version.change_note || "-"} />
                  </:col>
                  <:col :let={version} label={gettext("Date")}>
                    <Noora.Table.time_cell time={version.inserted_at} show_time />
                  </:col>
                  <:col :let={version} label={gettext("By")}>
                    <%= if version.created_by do %>
                      <Noora.Table.text_and_description_cell
                        label={
                          (version.created_by.account && version.created_by.account.handle) ||
                            version.created_by.email
                        }
                        description={version.created_by.email}
                      >
                        <:image>
                          <Noora.Avatar.avatar
                            id={"glossary-version-#{version.id}-author"}
                            name={
                              (version.created_by.account && version.created_by.account.handle) ||
                                version.created_by.email
                            }
                            image_href={gravatar_url(version.created_by.email)}
                            size="small"
                          />
                        </:image>
                      </Noora.Table.text_and_description_cell>
                    <% else %>
                      <Noora.Table.text_cell label="-" />
                    <% end %>
                  </:col>
                </Noora.Table.table>
              </Noora.Card.card_section>
            </Noora.Card.card>
          <% end %>

          <%= if @glossary_suggestions != [] do %>
            <Noora.Card.card
              class="noora-resource-card"
              title={gettext("Open suggestions")}
              icon="message_circle"
            >
              <Noora.Card.card_section class="noora-resource-table-card">
                <Noora.Table.table
                  id="glossary-suggestions"
                  rows={@glossary_suggestions}
                  row_key={fn ticket -> "glossary-suggestion-#{ticket.id}" end}
                  row_navigate={
                    fn ticket ->
                      suggestion_path(@handle, ticket)
                    end
                  }
                >
                  <:col :let={ticket} label={gettext("Suggestion")}>
                    <Noora.Table.text_cell label={"##{ticket.number}"} />
                  </:col>
                  <:col :let={ticket} label={gettext("Title")}>
                    <Noora.Table.text_cell label={ticket.title} />
                  </:col>
                  <:col :let={ticket} label={gettext("By")}>
                    <%= if ticket.user do %>
                      <Noora.Table.text_and_description_cell
                        label={
                          (ticket.user.account && ticket.user.account.handle) || ticket.user.email
                        }
                        description={ticket.user.email}
                      >
                        <:image>
                          <Noora.Avatar.avatar
                            id={"glossary-suggestion-#{ticket.id}-author"}
                            name={
                              (ticket.user.account && ticket.user.account.handle) || ticket.user.email
                            }
                            image_href={gravatar_url(ticket.user.email)}
                            size="small"
                          />
                        </:image>
                      </Noora.Table.text_and_description_cell>
                    <% else %>
                      <Noora.Table.text_cell label="-" />
                    <% end %>
                  </:col>
                  <:col :let={ticket} label={gettext("Date")}>
                    <Noora.Table.time_cell time={ticket.inserted_at} show_time />
                  </:col>
                </Noora.Table.table>
              </Noora.Card.card_section>
            </Noora.Card.card>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp terminology_entry_page(assigns) do
    entry = Enum.at(assigns.glossary_entries || [], assigns.terminology_entry_index) || %{}

    assigns =
      assigns
      |> assign_new(:new_term?, fn -> false end)
      |> assign(:terminology_entry, entry)

    ~H"""
    <div class="dash-page noora-terminology-page">
      <div class="noora-page-header">
        <div data-part="copy">
          <h1 data-part="page-title">
            {if @new_term?, do: gettext("New term"), else: terminology_term_label(@terminology_entry)}
          </h1>
          <p data-part="page-subtitle">
            {gettext("Edit one terminology term and its approved translations.")}
          </p>
        </div>
        <div data-part="actions">
          <Noora.Button.button
            patch={"/" <> @handle <> "/-/terminology"}
            label={gettext("Back to terms")}
            variant="secondary"
            size="medium"
          />
        </div>
      </div>

      <form
        phx-change="glossary_validate"
        phx-submit="save_glossary"
        class="voice-form terminology-entry-form"
        id="glossary-entry-form"
      >
        <%= for {entry, idx} <- Enum.with_index(@glossary_entries) do %>
          <%= if idx != @terminology_entry_index do %>
            <.terminology_entry_hidden_fields entry={entry} index={idx} />
          <% end %>
        <% end %>

        <div class="voice-section">
          <Noora.Card.card_section class="voice-card terminology-detail-card">
            <div class="voice-card-fields">
              <div class="voice-field-row">
                <div class="voice-field">
                  <Noora.Label.label label={gettext("Term")} required />
                  <Noora.TextInput.text_input
                    id={"glossary-entry-#{@terminology_entry_index}-term"}
                    name={"entries[#{@terminology_entry_index}][term]"}
                    value={glossary_entry_value(@terminology_entry, :term)}
                    placeholder={gettext("Term")}
                    disabled={!@can_glossary_submit?}
                    required
                    aria-label={gettext("Term")}
                    phx-debounce="300"
                  />
                </div>
                <div class="voice-field">
                  <Noora.Label.label label={gettext("Case sensitive")} />
                  <Noora.Select.select
                    id={"glossary-entry-#{@terminology_entry_index}-case-sensitive"}
                    name={"entries[#{@terminology_entry_index}][case_sensitive]"}
                    value={glossary_case_sensitive_value(@terminology_entry)}
                    label={gettext("No")}
                    disabled={!@can_glossary_submit?}
                    on_value_change={"select_glossary_case_sensitive:#{@terminology_entry_index}"}
                  >
                    <:item value="false" label={gettext("No")} icon="settings" />
                    <:item value="true" label={gettext("Yes")} icon="check" />
                  </Noora.Select.select>
                </div>
              </div>

              <div class="voice-field">
                <Noora.TextInput.text_input
                  id={"glossary-entry-#{@terminology_entry_index}-definition"}
                  name={"entries[#{@terminology_entry_index}][definition]"}
                  value={glossary_entry_value(@terminology_entry, :definition)}
                  label={gettext("Definition")}
                  placeholder={gettext("What this term means")}
                  disabled={!@can_glossary_submit?}
                  phx-debounce="300"
                />
              </div>

              <div class="terminology-translations-section">
                <div class="terminology-translations-header">
                  <Noora.Label.label label={gettext("Translations")} />
                  <Noora.Button.button
                    :if={@can_glossary_submit?}
                    type="button"
                    label={gettext("Add translation")}
                    variant="secondary"
                    size="small"
                    phx-click={"add_glossary_translation:#{@terminology_entry_index}"}
                  >
                    <:icon_left><Noora.Icon.plus /></:icon_left>
                  </Noora.Button.button>
                </div>

                <div class="terminology-translations-list">
                  <div
                    :if={map_get(@terminology_entry, :translations, []) != []}
                    class="terminology-translations-columns"
                  >
                    <span>{gettext("Language")}</span>
                    <span>{gettext("Translation")}</span>
                    <span aria-hidden="true"></span>
                  </div>

                  <%= for {translation, t_idx} <- Enum.with_index(map_get(@terminology_entry, :translations, [])) do %>
                    <div class="terminology-translation-row">
                      <div class="voice-field terminology-translation-locale">
                        <Noora.Select.select
                          id={"glossary-entry-#{@terminology_entry_index}-translation-#{t_idx}-locale"}
                          name={"entries[#{@terminology_entry_index}][translations][#{t_idx}][locale]"}
                          value={glossary_translation_value(translation, :locale)}
                          label={gettext("Select language")}
                          disabled={!@can_glossary_submit?}
                          on_value_change={
                            "select_glossary_translation_locale:#{@terminology_entry_index}:#{t_idx}"
                          }
                        >
                          <:item
                            :for={{code, name} <- locale_options()}
                            value={code}
                            label={"#{code} - #{name}"}
                            icon="language"
                          />
                        </Noora.Select.select>
                      </div>
                      <div class="voice-field terminology-translation-value">
                        <Noora.TextInput.text_input
                          id={"glossary-entry-#{@terminology_entry_index}-translation-#{t_idx}-value"}
                          name={"entries[#{@terminology_entry_index}][translations][#{t_idx}][translation]"}
                          value={glossary_translation_value(translation, :translation)}
                          placeholder={gettext("Approved translation")}
                          disabled={!@can_glossary_submit?}
                          phx-debounce="300"
                        />
                      </div>
                      <div class="terminology-translation-actions">
                        <Noora.Button.button
                          :if={@can_glossary_submit?}
                          type="button"
                          label={gettext("Remove")}
                          variant="secondary"
                          size="small"
                          phx-click={"remove_glossary_translation:#{@terminology_entry_index}:#{t_idx}"}
                        />
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </Noora.Card.card_section>
        </div>

        <%= if @can_glossary_submit? do %>
          <.save_bar
            id="glossary-entry-save-bar"
            form="glossary-entry-form"
            visible={@glossary_changed?}
            discard_event="glossary_discard"
            change_summary={@change_summary}
            generating_summary?={@generating_summary?}
            state_label={gettext("Ready to suggest changes")}
            submit_label={gettext("Suggest changes")}
            show_note={false}
          />
        <% end %>
      </form>
    </div>
    """
  end

  attr(:entry, :any, required: true)
  attr(:index, :integer, required: true)

  defp terminology_entry_hidden_fields(assigns) do
    ~H"""
    <input
      type="hidden"
      name={"entries[#{@index}][term]"}
      value={glossary_entry_value(@entry, :term)}
    />
    <input
      type="hidden"
      name={"entries[#{@index}][definition]"}
      value={glossary_entry_value(@entry, :definition)}
    />
    <input
      type="hidden"
      name={"entries[#{@index}][case_sensitive]"}
      value={glossary_case_sensitive_value(@entry)}
    />
    <%= for {translation, translation_idx} <- Enum.with_index(map_get(@entry, :translations, [])) do %>
      <input
        type="hidden"
        name={"entries[#{@index}][translations][#{translation_idx}][locale]"}
        value={glossary_translation_value(translation, :locale)}
      />
      <input
        type="hidden"
        name={"entries[#{@index}][translations][#{translation_idx}][translation]"}
        value={glossary_translation_value(translation, :translation)}
      />
    <% end %>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Terminology version
  # ---------------------------------------------------------------------------

  defp glossary_version_page(assigns) do
    ~H"""
    <div class="dash-page noora-terminology-page noora-version-page">
      <div class="noora-page-header">
        <div data-part="copy">
          <h1 data-part="page-title">
            <span>{"##{@glossary.version}"}</span>
            <span :if={@glossary.change_note} class="voice-version-title-note">
              {@glossary.change_note}
            </span>
          </h1>
          <div data-part="page-subtitle" class="voice-version-meta">
            <Noora.Time.time time={@glossary.inserted_at} show_time />
            <%= if @glossary.created_by do %>
              <span class="voice-version-meta-sep">&middot;</span>
              <span class="voice-author-chip">
                <Noora.Avatar.avatar
                  id={"glossary-version-#{@glossary.id}-author-avatar"}
                  name={
                    (@glossary.created_by.account && @glossary.created_by.account.handle) ||
                      @glossary.created_by.email
                  }
                  image_href={gravatar_url(@glossary.created_by.email)}
                  size="2xsmall"
                />
                <span>
                  {(@glossary.created_by.account && @glossary.created_by.account.handle) ||
                    @glossary.created_by.email}
                </span>
              </span>
            <% end %>
          </div>
        </div>
      </div>

      <Noora.Card.card_section class="noora-resource-table-card">
        <div data-part="header">
          <div data-part="title-group">
            <h2>{gettext("Terms")}</h2>
            <p>{gettext("Terminology entries in this version.")}</p>
          </div>
        </div>
        <Noora.Table.table
          id="glossary-version-terms"
          rows={terminology_version_table_rows(@glossary, @previous_glossary)}
          row_key={fn row -> "glossary-version-term-#{row.term}" end}
        >
          <:col :let={row} label={gettext("Term")}>
            <Noora.Table.text_and_description_cell
              icon="file_text"
              label={row.term}
              description={glossary_entry_value(row.entry, :definition)}
            />
          </:col>
          <:col :let={row} label={gettext("Translations")}>
            <Noora.Table.text_cell label={terminology_translations_summary(row.entry)} />
          </:col>
          <:col :let={row} label={gettext("Matching")}>
            <Noora.Table.status_badge_cell
              status={
                if map_get(row.entry, :case_sensitive, false), do: "attention", else: "disabled"
              }
              label={
                if map_get(row.entry, :case_sensitive, false),
                  do: gettext("Case sensitive"),
                  else: gettext("Case insensitive")
              }
            />
          </:col>
          <:col :let={row} label={gettext("Change")}>
            <%= if row.status == :existing do %>
              <Noora.Table.text_cell label={gettext("Unchanged")} />
            <% else %>
              <Noora.Table.badge_cell
                label={glossary_change_kind_label(row.status)}
                color={glossary_change_badge_color(row.status)}
                style="light-fill"
              />
            <% end %>
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="file_text"
                title={gettext("No terms")}
                subtitle={gettext("This revision does not contain terminology entries.")}
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
      </Noora.Card.card_section>
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
        description={gettext("Manage who has access to this organization.")}
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

  attr(:id, :string, required: true)
  attr(:available_filters, :list, default: [])
  attr(:active_filters, :list, default: [])

  defp settings_filter_controls(assigns) do
    ~H"""
    <div data-part="filters">
      <Noora.Filter.filter_dropdown
        id={@id}
        label={gettext("Filter")}
        available_filters={@available_filters}
        active_filters={@active_filters}
      />
    </div>
    <div :if={Enum.any?(@active_filters)} data-part="active-filters">
      <Noora.Filter.active_filter :for={filter <- @active_filters} filter={filter} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: API Tokens
  # ---------------------------------------------------------------------------

  attr(:live_action, :atom, required: true)
  attr(:handle, :string, required: true)
  attr(:api_tokens, :list, default: [])
  attr(:available_scopes, :list, default: [])
  attr(:token_form, :any, default: nil)
  attr(:newly_created_token, :string, default: nil)
  attr(:token_form_valid?, :boolean, default: false)
  attr(:tokens_search, :string, default: "")
  attr(:tokens_sort_key, :string, default: "inserted_at")
  attr(:tokens_sort_dir, :string, default: "desc")
  attr(:editing_token, :any, default: nil)
  attr(:token_edit_form, :any, default: nil)
  attr(:token_edit_changed?, :boolean, default: false)
  attr(:available_filters, :list, default: [])
  attr(:active_filters, :list, default: [])

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
          <.page_header title={gettext("New token")} />

          <.form
            for={@token_form}
            id="token-form"
            class="voice-form"
            phx-submit="create_token"
            phx-change="validate_token"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Token details")}</h2>
                <p>{gettext("Give your token a descriptive name and select the scopes it needs.")}</p>
              </div>
              <Noora.Card.card_section class="voice-card">
                <div class="voice-card-fields">
                  <Noora.TextInput.text_input
                    id="token-name"
                    name="token[name]"
                    value={@token_form[:name].value}
                    label={gettext("Name")}
                    placeholder={gettext("e.g. CI Pipeline Token")}
                    required
                    show_required
                  />
                  <Noora.TextInput.text_input
                    id="token-description"
                    name="token[description]"
                    value={@token_form[:description].value}
                    label={gettext("Description")}
                    placeholder={gettext("What is this token for?")}
                  />
                  <div class="voice-field">
                    <Noora.Label.label label={gettext("Expiration")} />
                    <Noora.Select.select
                      id="token-expiration"
                      name="token[expiration]"
                      value={@token_form[:expiration].value || "90"}
                      label={gettext("90 days")}
                      hint={gettext("Tokens with no expiration are a security risk.")}
                    >
                      <:item value="30" label={gettext("30 days")} icon="calendar_week" />
                      <:item value="60" label={gettext("60 days")} icon="calendar_week" />
                      <:item value="90" label={gettext("90 days")} icon="calendar_week" />
                      <:item value="never" label={gettext("No expiration")} icon="clock_hour_4" />
                    </Noora.Select.select>
                  </div>
                </div>
              </Noora.Card.card_section>
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
              <Noora.Card.card_section class="voice-card">
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
              </Noora.Card.card_section>
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
            class="voice-form"
            phx-submit="update_token"
            phx-change="validate_token_edit"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Token details")}</h2>
              </div>
              <Noora.Card.card_section class="voice-card">
                <div class="voice-card-fields">
                  <Noora.TextInput.text_input
                    id="edit-token-name"
                    name="token[name]"
                    value={@token_edit_form[:name].value}
                    label={gettext("Name")}
                    required
                    show_required
                  />
                  <Noora.TextInput.text_input
                    id="edit-token-description"
                    name="token[description]"
                    value={@token_edit_form[:description].value}
                    label={gettext("Description")}
                    placeholder={gettext("What is this token for?")}
                  />
                  <Noora.TextInput.text_input
                    id="edit-token-prefix"
                    value={"#{@editing_token.token_prefix}..."}
                    label={gettext("Token prefix")}
                    disabled
                  />
                  <Noora.TextInput.text_input
                    id="edit-token-expires"
                    value={
                      if @editing_token.expires_at,
                        do: Calendar.strftime(@editing_token.expires_at, "%b %d, %Y"),
                        else: gettext("Never")
                    }
                    label={gettext("Expires")}
                    disabled
                  />
                </div>
              </Noora.Card.card_section>
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
              <Noora.Card.card_section class="voice-card">
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
              </Noora.Card.card_section>
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
                  "Revoking this token will immediately prevent any applications using it from accessing Glossia."
                )}
              </p>
            </div>
            <Noora.Button.button
              type="button"
              label={gettext("Revoke token")}
              variant="destructive"
              size="medium"
              phx-click="revoke_token"
              phx-value-id={@editing_token.id}
              data-confirm={
                gettext(
                  "Are you sure you want to revoke this token? Any applications using this token will no longer be able to access the API."
                )
              }
            />
          </div>
        <% true -> %>
          <div class="noora-settings-list-page">
            <div data-part="page-header">
              <div data-part="heading">
                <h1 data-part="title">{gettext("Tokens")}</h1>
                <span data-part="subtitle">
                  {gettext(
                    "Tokens you have generated that can be used to access Glossia programmatically."
                  )}
                </span>
              </div>
              <div data-part="actions">
                <Noora.Button.button
                  patch={"/" <> @handle <> "/-/settings/tokens/new"}
                  label={gettext("Generate new token")}
                  variant="secondary"
                  size="medium"
                >
                  <:icon_left><Noora.Icon.plus /></:icon_left>
                </Noora.Button.button>
              </div>
            </div>

            <%= if @newly_created_token do %>
              <div class="api-token-reveal" id="token-reveal">
                <p>
                  {gettext("Make sure to copy your token now. You will not be able to see it again.")}
                </p>
                <div class="api-token-reveal-value">
                  <code id="token-value">{@newly_created_token}</code>
                  <Noora.Button.button
                    type="button"
                    label={gettext("Copy")}
                    variant="secondary"
                    size="small"
                    phx-hook=".CopyToken"
                    id="copy-token-btn"
                    data-value={@newly_created_token}
                  />
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

            <Noora.Card.card_section class="noora-settings-list-card">
              <div data-part="toolbar">
                <.settings_filter_controls
                  id="tokens-filter-dropdown"
                  available_filters={@available_filters}
                  active_filters={@active_filters}
                />
              </div>

              <Noora.Table.table
                id="tokens-table"
                rows={@api_tokens}
                row_key={fn token -> "token-#{token.id}" end}
                row_navigate={fn token -> "/" <> @handle <> "/-/settings/tokens/" <> token.id end}
              >
                <:col
                  :let={token}
                  label={gettext("Name")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/tokens",
                      "tokens-table",
                      @tokens_search,
                      @tokens_sort_key,
                      @tokens_sort_dir,
                      "name",
                      @active_filters
                    )
                  }
                  sort_order={if(@tokens_sort_key == "name", do: @tokens_sort_dir)}
                >
                  <Noora.Table.text_cell icon="lock_password" label={token.name} />
                </:col>
                <:col :let={token} label={gettext("Scopes")}>
                  <Noora.Table.text_cell label={token_scope_summary(token)} />
                </:col>
                <:col
                  :let={token}
                  label={gettext("Last used")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/tokens",
                      "tokens-table",
                      @tokens_search,
                      @tokens_sort_key,
                      @tokens_sort_dir,
                      "last_used_at",
                      @active_filters
                    )
                  }
                  sort_order={if(@tokens_sort_key == "last_used_at", do: @tokens_sort_dir)}
                >
                  <%= if token.last_used_at do %>
                    <Noora.Table.time_cell time={token.last_used_at} />
                  <% else %>
                    <Noora.Table.text_cell label={gettext("Never")} />
                  <% end %>
                </:col>
                <:col
                  :let={token}
                  label={gettext("Expires")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/tokens",
                      "tokens-table",
                      @tokens_search,
                      @tokens_sort_key,
                      @tokens_sort_dir,
                      "expires_at",
                      @active_filters
                    )
                  }
                  sort_order={if(@tokens_sort_key == "expires_at", do: @tokens_sort_dir)}
                >
                  <%= if token.expires_at do %>
                    <Noora.Table.time_cell time={token.expires_at} />
                  <% else %>
                    <Noora.Table.text_cell label={gettext("Never")} />
                  <% end %>
                </:col>
                <:empty_state>
                  <Noora.Table.table_empty_state>
                    <.noora_empty_state
                      icon="lock_password"
                      title={gettext("No tokens yet")}
                      subtitle={gettext("Tokens allow automated tools to authenticate with Glossia.")}
                    />
                  </Noora.Table.table_empty_state>
                </:empty_state>
              </Noora.Table.table>
            </Noora.Card.card_section>
          </div>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: OAuth Applications
  # ---------------------------------------------------------------------------

  attr(:live_action, :atom, required: true)
  attr(:handle, :string, required: true)
  attr(:oauth_apps, :list, default: [])
  attr(:oauth_app, :any, default: nil)
  attr(:boruta_client, :any, default: nil)
  attr(:app_form, :any, default: nil)
  attr(:newly_created_secret, :any, default: nil)
  attr(:newly_regenerated_secret, :string, default: nil)
  attr(:app_form_valid?, :boolean, default: false)
  attr(:app_edit_changed?, :boolean, default: false)
  attr(:apps_search, :string, default: "")
  attr(:apps_sort_key, :string, default: "inserted_at")
  attr(:apps_sort_dir, :string, default: "desc")
  attr(:available_filters, :list, default: [])
  attr(:active_filters, :list, default: [])

  defp api_apps_page(assigns) do
    ~H"""
    <div class="dash-page">
      <%= cond do %>
        <% @live_action == :api_apps_new -> %>
          <.page_header
            title={gettext("Register a new OAuth application")}
            description={
              gettext(
                "Allow users to sign in with Glossia or let an external service access the account."
              )
            }
          />

          <.form
            for={@app_form}
            id="oauth-app-form"
            class="noora-settings-form"
            phx-submit="create_oauth_app"
            phx-change="validate_oauth_app"
          >
            <Noora.Card.card_section class="noora-settings-form-card">
              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Application name")}</span>
                  <span data-part="description">
                    {gettext("A recognizable name shown when users authorize this application.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="app-name"
                    name="app[name]"
                    value={@app_form[:name].value}
                    placeholder={gettext("Internal dashboard")}
                    required
                    aria-label={gettext("Application name")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Description")}</span>
                  <span data-part="description">
                    {gettext("Explain what the application does and who owns it.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextArea.text_area
                    id="app-description"
                    name="app[description]"
                    value={@app_form[:description].value}
                    placeholder={gettext("Used by the internal content dashboard.")}
                    rows={3}
                    max_length={2_000}
                    show_character_count={false}
                    aria-label={gettext("Description")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Homepage URL")}</span>
                  <span data-part="description">
                    {gettext("The public home page for the application, if it has one.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="app-homepage"
                    name="app[homepage_url]"
                    value={@app_form[:homepage_url].value}
                    input_type="url"
                    placeholder="https://example.com"
                    aria-label={gettext("Homepage URL")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Authorization callback URL")}</span>
                  <span data-part="description">
                    {gettext("The URL where users return after authorizing the application.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="app-redirect"
                    name="app[redirect_uris]"
                    value={@app_form[:redirect_uris].value}
                    input_type="url"
                    placeholder="https://example.com/callback"
                    required
                    aria-label={gettext("Authorization callback URL")}
                  />
                </div>
              </div>
            </Noora.Card.card_section>

            <.form_save_bar
              id="oauth-app-save-bar"
              visible={@app_form_valid?}
              cancel_path={"/" <> @handle <> "/-/settings/apps"}
            />
          </.form>
        <% @live_action == :api_app_edit -> %>
          <.page_header
            title={@oauth_app.name}
            description={gettext("Manage application credentials and authorization callbacks.")}
          />

          <%= if @newly_regenerated_secret do %>
            <Noora.Alert.alert
              id="secret-reveal"
              type="secondary"
              status="warning"
              size="large"
              title={gettext("Client secret regenerated")}
              description={
                gettext("Copy your new client secret now. You will not be able to see it again.")
              }
            >
              <div class="api-token-reveal-value">
                <code>{@newly_regenerated_secret}</code>
                <Noora.Button.button
                  type="button"
                  label={gettext("Copy")}
                  variant="secondary"
                  size="small"
                  phx-hook=".CopyToken"
                  id="copy-secret-btn"
                  data-value={@newly_regenerated_secret}
                />
              </div>
            </Noora.Alert.alert>
          <% end %>

          <.form
            for={@app_form}
            id="oauth-app-edit-form"
            class="noora-settings-form"
            phx-submit="update_oauth_app"
            phx-change="validate_oauth_app_edit"
          >
            <Noora.Card.card_section class="noora-settings-form-card">
              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Client ID")}</span>
                  <span data-part="description">
                    {gettext("The stable identifier integrations use to start authorization.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="edit-app-client-id"
                    value={@boruta_client.id}
                    disabled
                    aria-label={gettext("Client ID")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Application name")}</span>
                  <span data-part="description">
                    {gettext("A recognizable name shown when users authorize this application.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="edit-app-name"
                    name="app[name]"
                    value={@app_form[:name].value}
                    required
                    aria-label={gettext("Application name")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Description")}</span>
                  <span data-part="description">
                    {gettext("Explain what the application does and who owns it.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextArea.text_area
                    id="edit-app-description"
                    name="app[description]"
                    value={@app_form[:description].value}
                    rows={3}
                    max_length={2_000}
                    show_character_count={false}
                    aria-label={gettext("Description")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Homepage URL")}</span>
                  <span data-part="description">
                    {gettext("The public home page for the application, if it has one.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="edit-app-homepage"
                    name="app[homepage_url]"
                    value={@app_form[:homepage_url].value}
                    input_type="url"
                    placeholder="https://example.com"
                    aria-label={gettext("Homepage URL")}
                  />
                </div>
              </div>

              <div data-part="section">
                <div data-part="label">
                  <span data-part="title">{gettext("Authorization callback URL")}</span>
                  <span data-part="description">
                    {gettext("The URL where users return after authorizing the application.")}
                  </span>
                </div>
                <div data-part="field">
                  <Noora.TextInput.text_input
                    id="edit-app-redirect"
                    name="app[redirect_uris]"
                    value={@app_form[:redirect_uris].value}
                    input_type="url"
                    placeholder="https://example.com/callback"
                    aria-label={gettext("Authorization callback URL")}
                  />
                </div>
              </div>
            </Noora.Card.card_section>

            <.form_save_bar
              id="oauth-app-edit-save-bar"
              visible={@app_edit_changed?}
              cancel_path={"/" <> @handle <> "/-/settings/apps"}
            />
          </.form>

          <Noora.Card.card_section class="noora-settings-actions">
            <div data-part="action">
              <div data-part="copy">
                <span data-part="title">{gettext("Client secret")}</span>
                <span data-part="description">
                  {gettext("Regenerate the client secret if you believe it has been compromised.")}
                </span>
              </div>
              <div data-part="button">
                <Noora.Button.button
                  type="button"
                  label={gettext("Regenerate client secret")}
                  variant="secondary"
                  size="medium"
                  phx-click="regenerate_secret"
                  phx-value-id={@oauth_app.id}
                  data-confirm={
                    gettext(
                      "Are you sure? Existing integrations using the current secret will stop working."
                    )
                  }
                />
              </div>
            </div>

            <div data-part="action" data-variant="danger">
              <div data-part="copy">
                <span data-part="title">{gettext("Danger zone")}</span>
                <span data-part="description">
                  {gettext(
                    "Deleting this application will revoke all tokens issued through it and break any integrations using it."
                  )}
                </span>
              </div>
              <div data-part="button">
                <Noora.Button.button
                  type="button"
                  label={gettext("Delete application")}
                  variant="destructive"
                  size="medium"
                  phx-click="delete_oauth_app"
                  phx-value-id={@oauth_app.id}
                  data-confirm={
                    gettext(
                      "Are you sure you want to delete this application? This action cannot be undone."
                    )
                  }
                />
              </div>
            </div>
          </Noora.Card.card_section>
        <% true -> %>
          <div class="noora-settings-list-page">
            <div data-part="page-header">
              <div data-part="heading">
                <h1 data-part="title">{gettext("OAuth applications")}</h1>
                <span data-part="subtitle">
                  {gettext(
                    "OAuth applications allow external services to access Glossia on behalf of users."
                  )}
                </span>
              </div>
              <div data-part="actions">
                <Noora.Button.button
                  patch={"/" <> @handle <> "/-/settings/apps/new"}
                  label={gettext("Register application")}
                  variant="secondary"
                  size="medium"
                >
                  <:icon_left><Noora.Icon.plus /></:icon_left>
                </Noora.Button.button>
              </div>
            </div>

            <%= if @newly_created_secret do %>
              <Noora.Alert.alert
                id="app-secret-reveal"
                type="secondary"
                status="warning"
                size="large"
                title={gettext("Application registered")}
                description={
                  gettext("Copy your client secret now. You will not be able to see it again.")
                }
              >
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
              </Noora.Alert.alert>
            <% end %>

            <Noora.Card.card_section class="noora-settings-list-card">
              <div data-part="toolbar">
                <.settings_filter_controls
                  id="oauth-apps-filter-dropdown"
                  available_filters={@available_filters}
                  active_filters={@active_filters}
                />
              </div>

              <Noora.Table.table
                id="oauth-apps-table"
                rows={@oauth_apps}
                row_key={fn app -> "oauth-app-#{app.id}" end}
                row_navigate={fn app -> "/" <> @handle <> "/-/settings/apps/" <> app.id end}
              >
                <:col
                  :let={app}
                  label={gettext("Name")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/apps",
                      "oauth-apps-table",
                      @apps_search,
                      @apps_sort_key,
                      @apps_sort_dir,
                      "name",
                      @active_filters
                    )
                  }
                  sort_order={if(@apps_sort_key == "name", do: @apps_sort_dir)}
                >
                  <Noora.Table.text_cell icon="apps" label={app.name} />
                </:col>
                <:col :let={app} label={gettext("Client ID")}>
                  <Noora.Table.tag_cell label={to_string(app.boruta_client_id)} />
                </:col>
                <:col
                  :let={app}
                  label={gettext("Created")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/apps",
                      "oauth-apps-table",
                      @apps_search,
                      @apps_sort_key,
                      @apps_sort_dir,
                      "inserted_at",
                      @active_filters
                    )
                  }
                  sort_order={if(@apps_sort_key == "inserted_at", do: @apps_sort_dir)}
                >
                  <Noora.Table.time_cell time={app.inserted_at} />
                </:col>
                <:empty_state>
                  <Noora.Table.table_empty_state>
                    <.noora_empty_state
                      icon="apps"
                      title={gettext("No OAuth applications yet")}
                      subtitle={
                        gettext(
                          "Register an OAuth application to let external services access your account."
                        )
                      }
                    />
                  </Noora.Table.table_empty_state>
                </:empty_state>
              </Noora.Table.table>
            </Noora.Card.card_section>
          </div>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Project
  # ---------------------------------------------------------------------------

  defp project_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header title={@project_name} />

      <%= if @project && @project.setup_status in ["pending", "running"] do %>
        <.setup_progress_panel
          status={@project.setup_status}
          events={@setup_events}
          error={@project.setup_error}
          can_retry={@can_write}
        />
      <% else %>
        <%= if @project && @project.setup_status == "failed" do %>
          <.setup_progress_panel
            status={@project.setup_status}
            events={@setup_events}
            error={@project.setup_error}
            can_retry={@can_write}
          />
        <% else %>
          <.setup_pull_request_notice
            :if={@project && @project.setup_pull_request_state in ["open", "closed"]}
            project={@project}
          />
          <.project_activity_card
            handle={@handle}
            project={@project}
            commits={@commits}
            sessions_by_sha={@sessions_by_sha}
            commits_error={@commits_error}
            commits_search={@commits_search}
            commits_sort_key={@commits_sort_key}
            commits_sort_dir={@commits_sort_dir}
            can_write={@can_write}
          />
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
        class="voice-form"
        phx-submit="update_project_settings"
        phx-change="validate_project_settings"
      >
        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("Avatar")}</h2>
            <p>{gettext("Upload an image to represent this project.")}</p>
          </div>
          <Noora.Card.card_section class="voice-card">
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
          </Noora.Card.card_section>
        </div>

        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("General")}</h2>
          </div>
          <Noora.Card.card_section class="voice-card">
            <div class="voice-card-fields">
              <Noora.TextInput.text_input
                id="project-name"
                name="project[name]"
                value={@project_settings_form[:name].value}
                label={gettext("Name")}
                required
                show_required
              />
              <Noora.TextArea.text_area
                id="project-description"
                name="project[description]"
                value={@project_settings_form[:description].value}
                label={gettext("Description")}
                rows={3}
                max_length={2_000}
                show_character_count={false}
                placeholder={gettext("A brief description of this project")}
              />
              <Noora.TextInput.text_input
                id="project-url"
                name="project[url]"
                value={@project_settings_form[:url].value}
                label={gettext("URL")}
                input_type="url"
                placeholder="https://example.com"
              />
            </div>
          </Noora.Card.card_section>
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

  attr(:project, :map, required: true)

  defp setup_pull_request_notice(assigns) do
    assigns =
      assign(
        assigns,
        :notice,
        case assigns.project.setup_pull_request_state do
          "closed" ->
            %{
              status: "warning",
              title: gettext("Setup pull request was closed"),
              description:
                gettext(
                  "Pull request #%{number} was closed without being merged. Reopen it to finish setting up localization.",
                  number: assigns.project.setup_pull_request_number
                ),
              action: gettext("View pull request")
            }

          _open ->
            %{
              status: "warning",
              title: gettext("Finish setting up Glossia"),
              description:
                gettext(
                  "Merge pull request #%{number} to activate this project's localization baseline.",
                  number: assigns.project.setup_pull_request_number
                ),
              action: gettext("Open pull request")
            }
        end
      )

    ~H"""
    <Noora.Alert.alert
      id="setup-pull-request-notice"
      type="secondary"
      status={@notice.status}
      size="large"
      title={@notice.title}
      description={@notice.description}
    >
      <:action :if={@project.setup_pull_request_url}>
        <Noora.Button.button
          href={@project.setup_pull_request_url}
          label={@notice.action}
          variant="secondary"
          size="small"
          target="_blank"
          rel="noopener noreferrer"
        />
      </:action>
    </Noora.Alert.alert>
    """
  end

  defp upload_error_to_string(:too_large), do: gettext("File is too large (max 5 MB)")
  defp upload_error_to_string(:not_accepted), do: gettext("File type not accepted")
  defp upload_error_to_string(:too_many_files), do: gettext("Too many files")
  defp upload_error_to_string(_), do: gettext("Upload error")

  defp project_activity_card(assigns) do
    ~H"""
    <%= if @commits_error do %>
      <Noora.Alert.alert
        id="project-activity-error"
        type="secondary"
        status="error"
        size="medium"
        title={gettext("Could not load activity from GitHub.")}
      />
    <% else %>
      <Noora.Card.card_section class="noora-resource-table-card">
        <div data-part="header">
          <div data-part="title-group">
            <h2>{gettext("Activity")}</h2>
            <p>{gettext("Recent content activity for this project.")}</p>
          </div>
        </div>

        <div class="noora-projects-toolbar">
          <.form for={%{}} phx-change="resource_search">
            <input type="hidden" name="table_id" value="commits-table" />
            <Noora.TextInput.text_input
              id="commits-search"
              name="search"
              type="search"
              value={@commits_search}
              placeholder={gettext("Search commits...")}
              show_suffix={false}
              phx-debounce="300"
            />
          </.form>
        </div>

        <Noora.Table.table
          id="commits-table"
          rows={@commits}
          row_key={fn commit -> "commit-#{commit.sha}" end}
        >
          <:col
            :let={commit}
            label={gettext("Commit")}
            patch={
              project_activity_sort_patch(
                @handle,
                @project.handle,
                @commits_search,
                @commits_sort_key,
                @commits_sort_dir,
                "message"
              )
            }
            sort_order={if(@commits_sort_key == "message", do: @commits_sort_dir)}
          >
            <Noora.Table.text_and_description_cell
              label={first_line(commit.message)}
              description={project_activity_session_description(@sessions_by_sha[commit.sha])}
            />
          </:col>
          <:col
            :let={commit}
            label={gettext("Author")}
            patch={
              project_activity_sort_patch(
                @handle,
                @project.handle,
                @commits_search,
                @commits_sort_key,
                @commits_sort_dir,
                "author"
              )
            }
            sort_order={if(@commits_sort_key == "author", do: @commits_sort_dir)}
          >
            <Noora.Table.text_cell label={commit.author_name}>
              <:image :if={commit.author_avatar_url}>
                <Noora.Avatar.avatar
                  id={"commit-#{commit.sha}-author-avatar"}
                  name={commit.author_name}
                  image_href={commit.author_avatar_url}
                  size="2xsmall"
                />
              </:image>
            </Noora.Table.text_cell>
          </:col>
          <:col
            :let={commit}
            label={gettext("Date")}
            patch={
              project_activity_sort_patch(
                @handle,
                @project.handle,
                @commits_search,
                @commits_sort_key,
                @commits_sort_dir,
                "date"
              )
            }
            sort_order={if(@commits_sort_key == "date", do: @commits_sort_dir)}
          >
            <%= if commit.date do %>
              <Noora.Table.time_cell time={commit.date} relative />
            <% else %>
              <Noora.Table.text_cell label="" />
            <% end %>
          </:col>
          <:col :let={commit} label={gettext("Actions")}>
            <Noora.Table.button_cell>
              <:button :if={@can_write and !@sessions_by_sha[commit.sha]}>
                <Noora.Button.button
                  label={gettext("Translate")}
                  variant="secondary"
                  size="small"
                  phx-click="translate_commit"
                  phx-value-sha={commit.sha}
                  phx-value-message={commit.message}
                />
              </:button>
              <:button>
                <Noora.Button.button
                  href={commit.url}
                  label={commit.short_sha}
                  variant="secondary"
                  size="small"
                />
              </:button>
            </Noora.Table.button_cell>
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="git_commit"
                title={gettext("No commits yet")}
                subtitle={gettext("Project activity will show up here once commits are available.")}
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
      </Noora.Card.card_section>
    <% end %>
    """
  end

  defp project_activity_session_description([session | _]) do
    gettext("Translation session: %{status}", status: session.status)
  end

  defp project_activity_session_description(_), do: nil

  attr(:handle, :string, required: true)
  attr(:project, :any, required: true)
  attr(:translations, :list, default: [])
  attr(:translations_total, :integer, default: 0)
  attr(:translations_search, :string, default: "")
  attr(:translations_sort_key, :string, default: "inserted_at")
  attr(:translations_sort_dir, :string, default: "desc")
  attr(:translations_page, :integer, default: 1)
  attr(:translations_active_filters, :any, default: [])
  attr(:available_filters, :list, default: [])
  attr(:active_filters, :list, default: [])

  defp project_translations_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Translations")}
        description={gettext("Translation sessions for this project.")}
      />

      <Noora.Card.card_section class="noora-resource-table-card">
        <div class="noora-resource-toolbar">
          <.form for={%{}} phx-change="resource_search">
            <input type="hidden" name="table_id" value="translations-table" />
            <Noora.TextInput.text_input
              id="translations-search"
              name="search"
              type="search"
              value={@translations_search}
              placeholder={gettext("Search translation sessions...")}
              show_suffix={false}
              phx-debounce="300"
            />
          </.form>

          <.settings_filter_controls
            id="translations-filter-dropdown"
            available_filters={@available_filters}
            active_filters={@active_filters}
          />
        </div>

        <Noora.Table.table
          id="translations-table"
          rows={@translations}
          row_key={fn session -> "translation-session-#{session.id}" end}
        >
          <:col
            :let={session}
            label={gettext("Status")}
            patch={
              project_translations_sort_patch(
                @handle,
                @project.handle,
                @translations_search,
                @translations_sort_key,
                @translations_sort_dir,
                "status",
                @active_filters
              )
            }
            sort_order={if(@translations_sort_key == "status", do: @translations_sort_dir)}
          >
            <Noora.Table.status_badge_cell
              status={translation_session_status_badge(session.status)}
              label={translation_session_status_label(session.status)}
            />
          </:col>
          <:col :let={session} label={gettext("Languages")}>
            <Noora.Table.text_cell
              icon="language"
              label={translation_session_languages_label(session)}
            />
          </:col>
          <:col :let={session} label={gettext("Commit")}>
            <%= if session.commit_sha do %>
              <Noora.Table.tag_cell label={String.slice(session.commit_sha, 0, 7)} />
            <% else %>
              <Noora.Table.text_cell label={gettext("No commit")} />
            <% end %>
          </:col>
          <:col
            :let={session}
            label={gettext("Created")}
            patch={
              project_translations_sort_patch(
                @handle,
                @project.handle,
                @translations_search,
                @translations_sort_key,
                @translations_sort_dir,
                "inserted_at",
                @active_filters
              )
            }
            sort_order={if(@translations_sort_key == "inserted_at", do: @translations_sort_dir)}
          >
            <Noora.Table.time_cell time={session.inserted_at} show_time />
          </:col>
          <:col :let={session} label={gettext("Actions")}>
            <Noora.Table.button_cell>
              <:button>
                <Noora.Button.button
                  navigate={"/" <> @handle <> "/" <> @project.handle <> "/-/sessions/" <> session.id}
                  label={gettext("View")}
                  variant="secondary"
                  size="small"
                />
              </:button>
            </Noora.Table.button_cell>
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="language"
                title={gettext("No translation sessions yet")}
                subtitle={
                  gettext("Translation sessions will show up here once content is translated.")
                }
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
      </Noora.Card.card_section>
    </div>
    """
  end

  defp project_translations_sort_patch(
         handle,
         project_handle,
         search,
         current_sort_key,
         current_sort_dir,
         sort_key,
         active_filters
       ) do
    sort_dir =
      if current_sort_key == sort_key and current_sort_dir == "asc",
        do: "desc",
        else: "asc"

    settings_table_patch(
      handle,
      "/" <> project_handle <> "/-/translations",
      "translations-table",
      search,
      sort_key,
      sort_dir,
      active_filters
    )
  end

  defp translation_session_languages_label(%{source_language: nil}), do: gettext("Not configured")

  defp translation_session_languages_label(session) do
    target_languages = session.target_languages || []
    session.source_language <> " -> " <> Enum.join(target_languages, ", ")
  end

  defp translation_session_status_badge("completed"), do: "success"
  defp translation_session_status_badge("failed"), do: "error"
  defp translation_session_status_badge("running"), do: "in_progress"
  defp translation_session_status_badge("pending"), do: "attention"
  defp translation_session_status_badge("cancelled"), do: "disabled"
  defp translation_session_status_badge(_), do: "disabled"

  defp translation_session_status_label("completed"), do: gettext("Completed")
  defp translation_session_status_label("failed"), do: gettext("Failed")
  defp translation_session_status_label("running"), do: gettext("Running")
  defp translation_session_status_label("pending"), do: gettext("Pending")
  defp translation_session_status_label("cancelled"), do: gettext("Cancelled")
  defp translation_session_status_label(status), do: status

  defp translation_session_cancellable?(%{status: status}), do: status in ["pending", "running"]

  defp session_detail_page(assigns) do
    ~H"""
    <div id="translation-session" class="dash-page">
      <.page_header
        title={gettext("Translation session")}
        description={
          if @session.commit_sha,
            do: gettext("Session for commit %{sha}", sha: String.slice(@session.commit_sha, 0, 7)),
            else: gettext("Translation session details")
        }
      />

      <div class="card" data-part="overview">
        <div data-part="overview-header">
          <div data-part="overview-primary">
            <span class={["badge", "badge-#{@session.status}"]}>{@session.status}</span>
            <%= if @session.source_language do %>
              <span data-part="languages">
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
          <Noora.Button.button
            :if={assigns[:can_write] && translation_session_cancellable?(@session)}
            type="button"
            label={gettext("Cancel translation")}
            variant="secondary"
            size="small"
            phx-click="cancel_translation_session"
          />
        </div>
        <%= if @session.commit_message do %>
          <p data-part="commit-message">{@session.commit_message}</p>
        <% end %>
        <div data-part="metadata">
          <%= if @session.started_at do %>
            <span>{gettext("Started %{time}", time: relative_time(@session.started_at))}</span>
          <% end %>
          <%= if @session.completed_at do %>
            <span>{gettext("Completed %{time}", time: relative_time(@session.completed_at))}</span>
          <% end %>
          <%= if @session.summary do %>
            <span>{@session.summary}</span>
          <% end %>
          <a
            :if={@session.pull_request_url}
            href={@session.pull_request_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            {gettext("Open pull request")}
          </a>
        </div>
      </div>

      <.translation_progress_panel
        items={@translation_progress_items}
        summary={@translation_progress_summary}
        failures={@translation_progress_failures}
      />

      <%= if @session_events != [] do %>
        <div class="session-event-feed" data-part="event-feed">
          <%= for event <- @session_events do %>
            <.session_event_item event={event} project={@project} />
          <% end %>
        </div>
      <% else %>
        <%= if @translation_progress_items == [] do %>
          <div class="dash-empty-state">
            <p>{gettext("No events recorded yet.")}</p>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr :items, :list, required: true
  attr :summary, :map, required: true
  attr :failures, :list, required: true

  defp translation_progress_panel(assigns) do
    assigns =
      assign(assigns, :display_running, translation_progress_display_running(assigns.summary))

    ~H"""
    <%= if @items != [] do %>
      <div id="translation-progress" class="translation-progress">
        <div id="translation-progress-summary" data-part="summary">
          <span id="translation-progress-summary-translated" data-part="translated">
            {gettext("%{done}/%{total} translated", done: @summary.done, total: @summary.total)}
          </span>
          <%= if @display_running > 0 do %>
            <span id="translation-progress-summary-running" data-part="running">
              {gettext("%{n} in progress", n: @display_running)}
            </span>
          <% end %>
          <%= if @summary.failed > 0 do %>
            <span id="translation-progress-summary-failed" data-part="failed">
              {gettext("%{n} failed", n: @summary.failed)}
            </span>
          <% end %>
          <%= if @summary.skipped > 0 do %>
            <span id="translation-progress-summary-skipped" data-part="skipped">
              {gettext("%{n} up to date", n: @summary.skipped)}
            </span>
          <% end %>
        </div>
        <div :if={@failures != []} id="translation-progress-failures" data-part="failures">
          <section
            :for={failure <- @failures}
            id={failure.dom_id}
            data-part="failure-summary"
            data-kind={failure.kind}
            role="alert"
          >
            <span data-part="failure-icon" aria-hidden="true">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <circle cx="12" cy="12" r="10"></circle>
                <path d="M12 8v4"></path>
                <path d="M12 16h.01"></path>
              </svg>
            </span>
            <div data-part="failure-content">
              <p data-part="failure-title">{failure.title}</p>
              <p data-part="failure-description">{failure.description}</p>
              <p data-part="failure-count">
                {ngettext(
                  "%{count} file was affected.",
                  "%{count} files were affected.",
                  failure.count,
                  count: failure.count
                )}
              </p>
              <a
                :if={failure.action_url}
                data-part="failure-action"
                href={failure.action_url}
                target="_blank"
                rel="noopener noreferrer"
              >
                {failure.action_label}
              </a>
            </div>
          </section>
        </div>
        <ul id="translation-progress-items" data-part="items">
          <%= for item <- @items do %>
            <li
              id={"translation-progress-item-#{item.index}"}
              class="card"
              data-part="item"
              data-status={item.status}
            >
              <div data-part="item-header">
                <span data-part="status">
                  <%= if item.status == :running do %>
                    <span data-part="indicator" aria-hidden="true"></span>
                  <% end %>
                  {translation_item_status_label(item.status)}
                </span>
                <a
                  :if={item.file_url}
                  data-part="path"
                  href={item.file_url}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {item.output_path}
                </a>
                <span :if={is_nil(item.file_url)} data-part="path">{item.output_path}</span>
                <span data-part="locale">{item.locale}</span>
                <span data-part="progress-meta">
                  <span :if={item.segment_kind == "frontmatter"}>
                    {gettext("Front matter")}
                  </span>
                  <span :if={item.segment_count && item.segment_count > 1}>
                    {gettext("Segment %{index} of %{count}",
                      index: item.segment_index,
                      count: item.segment_count
                    )}
                  </span>
                  <span>
                    {ngettext(
                      "%{n} model call",
                      "%{n} model calls",
                      item.turns,
                      n: item.turns
                    )}
                  </span>
                </span>
              </div>
              <div
                :if={item.failure}
                data-part="item-failure"
                data-kind={item.failure.kind}
              >
                <span data-part="item-failure-icon" aria-hidden="true">
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M12 8v4"></path>
                    <path d="M12 16h.01"></path>
                  </svg>
                </span>
                <div data-part="item-failure-content">
                  <p data-part="item-failure-title">{item.failure.title}</p>
                  <p data-part="item-failure-description">{item.failure.item_description}</p>
                  <details
                    :if={item.failure.diagnostics != []}
                    id={"translation-progress-item-#{item.index}-diagnostics"}
                    data-part="item-diagnostics"
                    phx-mounted={Phoenix.LiveView.JS.ignore_attributes("open")}
                  >
                    <summary>{gettext("Diagnostic details")}</summary>
                    <dl>
                      <div :for={{label, value} <- item.failure.diagnostics}>
                        <dt>{label}</dt>
                        <dd>{value}</dd>
                      </div>
                    </dl>
                  </details>
                </div>
              </div>
              <%= if item.text != "" do %>
                <%= cond do %>
                  <% item.status == :running -> %>
                    <div data-part="live-output">
                      <pre data-part="stream">{String.slice(item.text, 0, 2000)}</pre>
                    </div>
                  <% item.status == :failed -> %>
                    <details data-part="partial-output">
                      <summary>{gettext("Show incomplete output")}</summary>
                      <pre data-part="stream">{String.slice(item.text, 0, 2000)}</pre>
                    </details>
                  <% true -> %>
                    <details data-part="completed-output">
                      <summary>{gettext("Show translated output")}</summary>
                      <pre data-part="stream">{String.slice(item.text, 0, 2000)}</pre>
                    </details>
                <% end %>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    <% end %>
    """
  end

  defp translation_progress_display_running(%{running: running}) when running > 0, do: running

  defp translation_progress_display_running(summary) do
    processed = summary.done + summary.failed + summary.skipped
    if processed < summary.total, do: 1, else: 0
  end

  defp translation_item_status_label(:running), do: gettext("Translating")
  defp translation_item_status_label(:done), do: gettext("Done")
  defp translation_item_status_label(:failed), do: gettext("Failed")

  defp translation_file_url(
         %{github_repo_full_name: repository},
         :done,
         file_ref,
         output_path
       )
       when is_binary(repository) and repository != "" and is_binary(file_ref) and
              file_ref != "" and is_binary(output_path) and output_path != "" do
    encoded_path =
      output_path
      |> String.split("/", trim: false)
      |> Enum.map_join("/", fn segment ->
        URI.encode(segment, &URI.char_unreserved?/1)
      end)

    "https://github.com/#{repository}/blob/#{file_ref}/#{encoded_path}"
  end

  defp translation_file_url(_project, _status, _file_ref, _output_path), do: nil

  defp translation_failure_groups(items) do
    failures =
      items
      |> Enum.filter(&(&1.status == :failed and Failure.session_level?(&1.reason)))
      |> Enum.map(& &1.failure)

    specific_kinds_by_provider =
      failures
      |> Enum.reject(&(&1.kind == "provider-error"))
      |> Enum.group_by(& &1.provider, & &1.kind)
      |> Map.new(fn {provider, kinds} -> {provider, Enum.uniq(kinds)} end)

    # Some providers omit the original status after repeated failures. Fold
    # those generic errors into the provider's only known specific cause.
    failures
    |> Enum.group_by(&translation_failure_group_kind(&1, specific_kinds_by_provider))
    |> Enum.map(fn {_kind, failures} ->
      kind = translation_failure_group_kind(hd(failures), specific_kinds_by_provider)

      failures
      |> Enum.find(hd(failures), &(&1.kind == kind))
      |> Map.put(:count, length(failures))
      |> then(&Map.put(&1, :dom_id, translation_failure_dom_id(kind)))
    end)
    |> Enum.sort_by(& &1.first_index)
  end

  defp translation_failure_group_kind(
         %{kind: "provider-error", provider: provider},
         specific_kinds_by_provider
       )
       when is_binary(provider) do
    case Map.get(specific_kinds_by_provider, provider, []) do
      [kind] -> kind
      _ -> "provider-error"
    end
  end

  defp translation_failure_group_kind(failure, _specific_kinds_by_provider), do: failure.kind

  defp translation_failure_dom_id(kind) do
    digest =
      :sha256
      |> :crypto.hash(kind)
      |> Base.url_encode64(padding: false)
      |> binary_part(0, 12)

    "translation-progress-failure-#{digest}"
  end

  defp translation_failure(reason, index) do
    failure = Failure.normalize(reason)
    presentation = translation_failure_presentation(failure.kind)

    failure
    |> Map.merge(presentation)
    |> Map.put(:first_index, index)
    |> Map.put(:diagnostics, translation_failure_diagnostics(failure))
    |> Map.put(:action_url, translation_failure_action_url(failure))
  end

  defp translation_failure_presentation("provider-credit") do
    %{
      title: gettext("Model provider credit limit reached"),
      description:
        gettext(
          "Add credits to your model provider account, then retry this translation session."
        ),
      item_description:
        gettext(
          "This file could not be translated because the model provider account has no remaining credit."
        ),
      action_label: gettext("Review provider billing")
    }
  end

  defp translation_failure_presentation("provider-rate-limit") do
    %{
      title: gettext("Model provider rate limit reached"),
      description: gettext("Wait a moment, then retry this translation session."),
      item_description:
        gettext(
          "This file could not be translated because the provider is temporarily limiting requests."
        ),
      action_label: nil
    }
  end

  defp translation_failure_presentation("provider-credentials") do
    %{
      title: gettext("Model provider credentials were rejected"),
      description:
        gettext("Check the model provider credentials, then retry this translation session."),
      item_description:
        gettext(
          "This file could not be translated because the provider rejected the configured credentials."
        ),
      action_label: nil
    }
  end

  defp translation_failure_presentation("provider-timeout") do
    %{
      title: gettext("The model provider did not respond in time"),
      description:
        gettext("Retry this translation session. If the problem continues, check the provider."),
      item_description:
        gettext("This file could not be translated because the provider did not respond in time."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("provider-error") do
    %{
      title: gettext("The model provider request failed"),
      description:
        gettext("Retry this translation session. If the problem continues, check the provider."),
      item_description:
        gettext("This file could not be translated because the model provider request failed."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("validation-syntax") do
    %{
      title: gettext("Translated output has invalid syntax"),
      description: nil,
      item_description:
        gettext("Glossia could not produce well-formed output for this file after retrying."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("validation-preserved-content") do
    %{
      title: gettext("Translated output changed protected content"),
      description: nil,
      item_description:
        gettext("Glossia could not preserve every required token in this file after retrying."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("validation-command") do
    %{
      title: gettext("Translated output did not pass the project check"),
      description: nil,
      item_description:
        gettext("The validation command rejected the translated output for this file."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("validation") do
    %{
      title: gettext("Translated output did not pass validation"),
      description: nil,
      item_description:
        gettext("Glossia could not produce output that passed this file's validation rules."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("source-invalid-encoding") do
    %{
      title: gettext("Source file is not valid text"),
      description: nil,
      item_description: gettext("Glossia could not read this file as text."),
      action_label: nil
    }
  end

  defp translation_failure_presentation("source-unreadable") do
    %{
      title: gettext("Source file could not be read"),
      description: nil,
      item_description: gettext("Glossia could not read this source file."),
      action_label: nil
    }
  end

  defp translation_failure_presentation(_kind) do
    %{
      title: gettext("Translation failed"),
      description: nil,
      item_description:
        gettext("Glossia could not translate this file. Retry the translation session."),
      action_label: nil
    }
  end

  defp translation_failure_diagnostics(failure) do
    [
      {gettext("Provider"), failure.provider},
      {gettext("Provider response status"), failure.status && to_string(failure.status)},
      {gettext("Provider error code"), failure.code},
      {gettext("Provider request identifier"), failure.request_id}
    ]
    |> Enum.reject(fn {_label, value} -> is_nil(value) end)
  end

  defp translation_failure_action_url(%{kind: "provider-credit", provider: provider})
       when provider in ["together", "togetherai"],
       do: "https://api.together.ai/settings/billing"

  defp translation_failure_action_url(_failure), do: nil

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
        |> assign(:status, setup_event_status(event_type, content))
        |> assign(:title, setup_event_title(event_type, tool_name))
        |> assign(:description, setup_event_description(event_type, content, tool_name))
        |> assign(:body_html, setup_event_body_html(event_type, content))

      ~H"""
      <div
        class={"setup-event-row #{if @status == "information", do: "setup-event-row-no-badge", else: ""}"}
        data-status={@status}
      >
        <Noora.Badge.status_badge
          :if={@status != "information"}
          status={setup_event_badge_status(@status)}
          label={setup_event_status_label(@status)}
          type="dot"
        />
        <div class="setup-event-row-content">
          <div class="setup-event-row-header">
            <span class="setup-event-row-title">{@title}</span>
            <Noora.Button.button
              :if={@event_type == "pr_created"}
              href={@content}
              label={gettext("Open pull request")}
              variant="secondary"
              size="small"
              target="_blank"
              rel="noopener noreferrer"
            />
          </div>
          <p :if={@description != ""} class="setup-event-row-description">{@description}</p>
          <div :if={@body_html != ""} class="setup-event-row-body prose">{raw(@body_html)}</div>
        </div>
      </div>
      """
    end
  end

  attr(:status, :string, required: true)
  attr(:events, :list, default: [])
  attr(:error, :string, default: nil)
  attr(:can_retry, :boolean, default: false)
  attr(:pr_url, :string, default: nil)

  defp setup_progress_panel(assigns) do
    ~H"""
    <Noora.Card.card id="setup-progress-card" icon="settings" title={gettext("Localization setup")}>
      <:actions>
        <Noora.Badge.status_badge
          status={project_setup_status(@status)}
          label={project_setup_status_label(@status)}
        />
      </:actions>
      <Noora.Card.card_section class="setup-progress-section">
        <Noora.Alert.alert
          :if={@status == "failed"}
          type="secondary"
          status="error"
          size="large"
          title={gettext("Setup failed")}
          description={@error || gettext("An error occurred during setup.")}
        >
          <:action :if={@can_retry}>
            <Noora.Button.button
              type="button"
              label={gettext("Retry setup")}
              size="small"
              phx-click="retry_setup"
            />
          </:action>
        </Noora.Alert.alert>

        <Noora.Alert.alert
          :if={@status == "completed"}
          type="secondary"
          status="success"
          size="large"
          title={gettext("Setup complete")}
          description={gettext("Your localization baseline is ready for review.")}
        >
          <:action :if={@pr_url}>
            <Noora.Button.button
              href={@pr_url}
              label={gettext("Open pull request")}
              variant="secondary"
              size="small"
              target="_blank"
              rel="noopener noreferrer"
            />
          </:action>
        </Noora.Alert.alert>

        <div :if={@events != []} data-part="events" id="setup-events">
          <.setup_event_item :for={event <- @events} event={event} />
        </div>
      </Noora.Card.card_section>
    </Noora.Card.card>
    """
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
      "update",
      "plan",
      "harness_output",
      "tool_result",
      "tool_execution_end"
    ] or
      (content == "" and event_type == "status") or
      (event_type == "status" and setup_internal_status?(content))
  end

  defp setup_event_title(event_type, tool_name) do
    label =
      case event_type do
        "error" ->
          gettext("Setup error")

        "prompt" ->
          gettext("Setup instructions prepared")

        "pr_created" ->
          gettext("Pull request created")

        event_kind when event_kind in ["tool_call", "tool_execution_start"] ->
          gettext("Working on %{step}", step: tool_name_or_fallback(tool_name))

        event_kind when event_kind in ["tool_result", "tool_execution_end"] ->
          gettext("Finished %{step}", step: tool_name_or_fallback(tool_name))

        "status" ->
          gettext("Setup update")

        event_kind when event_kind in ["text", "message_start", "message_update"] ->
          gettext("Setup assistant update")

        _ ->
          gettext("Setup update")
      end

    label
  end

  defp setup_event_description(event_type, content, tool_name) do
    case event_type do
      "prompt" ->
        gettext("The repository and language choices are ready for the setup assistant.")

      "pr_created" ->
        gettext("The localization baseline is ready for review and merge.")

      event_kind when event_kind in ["tool_call", "tool_execution_start"] ->
        if content == tool_name,
          do: gettext("The setup assistant is applying the next repository change."),
          else: first_line(content)

      "status" ->
        gettext("The setup assistant is continuing with the repository setup.")

      event_kind when event_kind in ["harness_output", "warning"] ->
        gettext("The setup assistant is continuing with the repository setup.")

      event_kind when event_kind in ["text", "message_start", "message_update"] ->
        ""

      event_kind when event_kind in ["tool_result", "tool_execution_end"] ->
        if setup_event_failed?(content),
          do: gettext("The setup assistant could not complete this step."),
          else: gettext("The setup assistant completed this step.")

      _ ->
        first_line(content)
    end
  end

  defp setup_event_status(event_type, content) do
    case event_type do
      "error" ->
        "error"

      "pr_created" ->
        "success"

      event_kind when event_kind in ["tool_result", "tool_execution_end"] ->
        if setup_event_failed?(content), do: "error", else: "success"

      "warning" ->
        "warning"

      _ ->
        "information"
    end
  end

  defp setup_event_failed?(content) do
    downcased = String.downcase(content || "")

    Enum.any?(
      ["permission denied", "command failed", "exit status", "error:"],
      &String.contains?(downcased, &1)
    )
  end

  defp setup_event_status_label("success"), do: gettext("Done")
  defp setup_event_status_label("error"), do: gettext("Error")
  defp setup_event_status_label("warning"), do: gettext("Warning")
  defp setup_event_status_label(_), do: gettext("Update")

  defp setup_event_badge_status("information"), do: "in_progress"
  defp setup_event_badge_status(status), do: status

  defp setup_event_body_html(event_type, content) do
    body = setup_event_body(event_type, content)

    if body == "", do: "", else: Glossia.Markdown.to_html!(body)
  end

  defp setup_event_body(_event_type, ""), do: ""

  defp setup_event_body(event_type, _content)
       when event_type in [
              "prompt",
              "status",
              "harness_output",
              "warning",
              "tool_result",
              "tool_execution_end"
            ],
       do: ""

  defp setup_event_body(_event_type, content) do
    case JSON.decode(content) do
      {:ok, %{"type" => "item.started", "item" => %{"type" => "todo_list", "items" => items}}}
      when is_list(items) ->
        Enum.map_join(items, "\n", fn item ->
          checked = if item["completed"], do: "x", else: " "
          "- [#{checked}] #{item["text"]}"
        end)

      _ ->
        content
    end
  end

  defp tool_name_or_fallback(""), do: gettext("repository setup")

  defp tool_name_or_fallback(tool_name) do
    tool_name
    |> String.replace("command_execution", "command")
    |> String.replace("file_change", "file change")
    |> String.replace("_", " ")
  end

  defp setup_progress("completed", _events), do: 100

  defp setup_progress(status, events) when status in ["pending", "running", "failed"] do
    visible_count =
      Enum.count(events, fn event ->
        event_type = Map.get(event, :event_type, "")
        content = (Map.get(event, :content, "") || "") |> to_string()
        metadata = setup_event_metadata(event)
        tool_name = setup_event_tool_name(event_type, content, metadata)

        not skip_setup_event?(event_type, content) and
          setup_event_has_visible_content?(event_type, content, tool_name)
      end)

    min(10 + visible_count * 8, 90)
  end

  defp setup_progress(_status, _events), do: 0

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
      "Starting opencode in headless mode",
      "Session created",
      "Setup harness started",
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

  defp maybe_backfill_setup_pull_request(
         %{setup_status: "completed", setup_pull_request_number: nil} = project,
         events
       ) do
    with url when is_binary(url) <- setup_pr_url(events),
         [_, number_string] <- Regex.run(~r{/pull/(\d+)}, url),
         {number, ""} <- Integer.parse(number_string),
         {:ok, updated_project} <-
           Glossia.Projects.backfill_setup_pull_request(project, %{number: number, url: url}) do
      updated_project
    else
      _missing_reference -> project
    end
  end

  defp maybe_backfill_setup_pull_request(project, _events), do: project

  defp setup_pr_url_from_audit(_account, _project), do: nil

  # ---------------------------------------------------------------------------
  # Page: New Project (wizard)
  # ---------------------------------------------------------------------------

  defp project_new_wizard(assigns) do
    ~H"""
    <div class="dash-page" id="project-new">
      <.page_header
        title={gettext("New project")}
        description={gettext("Import a GitHub repository and set up localization.")}
      />

      <div data-part="wizard-progress">
        <Noora.ProgressBar.progress_bar
          value={wizard_step_progress(@step, @wizard_project, @setup_events)}
          max={100}
          data-running={wizard_running?(@step, @wizard_project)}
        />
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
        <Noora.Card.card id="repository-picker" icon="folder" title={gettext("Repository")}>
          <:actions>
            <Noora.Badge.badge
              color="neutral"
              style="light-fill"
              label={
                ngettext("%{count} repository", "%{count} repositories", length(@filtered_repos),
                  count: length(@filtered_repos)
                )
              }
            />
          </:actions>
          <Noora.Card.card_section class="project-setup-picker-section">
            <form phx-change="search_repos" class="project-setup-search-form">
              <Noora.TextInput.text_input
                id="repository-search"
                type="search"
                name="value"
                value={@github_repos_search}
                placeholder={gettext("Search repositories...")}
                phx-debounce="300"
                show_suffix={false}
                aria-label={gettext("Search repositories")}
              />
            </form>

            <Noora.Table.table
              id="repositories"
              rows={@filtered_repos}
              row_key={fn repo -> "repository-" <> to_string(repo["id"]) end}
            >
              <:col :let={repo} label={gettext("Repository")}>
                <Noora.Table.text_and_description_cell
                  icon="folder"
                  label={repo["full_name"]}
                  description={repo["description"]}
                />
              </:col>
              <:col :let={repo} label={gettext("Language")}>
                <Noora.Table.text_cell label={repo["language"] || gettext("Not detected")} />
              </:col>
              <:col :let={repo}>
                <Noora.Table.button_cell>
                  <:button>
                    <Noora.Button.button
                      type="button"
                      label={gettext("Select")}
                      size="small"
                      phx-click="select_repo"
                      phx-value-repo-id={repo["id"]}
                      phx-value-full-name={repo["full_name"]}
                      phx-value-name={repo["name"]}
                      phx-value-default-branch={repo["default_branch"]}
                      phx-value-description={repo["description"]}
                      phx-value-development={if(repo["development"], do: "true", else: "false")}
                      phx-value-owner-login={get_in(repo, ["owner", "login"])}
                    />
                  </:button>
                </Noora.Table.button_cell>
              </:col>
              <:empty_state>
                <Noora.Table.table_empty_state>
                  <.noora_empty_state
                    icon="search"
                    title={gettext("No matching repositories")}
                    subtitle={gettext("Try adjusting your search query.")}
                  />
                </Noora.Table.table_empty_state>
              </:empty_state>
            </Noora.Table.table>

            <Noora.Alert.alert
              type="secondary"
              status="information"
              size="large"
              title={gettext("Don't see your repository?")}
              description={gettext("Update the GitHub App installation to change repository access.")}
            >
              <:action>
                <Noora.Button.button
                  href={"/" <> @handle <> "/-/projects/install-github"}
                  label={gettext("Configure repository access")}
                  variant="secondary"
                  size="small"
                />
              </:action>
            </Noora.Alert.alert>
          </Noora.Card.card_section>
        </Noora.Card.card>
      <% @github_configured? -> %>
        <Noora.Alert.alert
          type="secondary"
          status="warning"
          size="large"
          title={gettext("No repositories accessible")}
          description={
            gettext(
              "The GitHub App is installed but has no accessible repositories. Configure the installation to grant access to the repositories you want to import."
            )
          }
        >
          <:action>
            <Noora.Button.button
              href={"/" <> @handle <> "/-/projects/install-github"}
              label={gettext("Configure repository access")}
              size="small"
            />
          </:action>
        </Noora.Alert.alert>
      <% true -> %>
        <Noora.Alert.alert
          type="secondary"
          status="information"
          size="large"
          title={gettext("Connect a Git provider")}
          description={
            gettext("Install the Glossia GitHub App to import repositories and set up localization.")
          }
        >
          <:action>
            <Noora.Button.button
              href={"/" <> @handle <> "/-/projects/install-github"}
              label={gettext("Install GitHub App")}
              size="small"
            />
          </:action>
        </Noora.Alert.alert>
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

    selected_summary =
      ngettext("%{count} language selected", "%{count} languages selected", selected_count,
        count: selected_count
      )

    assigns = assign(assigns, selected_count: selected_count, selected_summary: selected_summary)

    ~H"""
    <Noora.Card.card id="language-picker" icon="language" title={gettext("Target languages")}>
      <:actions>
        <Noora.Button.button
          type="button"
          label={gettext("Back")}
          variant="secondary"
          size="small"
          phx-click="wizard_back"
          phx-value-step="repo"
        />
        <Noora.Button.button
          type="button"
          label={gettext("Set up project")}
          size="small"
          phx-click="start_setup"
          disabled={@selected_count == 0}
        />
      </:actions>
      <Noora.Card.card_section class="project-setup-picker-section">
        <Noora.Alert.alert
          type="secondary"
          status="information"
          size="large"
          title={@selected_repo["full_name"]}
          description={@selected_summary}
        />

        <form phx-change="search_languages" class="project-setup-search-form">
          <Noora.TextInput.text_input
            id="language-search"
            type="search"
            name="value"
            value={@language_search}
            placeholder={gettext("Search languages...")}
            phx-debounce="200"
            show_suffix={false}
            aria-label={gettext("Search languages")}
          />
        </form>

        <Noora.Table.table
          id="languages"
          rows={@filtered_languages}
          row_key={fn language -> "language-" <> language.code end}
        >
          <:col :let={language} label={gettext("Language")}>
            <Noora.Table.text_and_description_cell
              icon="language"
              label={language.name}
              description={language.native}
            />
          </:col>
          <:col :let={language} label={gettext("Code")}>
            <Noora.Table.tag_cell label={language.code} />
          </:col>
          <:col :let={language} label={gettext("Selection")}>
            <Noora.Table.status_badge_cell
              status={if language.code in @selected_languages, do: "success", else: "disabled"}
              label={
                if language.code in @selected_languages,
                  do: gettext("Selected"),
                  else: gettext("Not selected")
              }
            />
          </:col>
          <:col :let={language}>
            <Noora.Table.button_cell>
              <:button>
                <Noora.Button.button
                  type="button"
                  label={
                    if language.code in @selected_languages,
                      do: gettext("Remove"),
                      else: gettext("Select")
                  }
                  variant={if language.code in @selected_languages, do: "secondary", else: "primary"}
                  size="small"
                  phx-click="toggle_language"
                  phx-value-code={language.code}
                />
              </:button>
            </Noora.Table.button_cell>
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="search"
                title={gettext("No matching languages")}
                subtitle={gettext("Try adjusting your search query.")}
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
      </Noora.Card.card_section>
    </Noora.Card.card>
    """
  end

  defp wizard_step_progress("repo", _project, _events), do: 33
  defp wizard_step_progress("languages", _project, _events), do: 66

  defp wizard_step_progress("setup", project, events) do
    setup_progress(project_setup_status_value(project), events)
  end

  defp wizard_step_progress(_, _project, _events), do: 0

  defp project_setup_status_value(%{setup_status: status}), do: status
  defp project_setup_status_value(_), do: "pending"

  # Drives the animated shimmer on the wizard progress bar: only while the setup
  # step is actively working (nil otherwise, so the attribute is omitted).
  defp wizard_running?("setup", %{setup_status: status}) when status in ["pending", "running"],
    do: "true"

  defp wizard_running?(_step, _project), do: nil

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
      <.setup_progress_panel
        status={@status || "pending"}
        events={@setup_events}
        error={@wizard_project && @wizard_project.setup_error}
        can_retry={@status == "failed"}
        pr_url={@pr_url}
      />

      <div :if={@status in ["completed", "failed"]} class="wizard-footer">
        <Noora.Button.button
          type="button"
          label={gettext("Go to project")}
          size="medium"
          phx-click="finish_setup"
        />
      </div>
    </div>
    """
  end

  attr(:voice, :map, default: nil)
  attr(:original_voice, :map, default: nil)
  attr(:voice_form_params, :map, default: %{})
  attr(:overrides, :list, default: [])
  attr(:original_overrides, :list, default: [])
  attr(:target_countries, :list, default: [])
  attr(:cultural_notes, :map, default: %{})

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

  attr(:glossary_entries, :list, default: [])
  attr(:original_glossary_entries, :list, default: [])

  defp glossary_suggestion_changes(assigns) do
    assigns =
      assign(
        assigns,
        :change_details,
        glossary_change_details(assigns.glossary_entries, assigns.original_glossary_entries)
      )

    ~H"""
    <Noora.Card.card_section class="noora-resource-table-card">
      <div data-part="header">
        <div data-part="title-group">
          <h2>{gettext("Proposed changes")}</h2>
          <p>{gettext("This review is read-only. Go back to continue editing your draft.")}</p>
        </div>
      </div>
      <Noora.Table.table
        id="terminology-proposed-changes"
        rows={@change_details}
        row_key={fn change -> "terminology-proposed-change-#{change.term}" end}
      >
        <:col :let={change} label={gettext("Term")}>
          <% entry = glossary_change_display_entry(change) %>
          <Noora.Table.text_and_description_cell
            icon="file_text"
            label={change.term}
            description={glossary_entry_value(entry, :definition)}
          />
        </:col>
        <:col :let={change} label={gettext("Translations")}>
          <% entry = glossary_change_display_entry(change) %>
          <Noora.Table.text_cell label={terminology_translations_summary(entry)} />
        </:col>
        <:col :let={change} label={gettext("Matching")}>
          <% entry = glossary_change_display_entry(change) %>
          <Noora.Table.status_badge_cell
            status={if map_get(entry, :case_sensitive, false), do: "attention", else: "disabled"}
            label={
              if map_get(entry, :case_sensitive, false),
                do: gettext("Case sensitive"),
                else: gettext("Case insensitive")
            }
          />
        </:col>
        <:col :let={change} label={gettext("Change")}>
          <Noora.Table.badge_cell
            label={glossary_change_kind_label(change.kind)}
            color={glossary_change_badge_color(change.kind)}
            style="light-fill"
          />
        </:col>
        <:empty_state>
          <Noora.Table.table_empty_state>
            <.noora_empty_state
              icon="file_text"
              title={gettext("No proposed terminology changes")}
              subtitle={gettext("Go back to edit your draft before creating a suggestion.")}
            />
          </Noora.Table.table_empty_state>
        </:empty_state>
      </Noora.Table.table>
    </Noora.Card.card_section>
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

  defp glossary_change_badge_color(:added), do: "success"
  defp glossary_change_badge_color(:removed), do: "destructive"
  defp glossary_change_badge_color(:updated), do: "primary"
  defp glossary_change_badge_color(_), do: "neutral"

  defp glossary_version_entry_status(nil, nil), do: :existing
  defp glossary_version_entry_status(_current, nil), do: :added
  defp glossary_version_entry_status(nil, _previous), do: :removed

  defp glossary_version_entry_status(current, previous) do
    if glossary_entry_signature(current) == glossary_entry_signature(previous),
      do: :existing,
      else: :updated
  end

  # ---------------------------------------------------------------------------
  # Shared: Diff field component
  # ---------------------------------------------------------------------------

  attr(:label, :string, required: true)
  attr(:current, :string, default: nil)
  attr(:previous, :string, default: nil)
  attr(:formatter, :any, default: nil)

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
  defp non_empty("__base__"), do: nil
  defp non_empty(val), do: val

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
            tone: non_empty(normalize_noora_empty_value(override["tone"] || "")),
            formality: non_empty(normalize_noora_empty_value(override["formality"] || "")),
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
        "tone" => normalize_noora_empty_value(Map.get(override, "tone", "")),
        "formality" => normalize_noora_empty_value(Map.get(override, "formality", "")),
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
          |> push_patch(
            to: maybe_with_draft_param("/#{handle}/-/terminology/suggestion/new", token)
          )
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
      glossary_draft_path = maybe_with_draft_param("/#{handle}/-/terminology", draft_token)

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
         glossary_back_path: maybe_with_draft_param("/#{handle}/-/terminology", draft_token)
       )
       |> push_patch(to: glossary_draft_path)}
    end
  end

  defp handle_voice_select(field, params, socket) do
    if not (socket.assigns[:can_voice_submit?] || false) do
      {:noreply, socket}
    else
      case noora_select_value(params) do
        nil ->
          {:noreply, socket}

        value ->
          form_params =
            socket
            |> voice_form_params_with_current_values()
            |> Map.put(field, value)

          base_changed? =
            form_changed?(
              form_params,
              socket.assigns.original_voice,
              socket.assigns.original_overrides
            )

          countries_changed? =
            voice_countries_changed?(
              socket.assigns.target_countries,
              socket.assigns.cultural_notes,
              socket.assigns.original_voice
            )

          changed? = base_changed? or countries_changed?

          socket =
            socket
            |> assign(changed?: changed?, voice_form_params: form_params)
            |> then(fn socket ->
              if changed? do
                schedule_summary_generation(socket, :voice)
              else
                cancel_summary_generation(socket)
              end
            end)

          {:noreply, socket}
      end
    end
  end

  defp handle_voice_override_select(idx, field, params, socket) do
    if not (socket.assigns[:can_voice_submit?] || false) do
      {:noreply, socket}
    else
      case noora_select_value(params) do
        nil ->
          {:noreply, socket}

        value ->
          idx_int = String.to_integer(idx)
          value = normalize_noora_empty_value(value)

          overrides =
            List.update_at(socket.assigns.overrides || [], idx_int, fn override ->
              Map.put(override, field, value)
            end)

          form_params =
            socket
            |> voice_form_params_with_current_values()
            |> put_voice_override_form_param(idx, Atom.to_string(field), value)

          base_changed? =
            form_changed?(
              form_params,
              socket.assigns.original_voice,
              socket.assigns.original_overrides
            )

          countries_changed? =
            voice_countries_changed?(
              socket.assigns.target_countries,
              socket.assigns.cultural_notes,
              socket.assigns.original_voice
            )

          changed? = base_changed? or countries_changed?

          socket =
            socket
            |> assign(overrides: overrides, changed?: changed?, voice_form_params: form_params)
            |> then(fn socket ->
              if changed? do
                schedule_summary_generation(socket, :voice)
              else
                cancel_summary_generation(socket)
              end
            end)

          {:noreply, socket}
      end
    end
  end

  defp handle_glossary_entry_select(idx, :case_sensitive, params, socket) do
    if not (socket.assigns[:can_glossary_submit?] || false) do
      {:noreply, socket}
    else
      case noora_select_value(params) do
        nil ->
          {:noreply, socket}

        value ->
          idx_int = String.to_integer(idx)
          selected? = value == "true"

          entries =
            List.update_at(socket.assigns.glossary_entries || [], idx_int, fn entry ->
              Map.put(entry, :case_sensitive, selected?)
            end)

          form_params =
            socket
            |> glossary_form_params_with_current_values()
            |> put_glossary_entry_form_param(idx, "case_sensitive", value)

          glossary_select_response(entries, form_params, socket)
      end
    end
  end

  defp handle_glossary_translation_select(entry_idx, translation_idx, :locale, params, socket) do
    if not (socket.assigns[:can_glossary_submit?] || false) do
      {:noreply, socket}
    else
      case noora_select_value(params) do
        nil ->
          {:noreply, socket}

        value ->
          entry_idx_int = String.to_integer(entry_idx)
          translation_idx_int = String.to_integer(translation_idx)

          entries =
            List.update_at(socket.assigns.glossary_entries || [], entry_idx_int, fn entry ->
              translations =
                entry
                |> map_get(:translations, [])
                |> List.wrap()
                |> List.update_at(translation_idx_int, fn translation ->
                  Map.put(translation, :locale, value)
                end)

              Map.put(entry, :translations, translations)
            end)

          form_params =
            socket
            |> glossary_form_params_with_current_values()
            |> put_glossary_translation_form_param(entry_idx, translation_idx, "locale", value)

          glossary_select_response(entries, form_params, socket)
      end
    end
  end

  defp glossary_select_response(entries, form_params, socket) do
    changed? =
      glossary_entries_index(entries) !=
        glossary_entries_index(socket.assigns.original_glossary_entries)

    socket =
      socket
      |> assign(
        glossary_entries: entries,
        glossary_changed?: changed?,
        glossary_form_params: form_params
      )
      |> then(fn socket ->
        if changed? do
          schedule_summary_generation(socket, :glossary)
        else
          cancel_summary_generation(socket)
        end
      end)

    {:noreply, socket}
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

  defp voice_current_value(params, voice, field) do
    Map.get(params || %{}, field, voice_original_value(voice, field))
  end

  defp voice_form_params_with_current_values(socket) do
    voice = socket.assigns[:voice] || socket.assigns[:original_voice]
    params = socket.assigns[:voice_form_params] || %{}

    defaults = %{
      "description" => voice_original_value(voice, "description"),
      "tone" => voice_original_value(voice, "tone"),
      "formality" => voice_original_value(voice, "formality"),
      "target_audience" => voice_original_value(voice, "target_audience"),
      "guidelines" => voice_original_value(voice, "guidelines"),
      "overrides" => voice_overrides_form_params(socket.assigns[:overrides] || [])
    }

    Map.merge(defaults, params)
  end

  defp voice_overrides_form_params(overrides) do
    overrides
    |> Enum.with_index()
    |> Map.new(fn {override, idx} ->
      {to_string(idx),
       %{
         "locale" => voice_override_value(override, :locale),
         "tone" => voice_override_value(override, :tone),
         "formality" => voice_override_value(override, :formality),
         "target_audience" => voice_override_value(override, :target_audience),
         "guidelines" => voice_override_value(override, :guidelines)
       }}
    end)
  end

  defp voice_override_value(override, field) do
    normalize_noora_empty_value(
      Map.get(override, field) || Map.get(override, Atom.to_string(field)) || ""
    )
  end

  defp voice_override_select_value(override, field) do
    case voice_override_value(override, field) do
      "" -> "__base__"
      value -> value
    end
  end

  defp put_voice_override_form_param(form_params, idx, field, value) do
    overrides = Map.get(form_params, "overrides", %{})
    override = Map.get(overrides, idx, %{})

    Map.put(
      form_params,
      "overrides",
      Map.put(overrides, idx, Map.put(override, field, value || ""))
    )
  end

  defp glossary_form_params_with_current_values(socket) do
    defaults = %{
      "entries" => glossary_entries_form_params(socket.assigns[:glossary_entries] || [])
    }

    Map.merge(defaults, socket.assigns[:glossary_form_params] || %{})
  end

  defp glossary_entries_form_params(entries) do
    entries
    |> Enum.with_index()
    |> Map.new(fn {entry, idx} ->
      {to_string(idx),
       %{
         "term" => glossary_entry_value(entry, :term),
         "definition" => glossary_entry_value(entry, :definition),
         "case_sensitive" => glossary_case_sensitive_value(entry),
         "translations" => glossary_translations_form_params(map_get(entry, :translations, []))
       }}
    end)
  end

  defp glossary_translations_form_params(translations) do
    translations
    |> List.wrap()
    |> Enum.with_index()
    |> Map.new(fn {translation, idx} ->
      {to_string(idx),
       %{
         "locale" => glossary_translation_value(translation, :locale),
         "translation" => glossary_translation_value(translation, :translation)
       }}
    end)
  end

  defp glossary_entry_value(entry, field), do: map_get(entry, field, "") || ""

  defp glossary_case_sensitive_value(entry) do
    if map_get(entry, :case_sensitive, false), do: "true", else: "false"
  end

  defp glossary_translation_value(translation, field), do: map_get(translation, field, "") || ""

  defp terminology_table_rows(entries) do
    entries
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.map(fn {entry, index} ->
      %{id: "terminology-term-#{index}", entry: entry, index: index}
    end)
  end

  defp terminology_version_table_rows(glossary, previous_glossary) do
    current_entries = List.wrap(glossary && glossary.entries)
    previous_entries = List.wrap(previous_glossary && previous_glossary.entries)

    current_by_term = glossary_entries_term_map(current_entries)
    previous_by_term = glossary_entries_term_map(previous_entries)

    current_by_term
    |> Map.keys()
    |> Kernel.++(Map.keys(previous_by_term))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(fn term ->
      current = Map.get(current_by_term, term)
      previous = Map.get(previous_by_term, term)
      status = glossary_version_entry_status(current, previous)

      %{
        term: term,
        entry: current || previous || %{},
        status: status
      }
    end)
  end

  defp terminology_term_label(entry) do
    entry
    |> glossary_entry_value(:term)
    |> case do
      "" -> gettext("New term")
      term -> term
    end
  end

  defp terminology_translations_summary(entry) do
    translations =
      entry
      |> map_get(:translations, [])
      |> List.wrap()
      |> Enum.reject(fn translation ->
        glossary_translation_value(translation, :locale) == "" and
          glossary_translation_value(translation, :translation) == ""
      end)

    case translations do
      [] ->
        gettext("No translations")

      translations ->
        preview =
          translations
          |> Enum.take(3)
          |> Enum.map(fn translation ->
            locale = glossary_translation_value(translation, :locale)
            value = glossary_translation_value(translation, :translation)

            if locale == "" do
              value
            else
              "#{locale}: #{value}"
            end
          end)
          |> Enum.join(", ")

        if length(translations) > 3 do
          preview <> ", ..."
        else
          preview
        end
    end
  end

  defp put_glossary_entry_form_param(form_params, idx, field, value) do
    entries = Map.get(form_params, "entries", %{})
    entry = Map.get(entries, idx, %{})

    Map.put(
      form_params,
      "entries",
      Map.put(entries, idx, Map.put(entry, field, value || ""))
    )
  end

  defp put_glossary_translation_form_param(form_params, entry_idx, translation_idx, field, value) do
    entries = Map.get(form_params, "entries", %{})
    entry = Map.get(entries, entry_idx, %{})
    translations = Map.get(entry, "translations", %{})
    translation = Map.get(translations, translation_idx, %{})

    entry =
      Map.put(
        entry,
        "translations",
        Map.put(translations, translation_idx, Map.put(translation, field, value || ""))
      )

    Map.put(form_params, "entries", Map.put(entries, entry_idx, entry))
  end

  defp noora_select_value(%{"value" => [value | _]}), do: value
  defp noora_select_value(%{"value" => value}) when is_binary(value), do: value
  defp noora_select_value(%{"data" => value}) when is_binary(value), do: value
  defp noora_select_value(_params), do: nil

  defp normalize_noora_empty_value("__base__"), do: ""
  defp normalize_noora_empty_value(value), do: value

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
    {o["locale"], normalize_noora_empty_value(o["tone"] || ""),
     normalize_noora_empty_value(o["formality"] || ""), o["target_audience"] || "",
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

    case Discussions.create_discussion(account, user, attrs, via: :dashboard) do
      {:ok, ticket} ->
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
           gettext("Voice suggestion submitted as suggestion #%{number}.", number: ticket.number)
         )
         |> push_patch(to: suggestion_path(handle, ticket))}

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
          else: suggestion_title(gettext("Terminology"), change_note)
        ),
      body:
        if(suggestion_body_text != "",
          do: suggestion_body_text,
          else: suggestion_body(gettext("terminology"), change_note)
        ),
      kind: "glossary_suggestion",
      metadata: %{
        "resource" => "glossary",
        "change_note" => change_note,
        "base_version" => base_version,
        "payload" => payload
      }
    }

    case Discussions.create_discussion(account, user, attrs, via: :dashboard) do
      {:ok, ticket} ->
        {:noreply,
         socket
         |> assign(
           glossary_suggestion_draft: nil,
           glossary_draft_token: nil,
           pending_glossary_suggestion_redirect: false,
           glossary_back_path: "/#{handle}/-/terminology"
         )
         |> put_flash(
           :info,
           gettext("Terminology suggestion submitted as suggestion #%{number}.",
             number: ticket.number
           )
         )
         |> push_patch(to: suggestion_path(handle, ticket))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit terminology suggestion."))}
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
      true -> gettext("Terminology suggestion")
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
          tone: non_empty(normalize_noora_empty_value(o["tone"] || "")),
          formality: non_empty(normalize_noora_empty_value(o["formality"] || "")),
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
      "Proposed %{resource} update.\n\nChange note: %{note}\n\nUse the suggestion action to apply this when ready.",
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

  defp apply_voice_suggestion(ticket, account, user, _handle) do
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
            :ok =
              Discussions.mark_suggestion_applied(ticket, user, :voice, voice.version,
                via: :dashboard
              )

            {:ok,
             gettext("Applied voice suggestion as version #%{version}.", version: voice.version)}

          {:error, _step, _changeset, _changes} ->
            {:error, :invalid_payload}
        end
      end
    end
  end

  defp apply_glossary_suggestion(ticket, account, user, _handle) do
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
            :ok =
              Discussions.mark_suggestion_applied(
                ticket,
                user,
                :glossary,
                glossary.version,
                via: :dashboard
              )

            {:ok,
             gettext("Applied terminology suggestion as version #%{version}.",
               version: glossary.version
             )}

          {:error, _step, _changeset, _changes} ->
            {:error, :invalid_payload}
        end
      end
    end
  end

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

  defp settings_available_filters(:tokens) do
    [
      %Filter.Filter{
        id: "name",
        field: :name,
        display_name: gettext("Name"),
        type: :text,
        operator: :=~,
        value: ""
      }
    ]
  end

  defp settings_available_filters(:oauth_apps) do
    [
      %Filter.Filter{
        id: "name",
        field: :name,
        display_name: gettext("Name"),
        type: :text,
        operator: :=~,
        value: ""
      }
    ]
  end

  defp settings_available_filters(:llm_models) do
    [
      %Filter.Filter{
        id: "handle",
        field: :handle,
        display_name: gettext("Handle"),
        type: :text,
        operator: :=~,
        value: ""
      },
      %Filter.Filter{
        id: "model",
        field: :model,
        display_name: gettext("Model"),
        type: :text,
        operator: :=~,
        value: ""
      }
    ]
  end

  defp translation_available_filters do
    [
      %Filter.Filter{
        id: "status",
        field: :status,
        display_name: gettext("Status"),
        type: :option,
        options: ["pending", "running", "completed", "failed"],
        options_display_names: %{
          "pending" => gettext("Pending"),
          "running" => gettext("Running"),
          "completed" => gettext("Completed"),
          "failed" => gettext("Failed")
        },
        operator: :==,
        value: nil
      }
    ]
  end

  defp add_noora_flop_filters(params, []), do: params

  defp add_noora_flop_filters(params, filters) do
    Map.update(params, "filters", filters, &(&1 ++ filters))
  end

  defp settings_decoded_query(socket), do: socket.assigns[:settings_query_params] || %{}

  defp settings_filter_path(socket, params) do
    path = socket.assigns[:settings_filter_path] || "/" <> socket.assigns.handle

    if map_size(params) == 0 do
      path
    else
      path <> "?" <> URI.encode_query(params)
    end
  end

  # Table ID -> param prefix mapping
  @table_prefixes %{
    "projects-table" => "p",
    "members-table" => "m",
    "invitations-table" => "i",
    "tokens-table" => "t",
    "oauth-apps-table" => "a",
    "translations-table" => "ts",
    "commits-table" => "c",
    "models" => "md"
  }

  defp settings_sort_patch(
         handle,
         path,
         table_id,
         search,
         current_sort_key,
         current_sort_dir,
         sort_key,
         active_filters
       ) do
    sort_dir =
      if current_sort_key == sort_key and current_sort_dir == "asc",
        do: "desc",
        else: "asc"

    settings_table_patch(handle, path, table_id, search, sort_key, sort_dir, active_filters)
  end

  defp settings_table_patch(
         handle,
         path,
         table_id,
         search,
         sort_key,
         sort_dir,
         active_filters
       ) do
    prefix = Map.fetch!(@table_prefixes, table_id)

    query_params =
      []
      |> maybe_add_param(prefix <> "q", search, "")
      |> maybe_add_param(prefix <> "sort", sort_key, default_sort_key(table_id))
      |> maybe_add_param(prefix <> "dir", sort_dir, default_sort_dir(table_id))
      |> Map.new()
      |> Map.merge(Filter.Operations.encode_filters_to_query(active_filters))

    path = "/" <> handle <> path

    if map_size(query_params) == 0 do
      path
    else
      path <> "?" <> URI.encode_query(query_params)
    end
  end

  defp project_activity_sort_patch(
         handle,
         project_handle,
         search,
         current_sort_key,
         current_sort_dir,
         sort_key
       ) do
    sort_dir =
      if current_sort_key == sort_key and current_sort_dir == "asc",
        do: "desc",
        else: "asc"

    settings_table_patch(
      handle,
      "/" <> project_handle,
      "commits-table",
      search,
      sort_key,
      sort_dir,
      []
    )
  end

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
      if action in [:project, :project_translations],
        do: socket.assigns.project.handle,
        else: nil

    path =
      case action do
        :members -> "/#{handle}/-/members"
        :api_tokens -> "/#{handle}/-/settings/tokens"
        :api_apps -> "/#{handle}/-/settings/apps"
        :llm_models -> "/#{handle}/-/settings/models"
        :project -> "/#{handle}/#{project_handle}"
        :project_translations -> "/#{handle}/#{project_handle}/-/translations"
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

  defp add_filter_params(params, _prefix, filters) when is_list(filters) do
    params ++ Enum.into(Filter.Operations.encode_filters_to_query(filters), [])
  end

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
      filters: socket.assigns[:translations_active_filters] || []
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

  defp current_table_state(socket, "models") do
    %{
      search: socket.assigns[:models_search] || "",
      sort: socket.assigns[:models_sort_key] || "handle",
      dir: socket.assigns[:models_sort_dir] || "asc",
      page: 1,
      filters: %{}
    }
  end

  defp current_table_state(_socket, _id),
    do: %{search: "", sort: "", dir: "asc", page: 1, filters: %{}}

  defp default_sort_key("commits-table"), do: "date"
  defp default_sort_key("projects-table"), do: "name"
  defp default_sort_key("members-table"), do: "name"
  defp default_sort_key("invitations-table"), do: "email"
  defp default_sort_key("tokens-table"), do: "name"
  defp default_sort_key("oauth-apps-table"), do: "name"
  defp default_sort_key("translations-table"), do: "inserted_at"
  defp default_sort_key("models"), do: "handle"
  defp default_sort_key(_), do: ""

  defp default_sort_dir("translations-table"), do: "desc"
  defp default_sort_dir("commits-table"), do: "desc"
  defp default_sort_dir(_), do: "asc"

  defp current_sort(socket, "members-table"),
    do: {socket.assigns.members_sort_key, socket.assigns.members_sort_dir}

  defp current_sort(socket, "invitations-table"),
    do: {socket.assigns.invitations_sort_key, socket.assigns.invitations_sort_dir}

  defp current_sort(socket, "tokens-table"),
    do: {socket.assigns[:tokens_sort_key] || "name", socket.assigns[:tokens_sort_dir] || "asc"}

  defp current_sort(socket, "oauth-apps-table"),
    do: {socket.assigns[:apps_sort_key] || "name", socket.assigns[:apps_sort_dir] || "asc"}

  defp current_sort(socket, "projects-table"),
    do:
      {socket.assigns[:projects_sort_key] || "name", socket.assigns[:projects_sort_dir] || "asc"}

  defp current_sort(socket, "translations-table"),
    do:
      {socket.assigns[:translations_sort_key] || "inserted_at",
       socket.assigns[:translations_sort_dir] || "desc"}

  defp current_sort(socket, "commits-table"),
    do: {socket.assigns[:commits_sort_key] || "date", socket.assigns[:commits_sort_dir] || "desc"}

  defp current_sort(socket, "models"),
    do: {socket.assigns[:models_sort_key] || "handle", socket.assigns[:models_sort_dir] || "asc"}

  defp current_sort(_socket, _), do: {"", "asc"}

  defp current_filters(socket, "members-table"), do: socket.assigns.members_filters

  defp current_filters(socket, "translations-table"),
    do: socket.assigns[:translations_active_filters] || []

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
    handle = socket.assigns.handle
    search = Map.get(params, prefix <> "q", "")
    sort_key = Map.get(params, prefix <> "sort", "inserted_at")
    sort_dir = Map.get(params, prefix <> "dir", "desc")
    page = parse_int(Map.get(params, prefix <> "page"), 1)
    available_filters = translation_available_filters()
    active_filters = Filter.Operations.decode_filters_from_query(params, available_filters)

    order_dir = if sort_dir == "desc", do: :desc, else: :asc
    order_by = if sort_key == "status", do: :status, else: :inserted_at

    flop_params =
      %{
        "page" => page,
        "page_size" => 25,
        "order_by" => [Atom.to_string(order_by)],
        "order_directions" => [Atom.to_string(order_dir)]
      }
      |> maybe_add_flop_filters(
        if(search == "", do: %{}, else: %{"commit_sha" => search}),
        %{"commit_sha" => "text"}
      )
      |> add_noora_flop_filters(Filter.Operations.convert_filters_to_flop(active_filters))

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
      translations_active_filters: active_filters,
      available_filters: available_filters,
      active_filters: active_filters,
      settings_query_params: params,
      settings_filter_path: "/" <> handle <> "/" <> project.handle <> "/-/translations"
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
              subscribe_to_setup_events(socket, project)
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

  defp subscribe_to_setup_events(socket, project) do
    project_id = to_string(project.id)

    if socket.assigns[:setup_events_project_id] == project_id do
      socket
    else
      Glossia.Projects.subscribe_setup_events(project)
      assign(socket, setup_events_project_id: project_id)
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
          glossary_back_path: maybe_with_draft_param("/#{handle}/-/terminology", token)
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
              glossary_back_path:
                maybe_with_draft_param("/#{handle}/-/terminology", fallback_token)
            )

          _ ->
            assign(socket,
              glossary_draft_token: nil,
              glossary_back_path: "/#{handle}/-/terminology"
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
  # Page: Suggestion detail
  # ---------------------------------------------------------------------------

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
                  {ticket_close_label(@ticket)}
                </button>
              <% end %>
            <% else %>
              <%= if @can_write do %>
                <button phx-click="reopen_discussion" class="dash-btn dash-btn-secondary">
                  {ticket_reopen_label(@ticket)}
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
            <.link patch={ticket_back_path(@handle, @ticket)} class="dash-btn dash-btn-secondary">
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
  defp ticket_kind_label("glossary_suggestion"), do: gettext("Terminology suggestion")
  defp ticket_kind_label("general"), do: gettext("General")
  defp ticket_kind_label(other), do: other

  defp ticket_close_label(%{kind: kind}) when kind in ["voice_suggestion", "glossary_suggestion"],
    do: gettext("Close suggestion")

  defp ticket_close_label(_ticket), do: gettext("Close")

  defp ticket_reopen_label(%{kind: kind})
       when kind in ["voice_suggestion", "glossary_suggestion"],
       do: gettext("Reopen suggestion")

  defp ticket_reopen_label(_ticket), do: gettext("Reopen")

  defp ticket_back_path(handle, %{kind: "voice_suggestion"}), do: "/#{handle}/-/voice"
  defp ticket_back_path(handle, %{kind: "glossary_suggestion"}), do: "/#{handle}/-/terminology"
  defp ticket_back_path(handle, _ticket), do: "/#{handle}"

  defp suggestion_path(handle, ticket), do: "/#{handle}/-/suggestions/#{ticket.number}"

  defp can_apply_suggestion?(ticket, can_voice_write, can_glossary_write) do
    ticket.status == "open" and
      ((ticket.kind == "voice_suggestion" and can_voice_write) or
         (ticket.kind == "glossary_suggestion" and can_glossary_write))
  end

  defp render_markdown(nil), do: ""
  defp render_markdown(""), do: ""

  defp render_markdown(text) do
    Glossia.Markdown.to_html!(text)
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
          {:ok, "/#{s3_path}"}
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

  @upload_extensions ~w(gif jpeg jpg png webp)

  defp upload_entry_extension(entry) do
    ext =
      entry.client_name
      |> Path.extname()
      |> String.trim_leading(".")
      |> String.downcase()

    if ext in @upload_extensions do
      ext
    else
      case entry.client_type do
        "image/jpeg" -> "jpg"
        "image/png" -> "png"
        "image/gif" -> "gif"
        "image/webp" -> "webp"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # LLM models page component
  # ---------------------------------------------------------------------------

  @model_picker_result_limit 50

  defp model_picker_options do
    Glossia.Accounts.LLMModel.available_models()
    |> Enum.flat_map(fn {provider_name, models} ->
      Enum.map(models, fn {label, value} ->
        ["#{provider_name} - #{label}", value]
      end)
    end)
    |> Enum.sort_by(fn [label, _value] -> String.downcase(label) end)
  end

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :string, default: "")
  attr(:options_json, :string, required: true)
  attr(:option_count, :integer, required: true)
  attr(:selected_label, :string, default: nil)
  attr(:hint, :string, default: nil)

  defp model_picker(assigns) do
    assigns = assign(assigns, :result_limit, @model_picker_result_limit)

    ~H"""
    <div
      id={@id}
      class="noora-dropdown model-picker"
      data-size="large"
      data-value={@value || ""}
      data-name={@name}
      data-options={@options_json}
      data-option-count={@option_count}
      data-placeholder={gettext("Select a model...")}
      data-search-placeholder={gettext("Search models...")}
      data-empty-label={gettext("No models found.")}
      data-result-summary={
        gettext("Showing the first %{limit} matches. Keep typing to narrow the results.",
          limit: @result_limit
        )
      }
      data-result-limit={@result_limit}
      phx-hook="ModelPicker"
      phx-update="ignore"
    >
      <input data-part="value" type="hidden" name={@name} value={@value || ""} />
      <button
        id={@id <> "-trigger"}
        type="button"
        data-part="trigger"
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={@id <> "-items"}
      >
        <div data-part="label-wrapper">
          <span data-part="label">{@selected_label || gettext("Select a model...")}</span>
        </div>
        <div data-part="indicator">
          <div data-part="indicator-down"><Noora.Icon.chevron_down /></div>
          <div data-part="indicator-up"><Noora.Icon.chevron_up /></div>
        </div>
      </button>
      <div data-part="positioner">
        <div class="noora-dropdown-content" data-part="content">
          <div data-part="search">
            <Noora.TextInput.text_input
              id={@id <> "-search"}
              name=""
              type="search"
              show_suffix={false}
              placeholder={gettext("Search models...")}
              aria-label={gettext("Search models")}
              aria-autocomplete="list"
              aria-controls={@id <> "-items"}
              aria-expanded="false"
              data-part="search-input"
            />
          </div>
          <div
            id={@id <> "-items"}
            data-part="items"
            role="listbox"
            aria-labelledby={@id <> "-trigger"}
          >
          </div>
        </div>
      </div>
      <span :if={@hint} data-part="hint">
        <Noora.Icon.info_circle />
        <span>{@hint}</span>
      </span>
      <template data-part="option-icon-template"><Noora.Icon.schema /></template>
      <template data-part="selected-icon-template"><Noora.Icon.check /></template>
    </div>
    """
  end

  attr(:live_action, :atom, required: true)
  attr(:handle, :string, required: true)
  attr(:llm_models, :list, default: [])
  attr(:model_form, :any, default: nil)
  attr(:model_form_valid?, :boolean, default: false)
  attr(:models_search, :string, default: "")
  attr(:models_sort_key, :string, default: "handle")
  attr(:models_sort_dir, :string, default: "asc")
  attr(:editing_model, :any, default: nil)
  attr(:model_edit_form, :any, default: nil)
  attr(:model_edit_changed?, :boolean, default: false)
  attr(:model_picker_options_json, :string, default: "[]")
  attr(:model_picker_option_count, :integer, default: 0)
  attr(:model_picker_selected_label, :string, default: nil)
  attr(:available_filters, :list, default: [])
  attr(:active_filters, :list, default: [])

  defp llm_models_page(assigns) do
    ~H"""
    <div class="dash-page">
      <%= cond do %>
        <% @live_action == :llm_model_new -> %>
          <.page_header title={gettext("New model")} />

          <.form
            for={@model_form}
            id="model-form"
            class="voice-form"
            phx-submit="create_model"
            phx-change="validate_model"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Model configuration")}</h2>
                <p>
                  {gettext(
                    "Add a named model configuration. Each translation uses one model handle from the nearest applicable GLOSSIA.md file, or the account default when no handle is set."
                  )}
                </p>
              </div>
              <Noora.Card.card_section class="voice-card">
                <div class="voice-card-fields">
                  <Noora.TextInput.text_input
                    id="model-handle"
                    field={@model_form[:handle]}
                    error={model_field_error(@model_form[:handle])}
                    label={gettext("Handle")}
                    placeholder={gettext("e.g. my-claude-model")}
                    hint={
                      gettext(
                        "Use lowercase letters, numbers, and hyphens. Reference this handle from GLOSSIA.md to choose the model for a content scope."
                      )
                    }
                    autocapitalize="none"
                    spellcheck="false"
                    required
                    show_required
                  />
                  <div class="voice-field model-select">
                    <Noora.Label.label label={gettext("Model")} required />
                    <.model_picker
                      id="model-model"
                      name="model[model]"
                      value={@model_form[:model].value}
                      options_json={@model_picker_options_json}
                      option_count={@model_picker_option_count}
                      hint={gettext("The model to use, sourced from models.dev.")}
                    />
                  </div>
                  <Noora.TextInput.text_input
                    id="model-api-key"
                    field={@model_form[:api_key]}
                    error={model_field_error(@model_form[:api_key])}
                    type="password"
                    label={gettext("API key")}
                    placeholder={gettext("sk-...")}
                    hint={gettext("Your provider API key. This will be encrypted at rest.")}
                    required
                    show_required
                  />
                </div>
              </Noora.Card.card_section>
            </div>

            <.form_save_bar
              id="model-save-bar"
              visible={@model_form_valid?}
              cancel_path={~p"/#{@handle}/-/settings/models"}
            />
          </.form>
        <% @live_action == :llm_model_edit -> %>
          <.page_header title={@editing_model.handle} />

          <.form
            for={@model_edit_form}
            id="model-edit-form"
            class="voice-form"
            phx-submit="update_model"
            phx-change="validate_model_edit"
          >
            <div class="voice-section">
              <div class="voice-section-info">
                <h2>{gettext("Model configuration")}</h2>
              </div>
              <Noora.Card.card_section class="voice-card">
                <div class="voice-card-fields">
                  <Noora.TextInput.text_input
                    id="edit-model-handle"
                    field={@model_edit_form[:handle]}
                    error={model_field_error(@model_edit_form[:handle])}
                    label={gettext("Handle")}
                    hint={gettext("Use lowercase letters, numbers, and hyphens.")}
                    autocapitalize="none"
                    spellcheck="false"
                    required
                    show_required
                  />
                  <div class="voice-field model-select">
                    <Noora.Label.label label={gettext("Model")} required />
                    <.model_picker
                      id="edit-model-model"
                      name="model[model]"
                      value={@model_edit_form[:model].value}
                      options_json={@model_picker_options_json}
                      option_count={@model_picker_option_count}
                      selected_label={@model_picker_selected_label}
                    />
                  </div>
                  <Noora.TextInput.text_input
                    id="edit-model-api-key"
                    field={@model_edit_form[:api_key]}
                    error={model_field_error(@model_edit_form[:api_key])}
                    type="password"
                    label={gettext("API key")}
                    placeholder={gettext("Leave blank to keep current key")}
                  />
                </div>
              </Noora.Card.card_section>
            </div>

            <div class="voice-section-divider"></div>

            <div class="api-action-section">
              <div class="api-action-info">
                <h2>{gettext("Account default")}</h2>
                <p>
                  <%= if @editing_model.default do %>
                    {gettext(
                      "This model is used for project setup and translations whose GLOSSIA.md configuration does not name a model handle."
                    )}
                  <% else %>
                    {gettext(
                      "Make this the fallback for project setup and translations whose GLOSSIA.md configuration does not name a model handle."
                    )}
                  <% end %>
                </p>
              </div>
              <Noora.Badge.badge
                :if={@editing_model.default}
                label={gettext("Default")}
                color="primary"
                style="light-fill"
              />
              <Noora.Button.button
                :if={not @editing_model.default}
                type="button"
                label={gettext("Make default")}
                variant="secondary"
                size="medium"
                phx-click="set_default_model"
                phx-value-id={@editing_model.id}
              />
            </div>

            <div class="voice-section-divider"></div>

            <div class="api-action-section api-action-danger">
              <div class="api-action-info">
                <h2>{gettext("Delete model")}</h2>
                <p>
                  {gettext("Permanently remove this model configuration. This cannot be undone.")}
                </p>
              </div>
              <Noora.Button.button
                type="button"
                label={gettext("Delete model")}
                variant="destructive"
                size="medium"
                phx-click="delete_model"
                phx-value-id={@editing_model.id}
                data-confirm={gettext("Are you sure you want to delete this model?")}
              />
            </div>

            <.form_save_bar
              id="model-edit-save-bar"
              visible={@model_edit_changed?}
              cancel_path={~p"/#{@handle}/-/settings/models"}
            />
          </.form>
        <% true -> %>
          <div class="noora-settings-list-page">
            <div data-part="page-header">
              <div data-part="heading">
                <h1 data-part="title">{gettext("Models")}</h1>
                <span data-part="subtitle">
                  {gettext(
                    "Each translation uses one configured model. GLOSSIA.md can select a handle for a content scope; work without a handle uses the account default."
                  )}
                </span>
              </div>
              <div data-part="actions">
                <Noora.Button.button
                  navigate={~p"/#{@handle}/-/settings/models/new"}
                  label={gettext("New model")}
                  variant="secondary"
                  size="medium"
                >
                  <:icon_left><Noora.Icon.plus /></:icon_left>
                </Noora.Button.button>
              </div>
            </div>

            <Noora.Card.card_section class="noora-settings-list-card">
              <div data-part="toolbar">
                <.settings_filter_controls
                  id="llm-models-filter-dropdown"
                  available_filters={@available_filters}
                  active_filters={@active_filters}
                />
              </div>

              <Noora.Table.table
                id="models"
                rows={@llm_models}
                row_key={fn model -> "llm-model-#{model.id}" end}
                row_navigate={fn model -> "/" <> @handle <> "/-/settings/models/" <> model.id end}
              >
                <:col
                  :let={model}
                  label={gettext("Handle")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/models",
                      "models",
                      @models_search,
                      @models_sort_key,
                      @models_sort_dir,
                      "handle",
                      @active_filters
                    )
                  }
                  sort_order={if(@models_sort_key == "handle", do: @models_sort_dir)}
                >
                  <Noora.Table.text_cell icon="api" label={model.handle} />
                </:col>
                <:col
                  :let={model}
                  label={gettext("Model")}
                  patch={
                    settings_sort_patch(
                      @handle,
                      "/-/settings/models",
                      "models",
                      @models_search,
                      @models_sort_key,
                      @models_sort_dir,
                      "model",
                      @active_filters
                    )
                  }
                  sort_order={if(@models_sort_key == "model", do: @models_sort_dir)}
                >
                  <Noora.Table.text_cell label={model.model} />
                </:col>
                <:col :let={model} label={gettext("Default")}>
                  <Noora.Badge.badge
                    :if={model.default}
                    label={gettext("Default")}
                    color="primary"
                    style="light-fill"
                  />
                </:col>
                <:empty_state>
                  <Noora.Table.table_empty_state>
                    <.noora_empty_state
                      icon="schema"
                      title={gettext("No models yet")}
                      subtitle={gettext("Models will show up here once you configure one.")}
                    />
                  </Noora.Table.table_empty_state>
                </:empty_state>
              </Noora.Table.table>
            </Noora.Card.card_section>
          </div>
      <% end %>
    </div>
    """
  end
end
