defmodule GlossiaWeb.DashboardLive do
  use GlossiaWeb, :live_view

  import GlossiaWeb.DashboardComponents

  alias Glossia.Accounts
  alias Glossia.Auditing
  alias Glossia.ChangeSummary
  alias Glossia.Glossaries
  alias Glossia.Organizations
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
        :logs -> apply_url_params_logs(socket, params)
        :members -> apply_url_params_members(socket, params)
        _ -> socket
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :account, _params) do
    assign(socket, page_title: socket.assigns.handle, projects: [])
  end

  defp apply_action(socket, :logs, _params) do
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
  end

  defp apply_action(socket, :voice, _params) do
    account = socket.assigns.account
    voice = Voices.get_latest_voice(account)
    {:ok, {versions, _meta}} = Voices.list_voice_versions(account)
    overrides = if voice, do: voice.overrides || [], else: []

    socket
    |> assign(
      page_title: gettext("Voice"),
      voice: voice,
      versions: versions,
      overrides: overrides,
      original_voice: voice,
      original_overrides: overrides,
      changed?: false,
      voice_form_params: %{},
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil
    )
  end

  defp apply_action(socket, :voice_version, %{"version" => version_str}) do
    account = socket.assigns.account
    version = String.to_integer(version_str)
    voice = Voices.get_voice_version(account, version)

    unless voice do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Voice
    end

    previous = Voices.get_previous_voice_version(account, version)

    assign(socket,
      page_title: gettext("Voice #%{version}", version: version),
      voice: voice,
      previous: previous
    )
  end

  defp apply_action(socket, :glossary, _params) do
    account = socket.assigns.account
    glossary = Glossaries.get_latest_glossary(account)
    {:ok, {versions, _meta}} = Glossaries.list_glossary_versions(account)
    entries = if glossary, do: glossary.entries || [], else: []

    socket
    |> assign(
      page_title: gettext("Glossary"),
      glossary: glossary,
      glossary_versions: versions,
      glossary_entries: entries,
      original_glossary: glossary,
      original_glossary_entries: entries,
      glossary_changed?: false,
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil
    )
  end

  defp apply_action(socket, :glossary_version, %{"version" => version_str}) do
    account = socket.assigns.account
    version = String.to_integer(version_str)
    glossary = Glossaries.get_glossary_version(account, version)

    unless glossary do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Glossary
    end

    previous = Glossaries.get_previous_glossary_version(account, version)

    assign(socket,
      page_title: gettext("Glossary #%{version}", version: version),
      glossary: glossary,
      previous_glossary: previous
    )
  end

  defp apply_action(socket, :members, _params) do
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
  end

  defp apply_action(socket, :project, %{"project" => project}) do
    assign(socket, page_title: project, project_name: project)
  end

  # ---------------------------------------------------------------------------
  # Voice form events
  # ---------------------------------------------------------------------------

  def handle_event("validate", params, socket) do
    changed? =
      form_changed?(params, socket.assigns.original_voice, socket.assigns.original_overrides)

    socket = assign(socket, changed?: changed?, voice_form_params: params)

    socket =
      if changed? do
        schedule_summary_generation(socket, :voice)
      else
        cancel_summary_generation(socket)
      end

    {:noreply, socket}
  end

  def handle_event("save_voice", params, socket) do
    change_note = String.trim(params["change_note"] || "")

    cond do
      !socket.assigns.can_write ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission to save."))}

      change_note == "" ->
        {:noreply, put_flash(socket, :error, gettext("A change note is required."))}

      true ->
        save_voice(params, change_note, socket)
    end
  end

  def handle_event("discard_changes", _params, socket) do
    socket = cancel_summary_generation(socket)

    {:noreply,
     assign(socket,
       overrides: socket.assigns.original_overrides,
       changed?: false,
       change_summary: "",
       generating_summary?: false
     )}
  end

  def handle_event("add_override", _params, socket) do
    new_override = %{locale: "", tone: nil, formality: nil, target_audience: nil, guidelines: nil}
    overrides = socket.assigns.overrides ++ [new_override]
    {:noreply, assign(socket, overrides: overrides, changed?: true)}
  end

  def handle_event("remove_override", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    overrides = List.delete_at(socket.assigns.overrides, idx)
    changed? = form_changed_overrides?(overrides, socket.assigns.original_overrides)
    {:noreply, assign(socket, overrides: overrides, changed?: changed?)}
  end

  # ---------------------------------------------------------------------------
  # Glossary events
  # ---------------------------------------------------------------------------

  def handle_event("save_glossary", params, socket) do
    change_note = String.trim(params["change_note"] || "")

    cond do
      !socket.assigns.can_write ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission to save."))}

      change_note == "" ->
        {:noreply, put_flash(socket, :error, gettext("A change note is required."))}

      true ->
        save_glossary(params, change_note, socket)
    end
  end

  def handle_event("glossary_validate", params, socket) do
    entries = parse_glossary_entries_from_params(params, socket.assigns.glossary_entries)

    socket =
      socket
      |> assign(glossary_entries: entries, glossary_changed?: true)
      |> schedule_summary_generation(:glossary)

    {:noreply, socket}
  end

  def handle_event("glossary_discard", _params, socket) do
    socket = cancel_summary_generation(socket)

    {:noreply,
     assign(socket,
       glossary_entries: socket.assigns.original_glossary_entries,
       glossary_changed?: false,
       change_summary: "",
       generating_summary?: false
     )}
  end

  def handle_event("add_glossary_entry", _params, socket) do
    new_entry = %{term: "", definition: nil, case_sensitive: false, translations: []}
    entries = socket.assigns.glossary_entries ++ [new_entry]
    {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
  end

  def handle_event("remove_glossary_entry", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    entries = List.delete_at(socket.assigns.glossary_entries, idx)
    {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
  end

  def handle_event(
        "add_glossary_translation",
        %{"entry-index" => entry_idx_str},
        socket
      ) do
    entry_idx = String.to_integer(entry_idx_str)
    entries = socket.assigns.glossary_entries

    entry = Enum.at(entries, entry_idx)
    translations = (entry.translations || []) ++ [%{locale: "", translation: ""}]
    updated_entry = Map.put(entry, :translations, translations)
    entries = List.replace_at(entries, entry_idx, updated_entry)

    {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
  end

  def handle_event(
        "remove_glossary_translation",
        %{"entry-index" => entry_idx_str, "translation-index" => t_idx_str},
        socket
      ) do
    entry_idx = String.to_integer(entry_idx_str)
    t_idx = String.to_integer(t_idx_str)
    entries = socket.assigns.glossary_entries

    entry = Enum.at(entries, entry_idx)
    translations = List.delete_at(entry.translations, t_idx)
    updated_entry = Map.put(entry, :translations, translations)
    entries = List.replace_at(entries, entry_idx, updated_entry)

    {:noreply, assign(socket, glossary_entries: entries, glossary_changed?: true)}
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
        %{"key" => key, "value" => "", "table_id" => table_id},
        socket
      ) do
    filters = current_filters(socket, table_id) |> Map.delete(key)
    {:noreply, push_table_params(socket, table_id, %{filters: filters, page: 1})}
  end

  def handle_event("resource_filter", %{"key" => key, "value" => val, "table_id" => tid}, socket) do
    filters = current_filters(socket, tid) |> Map.put(key, val)
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
  # LLM-generated change summary (throttled async)
  # ---------------------------------------------------------------------------

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

      {:noreply, assign(socket, generating_summary?: true, summary_task_ref: task.ref)}
    end
  end

  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    if ref == socket.assigns[:summary_task_ref] do
      case result do
        {:ok, summary} ->
          bar_id = save_bar_id(socket)

          {:noreply,
           socket
           |> assign(change_summary: summary, generating_summary?: false, summary_task_ref: nil)
           |> push_event("summary_generated:#{bar_id}", %{summary: summary})}

        {:error, _reason} ->
          {:noreply, assign(socket, generating_summary?: false, summary_task_ref: nil)}
      end
    else
      # Stale task result -- ignore
      {:noreply, socket}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  # ---------------------------------------------------------------------------
  # Render (dispatches to page components)
  # ---------------------------------------------------------------------------

  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :account -> %>
        <.account_page projects={@projects} handle={@handle} can_write={@can_write} />
      <% :logs -> %>
        <.logs_page
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
          versions={@versions}
          overrides={@overrides}
          handle={@handle}
          can_write={@can_write}
          changed?={@changed?}
        />
      <% :voice_version -> %>
        <.voice_version_page voice={@voice} previous={@previous} handle={@handle} />
      <% :glossary -> %>
        <.glossary_page
          glossary={@glossary}
          glossary_versions={@glossary_versions}
          glossary_entries={@glossary_entries}
          handle={@handle}
          can_write={@can_write}
          glossary_changed?={@glossary_changed?}
        />
      <% :glossary_version -> %>
        <.glossary_version_page
          glossary={@glossary}
          previous_glossary={@previous_glossary}
          handle={@handle}
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
      <% :project -> %>
        <.project_page project_name={@project_name} />
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
        title={gettext("Projects")}
        description={gettext("Content sources connected to this account.")}
      >
        <:actions>
          <%= if @can_write do %>
            <button class="dash-btn dash-btn-primary" disabled>{gettext("New project")}</button>
          <% end %>
        </:actions>
      </.page_header>

      <%= if @projects == [] do %>
        <div class="dash-empty-state">
          <svg
            width="48"
            height="48"
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
      <% else %>
        <div class="dash-project-list">
          <%= for project <- @projects do %>
            <.link patch={"/" <> @handle <> "/" <> project.name} class="dash-project-card">
              <h3>{project.name}</h3>
            </.link>
          <% end %>
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
          <%= if event.resource_path != "" do %>
            <a href={event.resource_path} class="activity-event-link">
              {event.summary}
            </a>
          <% else %>
            <span>{event.summary}</span>
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
              width="48"
              height="48"
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

  defp voice_page(assigns) do
    assigns =
      assigns
      |> Map.put(:tone_options, @tone_options)
      |> Map.put(:formality_options, @formality_options)

    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Voice")}
        description={gettext("Define the tone, formality, and style guidelines for your content.")}
      />

      <form phx-change="validate" phx-submit="save_voice" class="voice-form" id="voice-form">
        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("Tone and style")}</h2>
            <p>{gettext("Set the overall personality and formality level for your content.")}</p>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <div class="voice-field">
                <label for="voice_tone">{gettext("Tone")}</label>
                <select
                  id="voice_tone"
                  name="tone"
                  disabled={!@can_write}
                  phx-debounce="300"
                >
                  <option value="">{gettext("Select a tone")}</option>
                  <%= for opt <- @tone_options do %>
                    <option value={opt} selected={@voice && @voice.tone == opt}>
                      {opt |> String.capitalize()}
                    </option>
                  <% end %>
                </select>
                <span class="voice-field-help">
                  {gettext("The general character of your writing.")}
                </span>
              </div>
              <div class="voice-field">
                <label for="voice_formality">{gettext("Formality")}</label>
                <select
                  id="voice_formality"
                  name="formality"
                  disabled={!@can_write}
                  phx-debounce="300"
                >
                  <option value="">{gettext("Select a level")}</option>
                  <%= for opt <- @formality_options do %>
                    <option value={opt} selected={@voice && @voice.formality == opt}>
                      {opt |> String.replace("_", " ") |> String.capitalize()}
                    </option>
                  <% end %>
                </select>
                <span class="voice-field-help">
                  {gettext("How casual or formal the language should be.")}
                </span>
              </div>
              <div class="voice-field">
                <label for="voice_target_audience">{gettext("Target audience")}</label>
                <input
                  type="text"
                  id="voice_target_audience"
                  name="target_audience"
                  value={(@voice && @voice.target_audience) || ""}
                  placeholder={gettext("e.g. Developers, marketing teams, general public")}
                  disabled={!@can_write}
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
              <div class="voice-field">
                <label for="voice_guidelines">{gettext("Writing guidelines")}</label>
                <textarea
                  id="voice_guidelines"
                  name="guidelines"
                  rows="10"
                  placeholder={gettext("Write your brand voice guidelines here...")}
                  disabled={!@can_write}
                  phx-debounce="300"
                >{(@voice && @voice.guidelines) || ""}</textarea>
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
                <div class="voice-override-block" data-override-index={idx}>
                  <div class="voice-override-header">
                    <span class="voice-override-locale">
                      {if override.locale != "", do: override.locale, else: gettext("New override")}
                    </span>
                    <%= if @can_write do %>
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
                        <select name={"overrides[#{idx}][tone]"} disabled={!@can_write}>
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
                        <select name={"overrides[#{idx}][formality]"} disabled={!@can_write}>
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
                        disabled={!@can_write}
                        phx-debounce="300"
                      />
                    </div>
                    <div class="voice-field">
                      <label>{gettext("Guidelines")}</label>
                      <textarea
                        name={"overrides[#{idx}][guidelines]"}
                        rows="4"
                        disabled={!@can_write}
                        phx-debounce="300"
                      >{override.guidelines || ""}</textarea>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            <%= if @can_write do %>
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

        <%= if @versions != [] do %>
          <div class="voice-section-divider"></div>

          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Version history")}</h2>
              <p>{gettext("Previous versions of your voice configuration.")}</p>
            </div>
            <div class="voice-card">
              <table class="voice-history-table">
                <thead>
                  <tr>
                    <th>{gettext("Version")}</th>
                    <th>{gettext("Note")}</th>
                    <th>{gettext("Date")}</th>
                    <th>{gettext("By")}</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for v <- @versions do %>
                    <tr>
                      <td class="voice-history-version">
                        <.link
                          patch={"/" <> @handle <> "/voice/" <> to_string(v.version)}
                          class="voice-history-link"
                        >
                          {"##{v.version}"}
                        </.link>
                      </td>
                      <td class="voice-history-note">{v.change_note || "-"}</td>
                      <td class="voice-history-date">
                        <time datetime={DateTime.to_iso8601(v.inserted_at)}>
                          {Calendar.strftime(v.inserted_at, "%b %d, %Y %H:%M")}
                        </time>
                      </td>
                      <td class="voice-history-author">
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
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>

        <%= if @can_write do %>
          <.save_bar
            id="voice-save-bar"
            visible={@changed?}
            discard_event="discard_changes"
            change_summary={@change_summary}
            generating_summary?={@generating_summary?}
          />
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
          <.link patch={"/" <> @handle <> "/voice"} class="voice-back-link">
            <svg
              width="16"
              height="16"
              viewBox="0 0 20 20"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <polyline points="12 4 6 10 12 16" />
            </svg>
            {gettext("Voice")}
          </.link>
          <h1>
            <span>{"##{@voice.version}"}</span>
            <%= if @voice.change_note do %>
              <span class="voice-version-title-note">{@voice.change_note}</span>
            <% end %>
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
    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Glossary")}
        description={gettext("Approved terms and translations to keep your content consistent.")}
      />

      <form
        phx-change="glossary_validate"
        phx-submit="save_glossary"
        class="voice-form"
        id="glossary-form"
      >
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
                <div class="glossary-entry-block" data-entry-index={idx}>
                  <div class="voice-override-header">
                    <span class="voice-override-locale">
                      {if(entry.term != "" && entry.term, do: entry.term, else: gettext("New term"))}
                    </span>
                    <%= if @can_write do %>
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
                      <div class="voice-field">
                        <label>{gettext("Term")}</label>
                        <input
                          type="text"
                          name={"entries[#{idx}][term]"}
                          value={entry.term || ""}
                          placeholder={gettext("e.g. API, workspace, deploy")}
                          required
                          disabled={!@can_write}
                        />
                      </div>
                      <div class="voice-field">
                        <label>{gettext("Case sensitive")}</label>
                        <select
                          name={"entries[#{idx}][case_sensitive]"}
                          disabled={!@can_write}
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
                    <div class="voice-field">
                      <label>{gettext("Definition")}</label>
                      <input
                        type="text"
                        name={"entries[#{idx}][definition]"}
                        value={entry.definition || ""}
                        placeholder={gettext("Context or description (optional)")}
                        disabled={!@can_write}
                      />
                    </div>
                    <div class="glossary-translations-section">
                      <div class="glossary-translations-header">
                        <span class="voice-diff-label">{gettext("Translations")}</span>
                        <%= if @can_write do %>
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
                        <div class="glossary-translation-row">
                          <div class="voice-field">
                            <.locale_picker
                              id={"locale-picker-#{idx}-#{tidx}"}
                              name={"entries[#{idx}][translations][#{tidx}][locale]"}
                              value={translation.locale || ""}
                              disabled={!@can_write}
                            />
                          </div>
                          <div class="voice-field" style="flex: 1;">
                            <input
                              type="text"
                              name={"entries[#{idx}][translations][#{tidx}][translation]"}
                              value={translation.translation || ""}
                              placeholder={gettext("Translation")}
                              disabled={!@can_write}
                            />
                          </div>
                          <%= if @can_write do %>
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
            <%= if @can_write do %>
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

        <%= if @glossary_versions != [] do %>
          <div class="voice-section-divider"></div>

          <div class="voice-section">
            <div class="voice-section-info">
              <h2>{gettext("Version history")}</h2>
              <p>{gettext("Previous versions of your glossary.")}</p>
            </div>
            <div class="voice-card">
              <table class="voice-history-table">
                <thead>
                  <tr>
                    <th>{gettext("Version")}</th>
                    <th>{gettext("Note")}</th>
                    <th>{gettext("Date")}</th>
                    <th>{gettext("By")}</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for v <- @glossary_versions do %>
                    <tr>
                      <td class="voice-history-version">
                        <.link
                          patch={"/" <> @handle <> "/glossary/" <> to_string(v.version)}
                          class="voice-history-link"
                        >
                          {"##{v.version}"}
                        </.link>
                      </td>
                      <td class="voice-history-note">{v.change_note || "-"}</td>
                      <td class="voice-history-date">
                        <time datetime={DateTime.to_iso8601(v.inserted_at)}>
                          {Calendar.strftime(v.inserted_at, "%b %d, %Y %H:%M")}
                        </time>
                      </td>
                      <td class="voice-history-author">
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
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>

        <%= if @can_write do %>
          <.save_bar
            id="glossary-save-bar"
            visible={@glossary_changed?}
            discard_event="glossary_discard"
            change_summary={@change_summary}
            generating_summary?={@generating_summary?}
          />
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
          <.link patch={"/" <> @handle <> "/glossary"} class="voice-back-link">
            <svg
              width="16"
              height="16"
              viewBox="0 0 20 20"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <polyline points="12 4 6 10 12 16" />
            </svg>
            {gettext("Glossary")}
          </.link>
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
  # Page: Project
  # ---------------------------------------------------------------------------

  defp project_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.page_header title={@project_name} />

      <div class="dash-empty-state">
        <svg
          width="48"
          height="48"
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
        <p>{gettext("This is a placeholder for the project detail page.")}</p>
      </div>
    </div>
    """
  end

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

  defp format_field(nil, _formatter), do: "-"
  defp format_field(val, nil), do: val |> String.capitalize()
  defp format_field(val, fun), do: fun.(val)

  defp humanize_formality(val), do: val |> String.replace("_", " ") |> String.capitalize()

  defp gravatar_url(email, size \\ 24) do
    hash =
      :crypto.hash(:md5, String.downcase(String.trim(email)))
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=mp"
  end

  defp non_empty(""), do: nil
  defp non_empty(val), do: val

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

  defp form_changed?(_params, nil, _original_overrides), do: true

  defp form_changed?(params, original_voice, original_overrides) do
    base_changed? =
      params["tone"] != (original_voice.tone || "") or
        params["formality"] != (original_voice.formality || "") or
        params["target_audience"] != (original_voice.target_audience || "") or
        params["guidelines"] != (original_voice.guidelines || "")

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

  # ---------------------------------------------------------------------------
  # Save form helpers (extracted to avoid splitting handle_event clauses)

  defp save_voice(params, change_note, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle

    voice_attrs = %{
      tone: params["tone"],
      formality: params["formality"],
      target_audience: params["target_audience"],
      guidelines: params["guidelines"],
      change_note: change_note
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

    attrs = Map.put(voice_attrs, :overrides, overrides)

    case Voices.create_voice(account, attrs, user) do
      {:ok, %{voice: voice}} ->
        Auditing.record("voice.created", account, user,
          resource_type: "voice",
          resource_id: to_string(voice.version),
          resource_path: "/#{handle}/voice/#{voice.version}",
          summary: change_note
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Voice configuration saved."))
         |> push_patch(to: "/#{handle}/voice")}

      {:error, _step, _changeset, _changes} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to save voice configuration."))}
    end
  end

  defp save_glossary(params, change_note, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle

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

    attrs = %{
      change_note: change_note,
      entries: entries
    }

    case Glossaries.create_glossary(account, attrs, user) do
      {:ok, %{glossary: glossary}} ->
        Auditing.record("glossary.created", account, user,
          resource_type: "glossary",
          resource_id: to_string(glossary.version),
          resource_path: "/#{handle}/glossary/#{glossary.version}",
          summary: change_note
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Glossary saved."))
         |> push_patch(to: "/#{handle}/glossary")}

      {:error, _step, _changeset, _changes} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to save glossary."))}
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
    "activity-table" => "",
    "members-table" => "m",
    "invitations-table" => "i"
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

    path =
      case action do
        :logs -> "/#{handle}/logs"
        :members -> "/#{handle}/members"
        _ -> "/#{handle}"
      end

    url =
      if query_params == [] do
        path
      else
        path <> "?" <> URI.encode_query(query_params)
      end

    push_patch(socket, to: url)
  end

  defp maybe_add_param(params, _key, value, default) when value == default, do: params
  defp maybe_add_param(params, key, value, _default), do: params ++ [{key, to_string(value)}]

  defp add_filter_params(params, _prefix, filters) when map_size(filters) == 0, do: params

  defp add_filter_params(params, prefix, filters) do
    Enum.reduce(filters, params, fn {key, value}, acc ->
      if value == "", do: acc, else: acc ++ [{prefix <> "f_" <> key, value}]
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

  defp current_table_state(_socket, _id),
    do: %{search: "", sort: "", dir: "asc", page: 1, filters: %{}}

  defp default_sort_key("activity-table"), do: "date"
  defp default_sort_key("members-table"), do: "name"
  defp default_sort_key("invitations-table"), do: "email"
  defp default_sort_key(_), do: ""

  defp default_sort_dir("activity-table"), do: "desc"
  defp default_sort_dir(_), do: "asc"

  defp current_sort(socket, "activity-table"),
    do: {socket.assigns.events_sort_key, socket.assigns.events_sort_dir}

  defp current_sort(socket, "members-table"),
    do: {socket.assigns.members_sort_key, socket.assigns.members_sort_dir}

  defp current_sort(socket, "invitations-table"),
    do: {socket.assigns.invitations_sort_key, socket.assigns.invitations_sort_dir}

  defp current_sort(_socket, _), do: {"", "asc"}

  defp current_filters(socket, "activity-table"), do: socket.assigns.events_filters
  defp current_filters(socket, "members-table"), do: socket.assigns.members_filters
  defp current_filters(_socket, _), do: %{}

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

  defp extract_filters(params, prefix) do
    filter_prefix = prefix <> "f_"

    params
    |> Enum.filter(fn {k, v} -> String.starts_with?(k, filter_prefix) && v != "" end)
    |> Enum.into(%{}, fn {k, v} -> {String.replace_prefix(k, filter_prefix, ""), v} end)
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
        {"type", val} -> e.name == val
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
      nil -> members
      "" -> members
      role -> Enum.filter(members, &(&1.role == role))
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
end
