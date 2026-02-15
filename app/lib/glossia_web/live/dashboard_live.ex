defmodule GlossiaWeb.DashboardLive do
  use GlossiaWeb, :live_view

  import GlossiaWeb.DashboardComponents

  alias Glossia.Accounts
  alias Glossia.Auditing
  alias Glossia.ChangeSummary
  alias Glossia.DeveloperTokens
  alias Glossia.Glossaries
  alias Glossia.Organizations
  alias Glossia.Support
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
    target_countries = if voice, do: voice.target_countries || [], else: []
    cultural_notes = if voice, do: voice.cultural_notes || %{}, else: %{}

    socket
    |> assign(
      page_title: gettext("Voice"),
      voice: voice,
      versions: versions,
      overrides: overrides,
      original_voice: voice,
      original_overrides: overrides,
      target_countries: target_countries,
      cultural_notes: cultural_notes,
      changed?: false,
      voice_form_params: %{},
      change_summary: "",
      generating_summary?: false,
      summary_generation: 0,
      summary_timer_ref: nil,
      summary_task_ref: nil,
      context_generation: 0,
      context_timer_ref: nil,
      context_task_ref: nil,
      generating_contexts?: false
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

  defp apply_action(socket, :api_tokens, params) do
    require_admin!(socket)
    account = socket.assigns.account

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
      tokens_sort_dir: sort_dir
    )
  end

  defp apply_action(socket, :api_tokens_new, _params) do
    require_admin!(socket)

    assign(socket,
      page_title: gettext("New account token"),
      available_scopes: available_scopes(),
      token_form:
        to_form(%{"name" => "", "description" => "", "scopes" => [], "expiration" => "90"},
          as: :token
        ),
      newly_created_token: nil,
      token_form_valid?: false
    )
  end

  defp apply_action(socket, :api_token_edit, params) do
    require_admin!(socket)
    account = socket.assigns.account
    token = DeveloperTokens.get_account_token!(params["token_id"], account.id)

    assign(socket,
      page_title: token.name,
      editing_token: token,
      token_edit_form:
        to_form(
          %{"name" => token.name, "description" => token.description || ""},
          as: :token
        ),
      token_edit_changed?: false
    )
  end

  defp apply_action(socket, :api_apps, params) do
    require_admin!(socket)
    account = socket.assigns.account

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
      apps_sort_dir: sort_dir
    )
  end

  defp apply_action(socket, :api_apps_new, _params) do
    require_admin!(socket)

    assign(socket,
      page_title: gettext("New OAuth App"),
      app_form:
        to_form(%{"name" => "", "description" => "", "homepage_url" => "", "redirect_uris" => ""},
          as: :app
        ),
      app_form_valid?: false
    )
  end

  defp apply_action(socket, :api_app_edit, %{"app_id" => app_id}) do
    require_admin!(socket)
    account = socket.assigns.account
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
      newly_regenerated_secret: nil
    )
  end

  defp apply_action(socket, :tickets, params) do
    account = socket.assigns.account

    sort_key = Map.get(params, "ksort", "inserted_at")
    sort_dir = Map.get(params, "kdir", "desc")
    active_filters = extract_filters(params, "k")

    flop_params =
      %{
        "order_by" => [sort_key],
        "order_directions" => [sort_dir]
      }
      |> maybe_add_flop_filters(active_filters)

    {:ok, {tickets, _meta}} = Support.list_tickets(account, flop_params)

    assign(socket,
      page_title: gettext("Tickets"),
      tickets: tickets,
      tickets_sort_key: sort_key,
      tickets_sort_dir: sort_dir,
      tickets_active_filters: active_filters
    )
  end

  defp apply_action(socket, :ticket_new, _params) do
    assign(socket,
      page_title: gettext("New ticket"),
      ticket_form: to_form(%{"title" => "", "description" => "", "type" => "issue"}, as: :ticket),
      generating_title?: false,
      title_manually_edited?: false,
      ticket_title_generation: 0,
      ticket_title_timer_ref: nil,
      ticket_title_task_ref: nil
    )
  end

  defp apply_action(socket, :ticket_show, %{"ticket_number" => number_str}) do
    account = socket.assigns.account
    ticket = Support.get_ticket_by_number!(String.to_integer(number_str), account.id)

    assign(socket,
      page_title: ticket.title,
      ticket: ticket,
      message_form: to_form(%{"body" => ""}, as: :message)
    )
  end

  defp apply_action(socket, :project, %{"project" => project}) do
    og_image_url =
      if socket.assigns.account.visibility == "public" do
        og_attrs = %{
          title: project,
          description: socket.assigns.handle <> "/" <> project,
          category: "project"
        }

        Glossia.OgImage.project_url(socket.assigns.handle, project, og_attrs)
      end

    assign(socket, page_title: project, project_name: project, og_image_url: og_image_url)
  end

  defp require_admin!(socket) do
    unless socket.assigns.is_admin do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end
  end

  defp available_scopes do
    Glossia.Policy.list_rules()
    |> Enum.map(&"#{&1.object}:#{&1.action}")
    |> Enum.uniq()
    |> Enum.sort()
  end

  # ---------------------------------------------------------------------------
  # Voice form events
  # ---------------------------------------------------------------------------

  def handle_event("validate", params, socket) do
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

  def handle_event("add_country", %{"code" => code}, socket) do
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

  def handle_event("remove_country", %{"code" => code}, socket) do
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
      |> assign(target_countries: new_countries, cultural_notes: new_contexts, changed?: changed?)
      |> push_event("update_country_exclude", %{exclude: new_countries})
      |> schedule_summary_generation(:voice)

    {:noreply, socket}
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
    changed? = name_changed or desc_changed
    {:noreply, assign(socket, token_edit_changed?: changed?)}
  end

  def handle_event("update_token", %{"token" => params}, socket) do
    unless socket.assigns.is_admin do
      {:noreply, put_flash(socket, :error, gettext("You don't have permission."))}
    else
      token = socket.assigns.editing_token
      account = socket.assigns.account
      user = socket.assigns.current_user

      attrs = %{
        "name" => params["name"],
        "description" => params["description"]
      }

      case DeveloperTokens.update_account_token(token, attrs) do
        {:ok, updated_token} ->
          Auditing.record("token.updated", account, user,
            resource_type: "account_token",
            resource_id: to_string(updated_token.id),
            summary: "Updated account token \"#{updated_token.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Token updated."))
           |> push_patch(to: ~p"/#{socket.assigns.handle}/api/tokens")}

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
            summary: "Created account token \"#{token.name}\""
          )

          {:ok, {tokens, _meta}} = DeveloperTokens.list_account_tokens(account)

          {:noreply,
           socket
           |> assign(api_tokens: tokens, newly_created_token: plain_token)
           |> push_patch(to: ~p"/#{socket.assigns.handle}/api/tokens")}

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
            summary: "Revoked account token \"#{token.name}\""
          )

          {:ok, {tokens, _meta}} = DeveloperTokens.list_account_tokens(account)

          {:noreply,
           socket
           |> assign(api_tokens: tokens)
           |> put_flash(:info, gettext("Token revoked."))
           |> push_patch(to: ~p"/#{socket.assigns.handle}/api/tokens")}

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
            summary: "Created OAuth application \"#{app.name}\""
          )

          {:ok, {apps, _meta}} = DeveloperTokens.list_oauth_applications(account)

          {:noreply,
           socket
           |> assign(
             oauth_apps: apps,
             newly_created_secret: %{client_id: client_id, client_secret: client_secret}
           )
           |> push_patch(to: ~p"/#{socket.assigns.handle}/api/apps")}

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
            summary: "Updated OAuth application \"#{updated_app.name}\""
          )

          {:noreply,
           socket
           |> put_flash(:info, gettext("Application updated."))
           |> push_patch(to: ~p"/#{socket.assigns.handle}/api/apps/#{app.id}")}

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
            summary: "Deleted OAuth application \"#{app.name}\""
          )

          {:ok, {apps, _meta}} = DeveloperTokens.list_oauth_applications(account)

          {:noreply,
           socket
           |> assign(oauth_apps: apps)
           |> put_flash(:info, gettext("Application deleted."))
           |> push_patch(to: ~p"/#{socket.assigns.handle}/api/apps")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not delete application."))}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Ticket events
  # ---------------------------------------------------------------------------

  def handle_event("ticket_validate", %{"_target" => target, "ticket" => params}, socket) do
    description = params["description"] || ""
    title = params["title"] || ""

    title_manually_edited? =
      cond do
        target == ["ticket", "title"] and title != "" -> true
        target == ["ticket", "title"] -> false
        true -> socket.assigns[:title_manually_edited?] || false
      end

    socket =
      if String.length(description) >= 20 and not title_manually_edited? do
        schedule_title_generation(socket, description)
      else
        cancel_title_generation(socket)
      end

    {:noreply,
     assign(socket,
       title_manually_edited?: title_manually_edited?,
       ticket_form:
         to_form(
           %{
             "title" => title,
             "description" => description,
             "type" => params["type"] || "issue"
           },
           as: :ticket
         )
     )}
  end

  def handle_event("create_ticket", %{"ticket" => params}, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user

    case Support.create_ticket(account, user, params) do
      {:ok, ticket} ->
        Auditing.record("ticket.created", account, user,
          resource_type: "ticket",
          resource_id: to_string(ticket.id),
          summary: "Created ticket \"#{ticket.title}\""
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Ticket created."))
         |> push_patch(to: ~p"/#{socket.assigns.handle}/tickets/#{ticket.number}")}

      {:error, changeset} ->
        {:noreply, assign(socket, ticket_form: to_form(changeset, as: :ticket))}
    end
  end

  def handle_event("add_ticket_message", %{"message" => params}, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user
    account = socket.assigns.account

    case Support.add_message(ticket, user, params) do
      {:ok, _message} ->
        Auditing.record("ticket.replied", account, user,
          resource_type: "ticket",
          resource_id: to_string(ticket.id),
          summary: "Replied to ticket \"#{ticket.title}\""
        )

        ticket = Support.get_ticket!(ticket.id, account.id)

        {:noreply,
         socket
         |> assign(ticket: ticket, message_form: to_form(%{"body" => ""}, as: :message))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not send message."))}
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
      description = socket.assigns[:ticket_description_for_title] || ""

      case Glossia.RateLimiter.hit("ai:title:#{account.id}", :timer.minutes(1), 10) do
        {:allow, _count} ->
          messages = [
            %{
              role: :system,
              content:
                "You are a support ticket assistant. Given a user's description of an issue or feature request, generate a clear, concise title (under 80 characters). Only output the title, nothing else."
            },
            %{role: :user, content: description}
          ]

          task = Task.async(fn -> Glossia.Minimax.chat(messages, max_tokens: 1024) end)

          form = socket.assigns.ticket_form
          description_val = form[:description].value || ""
          type_val = form[:type].value || "issue"

          {:noreply,
           assign(socket,
             generating_title?: true,
             ticket_title_task_ref: task.ref,
             ticket_form:
               to_form(
                 %{"title" => "", "description" => description_val, "type" => type_val},
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
            description = form[:description].value || ""
            type = form[:type].value || "issue"

            {:noreply,
             socket
             |> assign(
               generating_title?: false,
               ticket_title_task_ref: nil,
               ticket_form:
                 to_form(
                   %{"title" => title, "description" => description, "type" => type},
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
          target_countries={@target_countries}
          cultural_notes={@cultural_notes}
          generating_contexts?={@generating_contexts?}
          handle={@handle}
          can_write={@can_write}
          changed?={@changed?}
          change_summary={@change_summary}
          generating_summary?={@generating_summary?}
          voice_form_params={@voice_form_params}
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
          change_summary={@change_summary}
          generating_summary?={@generating_summary?}
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
      <% action when action in [:tickets, :ticket_new, :ticket_show] -> %>
        <.tickets_page
          live_action={@live_action}
          handle={@handle}
          tickets={assigns[:tickets] || []}
          ticket={assigns[:ticket]}
          ticket_form={assigns[:ticket_form]}
          message_form={assigns[:message_form]}
          current_user={@current_user}
          tickets_sort_key={assigns[:tickets_sort_key] || "inserted_at"}
          tickets_sort_dir={assigns[:tickets_sort_dir] || "desc"}
          tickets_active_filters={assigns[:tickets_active_filters] || %{}}
          generating_title?={assigns[:generating_title?] || false}
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
            <h2>{gettext("About")}</h2>
            <p>{gettext("Describe what you do and which countries you target.")}</p>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <div class="voice-field">
                <label for="voice_description">{gettext("Description")}</label>
                <textarea
                  id="voice_description"
                  name="description"
                  rows="3"
                  placeholder={gettext("Briefly describe what you do and who you serve...")}
                  disabled={!@can_write}
                  phx-debounce="300"
                >{@voice_form_params["description"] || (@voice && @voice.description) || ""}</textarea>
                <span class="voice-field-help">
                  {gettext("Used to generate cultural notes for target countries.")}
                </span>
              </div>
              <div class="voice-field">
                <label>{gettext("Target countries")}</label>
                <%= if @target_countries != [] do %>
                  <div class="voice-country-tags" id="voice-country-tags">
                    <%= for code <- @target_countries do %>
                      <span class="voice-country-tag">
                        {country_flag(code)} {code}
                        <%= if @can_write do %>
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
                <%= if @can_write do %>
                  <.country_picker
                    id="voice-country-picker"
                    exclude={@target_countries}
                  />
                <% end %>
              </div>
              <%= if @target_countries != [] do %>
                <div class="voice-field">
                  <label>{gettext("Cultural notes")}</label>
                  <span class="voice-field-help">
                    <%= if @generating_contexts? do %>
                      {gettext("Generating cultural notes...")}
                    <% else %>
                      {gettext("AI-generated cultural notes per country. You can edit them.")}
                    <% end %>
                  </span>
                  <%= for code <- @target_countries do %>
                    <div class="voice-country-context" id={"country-context-#{code}"}>
                      <label class="voice-country-context-label">
                        {country_flag(code)} {country_name(code)}
                      </label>
                      <textarea
                        name={"cultural_notes[#{code}]"}
                        rows="3"
                        placeholder={
                          gettext("Cultural notes for %{country}...", country: country_name(code))
                        }
                        disabled={!@can_write}
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
      <.breadcrumb items={[
        {gettext("Voice"), "/" <> @handle <> "/voice"},
        {"##{@voice.version}", "/" <> @handle <> "/voice/versions/" <> @voice.id}
      ]} />
      <div class="dash-page-header">
        <div class="voice-version-header">
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
      <.breadcrumb items={[
        {gettext("Glossary"), "/" <> @handle <> "/glossary"},
        {"##{@glossary.version}", "/" <> @handle <> "/glossary/versions/" <> @glossary.id}
      ]} />
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

    assigns = assign(assigns, :scope_groups, scope_groups)

    ~H"""
    <div class="dash-page">
      <%= cond do %>
        <% @live_action == :api_tokens_new -> %>
          <.breadcrumb items={[
            {gettext("Account tokens"), "/" <> @handle <> "/api/tokens"},
            {gettext("New token"), "/" <> @handle <> "/api/tokens/new"}
          ]} />
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
                      <div class="api-scope-group-title">{group}</div>
                      <div class="api-scope-grid">
                        <%= for scope <- scopes do %>
                          <label class="api-scope-item">
                            <input type="checkbox" name="token[scopes][]" value={scope} />
                            <span>{scope}</span>
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
              cancel_path={"/" <> @handle <> "/api/tokens"}
            />
          </.form>
        <% @live_action == :api_token_edit -> %>
          <.breadcrumb items={[
            {gettext("Account tokens"), "/" <> @handle <> "/api/tokens"},
            {@editing_token.name, "/" <> @handle <> "/api/tokens/" <> @editing_token.id}
          ]} />
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
                    <span class="muted">{@editing_token.token_prefix}...</span>
                  </div>
                  <div class="voice-field">
                    <label>{gettext("Scopes")}</label>
                    <div class="api-token-scopes">
                      <%= for scope <- String.split(@editing_token.scope || "", " ", trim: true) do %>
                        <span class="api-scope-badge">{scope}</span>
                      <% end %>
                      <%= if (@editing_token.scope || "") == "" do %>
                        <span class="muted">{gettext("No scopes")}</span>
                      <% end %>
                    </div>
                  </div>
                  <div class="voice-field">
                    <label>{gettext("Expires")}</label>
                    <span>
                      <%= if @editing_token.expires_at do %>
                        {Calendar.strftime(@editing_token.expires_at, "%b %d, %Y")}
                      <% else %>
                        {gettext("Never")}
                      <% end %>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <.form_save_bar
              id="token-edit-save-bar"
              visible={@token_edit_changed?}
              cancel_path={"/" <> @handle <> "/api/tokens"}
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
              <.link patch={"/" <> @handle <> "/api/tokens/new"} class="dash-btn dash-btn-primary">
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
              <strong>{token.name}</strong>
              <br />
              <span class="mono" style="font-size: var(--text-xs); color: var(--color-text-muted);">
                {token.token_prefix}...
              </span>
            </:col>
            <:col :let={token} label={gettext("Scopes")} key="scopes">
              <div class="api-token-scopes">
                <%= for scope <- String.split(token.scope || "", " ", trim: true) |> Enum.take(3) do %>
                  <span class="api-scope-badge">{scope}</span>
                <% end %>
                <%= if length(String.split(token.scope || "", " ", trim: true)) > 3 do %>
                  <span class="api-scope-badge">
                    +{length(String.split(token.scope || "", " ", trim: true)) - 3}
                  </span>
                <% end %>
              </div>
            </:col>
            <:col :let={token} label={gettext("Last used")} key="last_used_at" sortable>
              <%= if token.last_used_at do %>
                <time datetime={DateTime.to_iso8601(token.last_used_at)}>
                  {Calendar.strftime(token.last_used_at, "%b %d, %Y")}
                </time>
              <% else %>
                <span class="muted">{gettext("Never")}</span>
              <% end %>
            </:col>
            <:col :let={token} label={gettext("Expires")} key="expires_at" sortable>
              <%= if token.expires_at do %>
                <time datetime={DateTime.to_iso8601(token.expires_at)}>
                  {Calendar.strftime(token.expires_at, "%b %d, %Y")}
                </time>
              <% else %>
                <span>{gettext("Never")}</span>
              <% end %>
            </:col>
            <:action :let={token}>
              <.link patch={"/" <> @handle <> "/api/tokens/" <> token.id} class="voice-link-btn">
                {gettext("Edit")}
              </.link>
              <button
                class="voice-link-btn voice-link-btn-danger"
                phx-click="revoke_token"
                phx-value-id={token.id}
                data-confirm={
                  gettext(
                    "Are you sure you want to revoke this token? Any applications using this token will no longer be able to access the API."
                  )
                }
              >
                {gettext("Revoke")}
              </button>
            </:action>
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
          <.breadcrumb items={[
            {gettext("OAuth apps"), "/" <> @handle <> "/api/apps"},
            {gettext("New application"), "/" <> @handle <> "/api/apps/new"}
          ]} />
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
              cancel_path={"/" <> @handle <> "/api/apps"}
            />
          </.form>
        <% @live_action == :api_app_edit -> %>
          <.breadcrumb items={[
            {gettext("OAuth apps"), "/" <> @handle <> "/api/apps"},
            {@oauth_app.name, "/" <> @handle <> "/api/apps/" <> @oauth_app.id}
          ]} />
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
                    <div class="api-credential-field">
                      <span>{@boruta_client.id}</span>
                      <button
                        type="button"
                        class="api-copy-btn"
                        phx-hook=".CopyToken"
                        id="copy-client-id-btn"
                        data-value={@boruta_client.id}
                        title={gettext("Copy to clipboard")}
                      >
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
                          <rect width="14" height="14" x="8" y="8" rx="2" ry="2" />
                          <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
                        </svg>
                      </button>
                    </div>
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
              cancel_path={"/" <> @handle <> "/api/apps"}
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
              <.link patch={"/" <> @handle <> "/api/apps/new"} class="dash-btn dash-btn-primary">
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
              <strong>{app.name}</strong>
            </:col>
            <:col :let={app} label={gettext("Client ID")} key="client_id">
              <span class="mono" style="font-size: var(--text-xs);">
                {app.boruta_client_id}
              </span>
            </:col>
            <:col :let={app} label={gettext("Created")} key="inserted_at" sortable>
              <time datetime={DateTime.to_iso8601(app.inserted_at)}>
                {Calendar.strftime(app.inserted_at, "%b %d, %Y")}
              </time>
            </:col>
            <:action :let={app}>
              <.link
                patch={"/" <> @handle <> "/api/apps/" <> app.id}
                class="voice-link-btn"
              >
                {gettext("Edit")}
              </.link>
              <button
                class="voice-link-btn voice-link-btn-danger"
                phx-click="delete_oauth_app"
                phx-value-id={app.id}
                data-confirm={gettext("Are you sure you want to delete this application?")}
              >
                {gettext("Delete")}
              </button>
            </:action>
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

  defp save_voice(params, change_note, socket) do
    account = socket.assigns.account
    user = socket.assigns.current_user
    handle = socket.assigns.handle

    voice_attrs = %{
      tone: params["tone"],
      formality: params["formality"],
      target_audience: params["target_audience"],
      guidelines: params["guidelines"],
      description: non_empty(params["description"]),
      target_countries: socket.assigns.target_countries,
      cultural_notes: socket.assigns.cultural_notes,
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
          resource_path: ~p"/#{handle}/voice/#{voice.version}",
          summary: change_note
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Voice configuration saved."))
         |> push_patch(to: ~p"/#{handle}/voice")}

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
          resource_path: ~p"/#{handle}/glossary/#{glossary.version}",
          summary: change_note
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Glossary saved."))
         |> push_patch(to: ~p"/#{handle}/glossary")}

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

  defp schedule_title_generation(socket, description) do
    if timer = socket.assigns[:ticket_title_timer_ref] do
      Process.cancel_timer(timer)
    end

    generation = (socket.assigns[:ticket_title_generation] || 0) + 1
    timer_ref = Process.send_after(self(), {:generate_ticket_title, generation}, 1_500)

    assign(socket,
      ticket_title_generation: generation,
      ticket_title_timer_ref: timer_ref,
      ticket_description_for_title: description
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
    "activity-table" => "",
    "members-table" => "m",
    "invitations-table" => "i",
    "tokens-table" => "t",
    "oauth-apps-table" => "a",
    "tickets-table" => "k"
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
        :api_tokens -> "/#{handle}/api/tokens"
        :api_apps -> "/#{handle}/api/apps"
        :tickets -> "/#{handle}/tickets"
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

  defp maybe_add_flop_filters(params, filters) when map_size(filters) == 0, do: params

  defp maybe_add_flop_filters(params, filters) do
    flop_filters =
      Enum.map(filters, fn {field, value} ->
        %{"field" => field, "op" => "==", "value" => value}
      end)

    Map.put(params, "filters", flop_filters)
  end

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

  defp current_table_state(socket, "tickets-table") do
    %{
      search: "",
      sort: socket.assigns[:tickets_sort_key] || "inserted_at",
      dir: socket.assigns[:tickets_sort_dir] || "desc",
      page: 1,
      filters: socket.assigns[:tickets_active_filters] || %{}
    }
  end

  defp current_table_state(_socket, _id),
    do: %{search: "", sort: "", dir: "asc", page: 1, filters: %{}}

  defp default_sort_key("activity-table"), do: "date"
  defp default_sort_key("members-table"), do: "name"
  defp default_sort_key("invitations-table"), do: "email"
  defp default_sort_key("tokens-table"), do: "name"
  defp default_sort_key("oauth-apps-table"), do: "name"
  defp default_sort_key("tickets-table"), do: "inserted_at"
  defp default_sort_key(_), do: ""

  defp default_sort_dir("activity-table"), do: "desc"
  defp default_sort_dir("tickets-table"), do: "desc"
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

  defp current_sort(socket, "tickets-table"),
    do:
      {socket.assigns[:tickets_sort_key] || "inserted_at",
       socket.assigns[:tickets_sort_dir] || "desc"}

  defp current_sort(_socket, _), do: {"", "asc"}

  defp current_filters(socket, "activity-table"), do: socket.assigns.events_filters
  defp current_filters(socket, "members-table"), do: socket.assigns.members_filters

  defp current_filters(socket, "tickets-table"),
    do: socket.assigns[:tickets_active_filters] || %{}

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

  # ---------------------------------------------------------------------------
  # Page: Tickets
  # ---------------------------------------------------------------------------

  defp tickets_page(assigns) do
    case assigns.live_action do
      :tickets -> tickets_list_page(assigns)
      :ticket_new -> ticket_new_page(assigns)
      :ticket_show -> ticket_show_page(assigns)
    end
  end

  defp tickets_list_page(assigns) do
    assigns =
      assign(assigns,
        ticket_filters: [
          %{
            key: "type",
            label: gettext("Type"),
            options: [
              %{value: "issue", label: gettext("Issue")},
              %{value: "request", label: gettext("Feature request")}
            ]
          },
          %{
            key: "status",
            label: gettext("Status"),
            options: [
              %{value: "open", label: gettext("Open")},
              %{value: "in_progress", label: gettext("In progress")},
              %{value: "resolved", label: gettext("Resolved")},
              %{value: "implemented", label: gettext("Implemented")}
            ]
          }
        ]
      )

    ~H"""
    <div class="dash-page">
      <.page_header
        title={gettext("Tickets")}
        description={gettext("Report issues or request features.")}
      >
        <:actions>
          <.link patch={"/" <> @handle <> "/tickets/new"} class="dash-btn dash-btn-primary">
            {gettext("New ticket")}
          </.link>
        </:actions>
      </.page_header>
      <.resource_table
        id="tickets-table"
        rows={@tickets}
        sort_key={@tickets_sort_key}
        sort_dir={@tickets_sort_dir}
        filters={@ticket_filters}
        active_filters={@tickets_active_filters}
      >
        <:col :let={ticket} label="#" key="number" sortable>
          <.link
            patch={"/" <> @handle <> "/tickets/" <> Integer.to_string(ticket.number)}
            class="resource-link"
          >
            {"##{ticket.number}"}
          </.link>
        </:col>
        <:col :let={ticket} label={gettext("Title")} key="title" sortable>
          <.link
            patch={"/" <> @handle <> "/tickets/" <> Integer.to_string(ticket.number)}
            class="resource-link"
          >
            {ticket.title}
          </.link>
        </:col>
        <:col :let={ticket} label={gettext("Type")} key="type">
          <.badge variant={ticket_type_variant(ticket.type)}>
            {ticket_type_label(ticket.type)}
          </.badge>
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
            patch={"/" <> @handle <> "/tickets/" <> Integer.to_string(ticket.number)}
            class="dash-btn dash-btn-secondary dash-btn-sm"
          >
            {gettext("View")}
          </.link>
        </:action>
        <:empty>
          <div class="dash-empty-state">
            <p>{gettext("No tickets yet. Create one to get started.")}</p>
          </div>
        </:empty>
      </.resource_table>
    </div>
    """
  end

  defp ticket_new_page(assigns) do
    ~H"""
    <div class="dash-page">
      <.breadcrumb items={[
        {gettext("Tickets"), "/" <> @handle <> "/tickets"},
        {gettext("New ticket"), "/" <> @handle <> "/tickets/new"}
      ]} />
      <.page_header
        title={gettext("New ticket")}
        description={gettext("Describe your issue or feature request.")}
      />
      <.form
        for={@ticket_form}
        id="ticket-form"
        phx-submit="create_ticket"
        phx-change="ticket_validate"
        class="ticket-form"
      >
        <div class="ticket-form-field">
          <label for="ticket_type">{gettext("Type")}</label>
          <select name="ticket[type]" id="ticket_type">
            <option value="issue" selected={@ticket_form[:type].value == "issue"}>
              {gettext("Issue")}
            </option>
            <option value="request" selected={@ticket_form[:type].value == "request"}>
              {gettext("Feature request")}
            </option>
          </select>
        </div>
        <div class="ticket-form-field">
          <label for="ticket_title">{gettext("Title")}</label>
          <div class={["ticket-title-wrapper", @generating_title? && "generating"]}>
            <input
              type="text"
              name="ticket[title]"
              id="ticket_title"
              value={@ticket_form[:title].value}
              placeholder={
                if @generating_title?, do: gettext("Generating..."), else: gettext("Brief summary...")
              }
              phx-hook=".TicketTitle"
              required
              disabled={@generating_title?}
            />
          </div>
        </div>
        <div class="ticket-form-field">
          <label for="ticket_description">{gettext("Description")}</label>
          <textarea
            name="ticket[description]"
            id="ticket_description"
            rows="6"
            placeholder={gettext("Provide details...")}
            phx-debounce="500"
            required
          >{@ticket_form[:description].value}</textarea>
        </div>
        <div class="ticket-form-actions">
          <.link patch={"/" <> @handle <> "/tickets"} class="dash-btn dash-btn-secondary">
            {gettext("Cancel")}
          </.link>
          <button type="submit" class="dash-btn dash-btn-primary">
            {gettext("Create ticket")}
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
      <.breadcrumb items={[
        {gettext("Tickets"), "/" <> @handle <> "/tickets"},
        {"##{@ticket.number}", "/" <> @handle <> "/tickets/" <> Integer.to_string(@ticket.number)}
      ]} />
      <div class="ticket-detail-header">
        <div>
          <h1 class="ticket-detail-title">{@ticket.title}</h1>
          <div class="ticket-detail-meta">
            <.badge variant={ticket_type_variant(@ticket.type)}>
              {ticket_type_label(@ticket.type)}
            </.badge>
            <.badge variant={ticket_status_variant(@ticket.status)}>
              {ticket_status_label(@ticket.status)}
            </.badge>
            <span class="ticket-detail-date">
              {gettext("Opened %{date}",
                date: Calendar.strftime(@ticket.inserted_at, "%b %d, %Y")
              )}
            </span>
          </div>
        </div>
      </div>
      <div class="ticket-conversation">
        <div class="ticket-message ticket-message-user" id="ticket-description">
          <div class="ticket-message-header">
            <span class="ticket-message-author">{@ticket.user.name || @ticket.user.email}</span>
            <span class="ticket-message-time">
              {Calendar.strftime(@ticket.inserted_at, "%b %d, %Y at %H:%M")}
            </span>
          </div>
          <div class="ticket-message-body">{@ticket.description}</div>
        </div>
        <div
          :for={msg <- @ticket.messages}
          class={[
            "ticket-message",
            if(msg.is_staff, do: "ticket-message-staff", else: "ticket-message-user")
          ]}
          id={"msg-" <> msg.id}
        >
          <div class="ticket-message-header">
            <span class="ticket-message-author">
              {msg.user.name || msg.user.email}
              <.badge :if={msg.is_staff} variant="info">{gettext("Staff")}</.badge>
            </span>
            <span class="ticket-message-time">
              {Calendar.strftime(msg.inserted_at, "%b %d, %Y at %H:%M")}
            </span>
          </div>
          <div class="ticket-message-body">{msg.body}</div>
        </div>
      </div>
      <%= if @ticket.status in ~w(open in_progress) and @current_user do %>
        <.form
          for={@message_form}
          id="message-form"
          phx-submit="add_ticket_message"
          class="ticket-reply-form"
        >
          <div class="ticket-reply-input-wrap">
            <textarea
              name="message[body]"
              id="message_body"
              rows="1"
              placeholder={gettext("Write a reply...")}
              required
            >{@message_form[:body].value}</textarea>
            <button type="submit" class="ticket-reply-send" aria-label={gettext("Send reply")}>
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
                <path d="m22 2-7 20-4-9-9-4Z" /><path d="M22 2 11 13" />
              </svg>
            </button>
          </div>
        </.form>
      <% end %>
    </div>
    """
  end

  defp ticket_status_variant("open"), do: "neutral"
  defp ticket_status_variant("in_progress"), do: "info"
  defp ticket_status_variant("resolved"), do: "success"
  defp ticket_status_variant("implemented"), do: "success"
  defp ticket_status_variant(_), do: "neutral"

  defp ticket_status_label("open"), do: gettext("Open")
  defp ticket_status_label("in_progress"), do: gettext("In progress")
  defp ticket_status_label("resolved"), do: gettext("Resolved")
  defp ticket_status_label("implemented"), do: gettext("Implemented")
  defp ticket_status_label(other), do: other

  defp ticket_type_variant("issue"), do: "warning"
  defp ticket_type_variant("request"), do: "info"
  defp ticket_type_variant(_), do: "neutral"

  defp ticket_type_label("issue"), do: gettext("Issue")
  defp ticket_type_label("request"), do: gettext("Feature request")
  defp ticket_type_label(other), do: other
end
