defmodule GlossiaWeb.QualityLive do
  use GlossiaWeb, :live_view

  import GlossiaWeb.DashboardComponents

  alias Glossia.Quality
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :subscribed_quality_run_id, nil)}
  end

  def handle_params(%{"project" => project_handle} = params, _uri, socket) do
    project = Glossia.Projects.get_project(socket.assigns.account, project_handle)

    unless project do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end

    socket =
      socket
      |> assign(
        project: project,
        sidebar_context: :project,
        sidebar_project: project
      )
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  def handle_event("start_quality_run", _params, socket) do
    require_quality_write!(socket)

    case Quality.create_run(
           socket.assigns.account,
           socket.assigns.project,
           socket.assigns.current_user
         ) do
      {:ok, run} ->
        {:noreply,
         push_navigate(socket,
           to: ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}/-/qa/runs/#{run.id}"
         )}

      {:error, :quality_profile_missing} ->
        {:noreply, put_flash(socket, :error, gettext("Save the localization QA settings first."))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, quality_error(reason))}
    end
  end

  def handle_event("cancel_quality_run", _params, socket) do
    require_quality_write!(socket)

    case Quality.cancel_run(socket.assigns.run) do
      {:ok, _run} ->
        {:noreply, put_flash(socket, :info, gettext("The localization QA run was cancelled."))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, quality_error(reason))}
    end
  end

  def handle_event("select_quality_capture", %{"page-id" => page_id} = params, socket) do
    require_quality_read!(socket)

    case Enum.find(socket.assigns.pages, &(&1.id == page_id)) do
      nil ->
        {:noreply, socket}

      page ->
        {:noreply,
         assign(socket,
           following_session: false,
           replay_position:
             replay_position(params["at"], socket.assigns.run, socket.assigns.session_events),
           selected_page: page,
           selected_annotations: annotations_for(socket.assigns.run, page)
         )}
    end
  end

  def handle_event("follow_quality_session", _params, socket) do
    require_quality_read!(socket)

    {:noreply,
     socket
     |> assign(following_session: true, replay_position: nil)
     |> select_latest_capture()}
  end

  def handle_event("save_quality_profile", %{"profile" => params}, socket) do
    require_quality_admin!(socket)

    attrs = %{
      "source_locale" => "en",
      "locale_origins" => %{"en" => params["site_url"]},
      "seed_paths" => ["/"],
      "max_pages" => 20
    }

    case Quality.upsert_profile(socket.assigns.project, attrs) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> assign_profile_form(profile)
         |> put_flash(:info, gettext("QA settings saved."))}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, as: :profile))}
    end
  end

  def handle_event("update_finding", %{"id" => id, "status" => status}, socket) do
    require_quality_write!(socket)
    finding = Quality.get_finding!(socket.assigns.project, id)

    case Quality.update_finding_status(finding, status) do
      {:ok, _finding} -> {:noreply, reload_findings(socket)}
      {:error, reason} -> {:noreply, put_flash(socket, :error, quality_error(reason))}
    end
  end

  def handle_event(
        "remember_translation",
        %{"finding_id" => finding_id, "translation" => translation},
        socket
      ) do
    require_quality_write!(socket)
    finding = Quality.get_finding!(socket.assigns.project, finding_id)

    case Quality.remember_translation(
           socket.assigns.project,
           finding,
           socket.assigns.current_user,
           translation
         ) do
      {:ok, _context} ->
        {:noreply,
         socket
         |> reload_findings()
         |> assign(:project_context, Quality.get_latest_project_context(socket.assigns.project))
         |> push_event("close-modal", %{id: "quality-memory-modal-#{finding.id}"})
         |> put_flash(:info, gettext("The approved translation will guide future translations."))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, quality_error(reason))}
    end
  end

  def handle_info({:quality_run_updated, run}, socket) do
    if socket.assigns.live_action == :project_quality_run and socket.assigns.run.id == run.id do
      {:noreply, apply_run(socket, run.id)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:quality_session_event, event}, socket) do
    if socket.assigns.live_action == :project_quality_run and
         socket.assigns.run.id == event.run_id do
      {:noreply, apply_session_event(socket, event)}
    else
      {:noreply, socket}
    end
  end

  defp apply_action(socket, :project_quality, params) do
    require_quality_read!(socket)

    {:ok, {runs, runs_meta}} =
      Quality.list_runs(socket.assigns.project, Map.take(params, ["page"]))

    socket
    |> clear_run_subscription()
    |> assign(
      page_title: gettext("Localization QA"),
      profile: Quality.get_profile(socket.assigns.project),
      runs: runs,
      runs_meta: runs_meta,
      findings: Quality.list_findings(socket.assigns.project),
      project_context: Quality.get_latest_project_context(socket.assigns.project),
      breadcrumb_items: [
        {socket.assigns.project.handle,
         ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}"},
        {gettext("Localization QA"), nil}
      ]
    )
  end

  defp apply_action(socket, :project_quality_run, %{"run_id" => run_id}) do
    require_quality_read!(socket)

    socket
    |> apply_run(run_id)
    |> assign(
      page_title: gettext("QA run"),
      breadcrumb_items: [
        {socket.assigns.project.handle,
         ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}"},
        {gettext("Localization QA"),
         ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}/-/qa"},
        {gettext("Run"), nil}
      ]
    )
  end

  defp apply_action(socket, :project_quality_settings, _params) do
    require_quality_admin!(socket)
    profile = Quality.profile_or_default(socket.assigns.project)

    socket
    |> clear_run_subscription()
    |> assign_profile_form(profile)
    |> assign(
      page_title: gettext("QA settings"),
      breadcrumb_items: [
        {socket.assigns.project.handle,
         ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}"},
        {gettext("Settings"),
         ~p"/#{socket.assigns.handle}/#{socket.assigns.project.handle}/-/settings"},
        {gettext("QA"), nil}
      ]
    )
  end

  defp apply_run(socket, run_id) do
    run = Quality.get_run!(socket.assigns.project, run_id)

    pages = Quality.list_run_pages(run)
    events = Quality.list_session_events(run)
    following_session = Map.get(socket.assigns, :following_session, true)
    replay_position = Map.get(socket.assigns, :replay_position)

    socket
    |> sync_run_subscription(run)
    |> assign(
      run: run,
      pages: pages,
      session_events: events,
      capture_events: Enum.filter(events, &(&1.kind == "page_captured" and &1.page_id)),
      findings: Quality.list_findings(socket.assigns.project, run_id: run.id),
      following_session: following_session,
      replay_position: replay_position
    )
    |> select_capture()
  end

  defp sync_run_subscription(socket, run) do
    current_run_id = socket.assigns.subscribed_quality_run_id
    target_run_id = if connected?(socket), do: run.id

    if current_run_id != target_run_id do
      if current_run_id, do: Quality.unsubscribe_run(current_run_id)
      if target_run_id, do: Quality.subscribe_run(run)
    end

    assign(socket, :subscribed_quality_run_id, target_run_id)
  end

  defp apply_session_event(socket, event) do
    socket = assign(socket, :session_events, upsert_by_id(socket.assigns.session_events, event))

    case event.kind do
      "page_captured" -> apply_page_captured_event(socket, event)
      "finding_recorded" -> apply_finding_recorded_event(socket, event)
      _kind -> socket
    end
  end

  defp apply_page_captured_event(socket, event) do
    case Quality.get_page(socket.assigns.project, socket.assigns.run.id, event.page_id) do
      nil ->
        socket

      page ->
        socket
        |> assign(
          pages: upsert_by_id(socket.assigns.pages, page),
          capture_events: upsert_by_id(socket.assigns.capture_events, event)
        )
        |> select_capture()
    end
  end

  defp apply_finding_recorded_event(socket, event) do
    case Quality.get_occurrence(socket.assigns.run, event.finding_id, event.page_id) do
      nil ->
        socket

      occurrence ->
        run = %{
          socket.assigns.run
          | occurrences: upsert_by_id(socket.assigns.run.occurrences, occurrence)
        }

        socket
        |> assign(
          run: run,
          findings:
            socket.assigns.findings
            |> upsert_by_id(occurrence.finding)
            |> sort_findings()
        )
        |> select_capture()
    end
  end

  defp upsert_by_id(items, item) do
    items
    |> Enum.reject(&(&1.id == item.id))
    |> Kernel.++([item])
  end

  defp sort_findings(findings) do
    Enum.sort_by(findings, fn finding ->
      {severity_rank(finding.severity), -DateTime.to_unix(finding.last_seen_at, :microsecond)}
    end)
  end

  defp clear_run_subscription(socket) do
    if run_id = socket.assigns.subscribed_quality_run_id do
      Quality.unsubscribe_run(run_id)
    end

    assign(socket, :subscribed_quality_run_id, nil)
  end

  defp select_capture(socket) do
    selected_page = Map.get(socket.assigns, :selected_page)

    selected_page =
      cond do
        socket.assigns.following_session ->
          latest_capture(socket.assigns)

        selected_page && Enum.any?(socket.assigns.pages, &(&1.id == selected_page.id)) ->
          selected_page

        true ->
          latest_capture(socket.assigns)
      end

    assign(socket,
      selected_page: selected_page,
      selected_annotations: annotations_for(socket.assigns.run, selected_page)
    )
  end

  defp select_latest_capture(socket) do
    page = latest_capture(socket.assigns)

    assign(socket,
      selected_page: page,
      selected_annotations: annotations_for(socket.assigns.run, page)
    )
  end

  defp latest_capture(assigns) do
    latest_page_id =
      assigns.capture_events
      |> List.last()
      |> case do
        nil -> nil
        event -> event.page_id
      end

    Enum.find(assigns.pages, &(&1.id == latest_page_id)) || List.last(assigns.pages)
  end

  defp annotations_for(_run, nil), do: []

  defp annotations_for(run, page) do
    run.occurrences
    |> Enum.filter(&(&1.page_id == page.id))
    |> Enum.sort_by(&severity_rank(&1.finding.severity))
  end

  defp reload_findings(socket) do
    run_id = if socket.assigns.live_action == :project_quality_run, do: socket.assigns.run.id

    assign(socket,
      findings: Quality.list_findings(socket.assigns.project, run_id: run_id)
    )
  end

  defp assign_profile_form(socket, profile) do
    form = Quality.change_profile(profile) |> to_form(as: :profile)

    assign(socket,
      profile: profile,
      profile_form: form,
      site_url: Map.get(profile.locale_origins || %{}, profile.source_locale || "en", "")
    )
  end

  defp require_quality_read!(socket), do: require_quality!(socket, :quality_read)
  defp require_quality_write!(socket), do: require_quality!(socket, :quality_write)
  defp require_quality_admin!(socket), do: require_quality!(socket, :quality_admin)

  defp require_quality!(socket, action) do
    unless Glossia.Authz.authorize?(action, socket.assigns.current_user, socket.assigns.account) do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Project
    end
  end

  defp quality_error(%Ecto.Changeset{}), do: gettext("Please review the invalid values.")

  defp quality_error(:quality_run_already_active),
    do: gettext("A localization QA run is already pending or running for this project.")

  defp quality_error(:quality_run_not_active),
    do: gettext("This localization QA run is no longer pending or running.")

  defp quality_error(reason) when is_atom(reason), do: reason |> Atom.to_string() |> humanize()
  defp quality_error(_reason), do: gettext("The localization QA request could not be completed.")

  defp humanize(value), do: value |> String.replace("_", " ") |> String.capitalize()

  defp run_status("completed"), do: "success"
  defp run_status("failed"), do: "error"
  defp run_status("running"), do: "in_progress"
  defp run_status("pending"), do: "attention"
  defp run_status(_status), do: "disabled"

  defp terminal_run?(run), do: run.status in ["completed", "failed", "cancelled"]

  defp finding_status("resolved"), do: "success"
  defp finding_status("dismissed"), do: "disabled"
  defp finding_status("acknowledged"), do: "in_progress"
  defp finding_status(_status), do: "attention"

  defp severity_color("high"), do: "destructive"
  defp severity_color("medium"), do: "warning"
  defp severity_color("low"), do: "information"
  defp severity_color(_severity), do: "neutral"

  defp severity_rank("high"), do: 0
  defp severity_rank("medium"), do: 1
  defp severity_rank("low"), do: 2
  defp severity_rank(_severity), do: 3

  defp event_icon("session_started"), do: "player_play"
  defp event_icon("navigation_started"), do: "devices_browser"
  defp event_icon("page_captured"), do: "photo"
  defp event_icon("analysis_started"), do: "eye"
  defp event_icon("finding_recorded"), do: "alert_circle"
  defp event_icon("session_completed"), do: "circle_check"
  defp event_icon("session_failed"), do: "alert_hexagon"
  defp event_icon("session_cancelled"), do: "circle_x"
  defp event_icon(_kind), do: "timeline_event"

  defp event_color("page_captured"), do: "information"
  defp event_color("finding_recorded"), do: "warning"
  defp event_color("session_completed"), do: "success"
  defp event_color("session_failed"), do: "destructive"
  defp event_color("session_cancelled"), do: "neutral"
  defp event_color(_kind), do: "primary"

  # Every event in the timeline records the start of a step, so only the newest one on a run that
  # is still going can still be happening. Anything a later event has already superseded — or
  # anything at all once the run is terminal — is settled, and keeping those badges spinning is
  # what made a finished run read as stuck.
  defp event_settled?(run, index, last_index),
    do: index < last_index or terminal_run?(run)

  defp event_status(%{kind: "session_completed"}, _settled?), do: "success"
  defp event_status(%{kind: "session_failed"}, _settled?), do: "error"
  defp event_status(%{kind: "session_cancelled"}, _settled?), do: "disabled"
  defp event_status(%{kind: "finding_recorded"}, _settled?), do: "warning"
  defp event_status(%{kind: "page_captured"}, _settled?), do: "success"
  defp event_status(_event, true), do: "success"
  defp event_status(_event, false), do: "in_progress"

  defp event_status_label(%{kind: "finding_recorded", metadata: metadata}, _settled?) do
    humanize(metadata["severity"] || "finding")
  end

  defp event_status_label(%{kind: "session_started"}, _settled?), do: gettext("Started")
  defp event_status_label(%{kind: "navigation_started"}, true), do: gettext("Opened")
  defp event_status_label(%{kind: "navigation_started"}, false), do: gettext("Opening")
  defp event_status_label(%{kind: "page_captured"}, _settled?), do: gettext("Captured")
  defp event_status_label(%{kind: "analysis_started"}, true), do: gettext("Analyzed")
  defp event_status_label(%{kind: "analysis_started"}, false), do: gettext("Analyzing")
  defp event_status_label(%{kind: "session_completed"}, _settled?), do: gettext("Completed")
  defp event_status_label(%{kind: "session_failed"}, _settled?), do: gettext("Failed")
  defp event_status_label(%{kind: "session_cancelled"}, _settled?), do: gettext("Cancelled")
  defp event_status_label(_event, true), do: gettext("Done")
  defp event_status_label(_event, false), do: gettext("In progress")

  defp elapsed_time(run, event), do: run |> elapsed_seconds(event) |> format_elapsed_time()

  defp elapsed_seconds(%{started_at: nil}, _event), do: 0

  defp elapsed_seconds(run, event) do
    max(DateTime.diff(event.inserted_at, run.started_at, :second), 0)
  end

  defp format_elapsed_time(seconds) do
    minutes = div(seconds, 60)
    remainder = rem(seconds, 60)

    String.pad_leading(to_string(minutes), 2, "0") <>
      ":" <> String.pad_leading(to_string(remainder), 2, "0")
  end

  defp session_duration(run, events) do
    events
    |> List.last()
    |> case do
      nil -> 1
      event -> max(elapsed_seconds(run, event), 1)
    end
  end

  defp replay_frames(run, capture_events) do
    Enum.map(capture_events, fn event ->
      %{"pageId" => to_string(event.page_id), "time" => elapsed_seconds(run, event)}
    end)
  end

  defp finding_events(events),
    do: Enum.filter(events, &(&1.kind == "finding_recorded" and &1.page_id))

  defp replay_position(nil, _run, _events), do: nil

  defp replay_position(value, run, events) do
    case Integer.parse(to_string(value)) do
      {position, ""} -> min(max(position, 0), session_duration(run, events))
      _ -> nil
    end
  end

  defp selected_capture_position(run, capture_events, page) do
    capture_events
    |> Enum.find(&(&1.page_id == page.id))
    |> case do
      nil -> 0
      event -> elapsed_seconds(run, event)
    end
  end

  defp timeline_position(run, event, events) do
    elapsed_seconds(run, event) / session_duration(run, events) * 100
  end

  defp preview_text(nil), do: gettext("No text was captured for this page.")
  defp preview_text(""), do: gettext("No text was captured for this page.")

  defp preview_text(text) do
    if String.length(text) > 800, do: String.slice(text, 0, 800) <> "…", else: text
  end

  defp run_duration(run) do
    started_at = run.started_at || run.inserted_at
    completed_at = run.completed_at || DateTime.utc_now()
    seconds = max(DateTime.diff(completed_at, started_at, :second), 0)
    minutes = div(seconds, 60)
    remainder = rem(seconds, 60)

    if minutes > 0 do
      gettext("%{minutes}m %{seconds}s", minutes: minutes, seconds: remainder)
    else
      gettext("%{seconds}s", seconds: remainder)
    end
  end

  def render(assigns) do
    ~H"""
    <section id="quality-page" class="dash-page">
      <%= case @live_action do %>
        <% :project_quality -> %>
          <.overview assigns={assigns} />
        <% :project_quality_run -> %>
          <.run_detail assigns={assigns} />
        <% :project_quality_settings -> %>
          <.settings assigns={assigns} />
      <% end %>
    </section>
    """
  end

  attr :assigns, :map, required: true

  defp overview(%{assigns: page_assigns} = assigns) do
    assigns = assign(assigns, page: page_assigns)

    ~H"""
    <.page_header
      title={gettext("Localization QA")}
      description={
        gettext(
          "Verify translations and localized product experiences by navigating the product as a user would."
        )
      }
    >
      <:actions>
        <Noora.Button.button
          :if={@page.can_quality_admin}
          label={gettext("Settings")}
          variant="secondary"
          size="medium"
          navigate={~p"/#{@page.handle}/#{@page.project.handle}/-/qa/settings"}
        />
        <Noora.Button.button
          :if={@page.can_quality_write}
          label={gettext("Run QA")}
          size="medium"
          disabled={is_nil(@page.profile)}
          phx-click="start_quality_run"
        />
      </:actions>
    </.page_header>

    <Noora.Alert.alert
      :if={is_nil(@page.profile)}
      status="warning"
      size="large"
      title={gettext("Configuration required")}
      description={
        gettext(
          "Add the web address for each locale and at least one path before running an inspection."
        )
      }
    >
      <:action :if={@page.can_quality_admin}>
        <Noora.Button.button
          label={gettext("Configure")}
          size="small"
          navigate={~p"/#{@page.handle}/#{@page.project.handle}/-/qa/settings"}
        />
      </:action>
    </Noora.Alert.alert>

    <Noora.Card.card icon="book" title={gettext("Reviewed project memory")}>
      <Noora.Card.card_section data-part="memory-section">
        <%= if @page.project_context do %>
          <div data-part="memory-summary">
            <div data-part="metadata">
              <div data-part="title">{gettext("Version")}</div>
              <Noora.Badge.badge
                label={to_string(@page.project_context.version)}
                color="information"
                style="light-fill"
              />
            </div>
            <div data-part="metadata">
              <div data-part="title">{gettext("Approved instructions")}</div>
              <span data-part="label">{length(@page.project_context.entries)}</span>
            </div>
            <p data-part="memory-hint">
              {gettext("Future translations are grounded in these instructions.")}
            </p>
          </div>
        <% else %>
          <.noora_empty_state
            icon="book"
            title={gettext("No project memory yet")}
            subtitle={
              gettext("Approve a QA finding to turn it into context for future translations.")
            }
          />
        <% end %>
      </Noora.Card.card_section>
    </Noora.Card.card>

    <.runs_table
      runs={@page.runs}
      meta={@page.runs_meta}
      handle={@page.handle}
      project={@page.project}
    />
    <.findings_table findings={@page.findings} can_write={@page.can_quality_write} />
    """
  end

  attr :assigns, :map, required: true

  defp run_detail(%{assigns: page_assigns} = assigns) do
    assigns = assign(assigns, page: page_assigns)

    ~H"""
    <.page_header
      title={gettext("QA run")}
      description={gettext("Browser evidence and findings from this QA run.")}
    >
      <:actions>
        <Noora.Button.button
          :if={@page.can_quality_write and @page.run.status in ["pending", "running"]}
          label={gettext("Cancel run")}
          variant="destructive"
          size="medium"
          phx-click="cancel_quality_run"
          data-confirm={gettext("Are you sure you want to cancel this localization QA run?")}
        />
        <Noora.Button.button
          label={gettext("All QA runs")}
          variant="secondary"
          size="medium"
          navigate={~p"/#{@page.handle}/#{@page.project.handle}/-/qa"}
        />
      </:actions>
    </.page_header>

    <Noora.Alert.alert
      :if={@page.run.status == "failed"}
      status="error"
      size="large"
      title={gettext("QA run failed")}
      description={@page.run.error}
    />

    <Noora.Card.card id="quality-run-details" icon="checkup_list" title={gettext("Run details")}>
      <Noora.Card.card_section data-part="run-details-section">
        <div data-part="metadata-grid">
          <div data-part="metadata-row">
            <div data-part="metadata">
              <div data-part="title">{gettext("Status")}</div>
              <Noora.Badge.status_badge
                status={run_status(@page.run.status)}
                label={humanize(@page.run.status)}
              />
            </div>
            <div data-part="metadata">
              <div data-part="title">{gettext("Duration")}</div>
              <span data-part="label">
                <Noora.Icon.icon name="history" />
                {run_duration(@page.run)}
              </span>
            </div>
            <div data-part="metadata">
              <div data-part="title">{gettext("Pages inspected")}</div>
              <span data-part="label">{@page.run.pages_count}</span>
            </div>
            <div data-part="metadata">
              <div data-part="title">{gettext("Findings")}</div>
              <span data-part="label">{@page.run.findings_count}</span>
            </div>
          </div>
        </div>
      </Noora.Card.card_section>
    </Noora.Card.card>

    <Noora.Card.card
      id="quality-session-viewer"
      icon="player_play"
      title={gettext("Session replay")}
    >
      <:actions>
        <Noora.Badge.badge
          :if={@page.run.status == "running"}
          label={gettext("Live")}
          color="destructive"
          style="light-fill"
          dot
        />
        <Noora.Button.button
          :if={@page.run.status == "running" and not @page.following_session}
          label={gettext("Follow live")}
          variant="secondary"
          size="small"
          phx-click="follow_quality_session"
        />
      </:actions>

      <Noora.Card.card_section data-part="capture-section">
        <%= if @page.selected_page do %>
          <% replay_duration = session_duration(@page.run, @page.session_events) %>
          <% replay_position =
            @page.replay_position ||
              selected_capture_position(
                @page.run,
                @page.capture_events,
                @page.selected_page
              ) %>
          <div data-part="capture-details">
            <div data-part="capture-title">
              <strong>{@page.selected_page.title || @page.selected_page.logical_path}</strong>
              <span>{@page.selected_page.final_url || @page.selected_page.requested_url}</span>
            </div>
            <div data-part="capture-badges">
              <Noora.Badge.badge
                label={@page.selected_page.locale}
                color="information"
                style="light-fill"
              />
              <Noora.Badge.badge
                label={
                  gettext("Document language: %{locale}",
                    locale: @page.selected_page.document_locale || gettext("Not declared")
                  )
                }
                color="neutral"
                style="light-fill"
              />
            </div>
          </div>

          <div
            id="quality-session-replay"
            phx-hook=".QualitySessionReplay"
            data-duration={replay_duration}
            data-position={replay_position}
            data-selected-page-id={@page.selected_page.id}
            data-frames={Jason.encode!(replay_frames(@page.run, @page.capture_events))}
            data-play-label={gettext("Play replay")}
            data-pause-label={gettext("Pause replay")}
          >
            <figure id="quality-session-capture">
              <img
                :if={@page.selected_page.screenshot_path}
                src={
                  ~p"/#{@page.handle}/#{@page.project.handle}/-/qa/runs/#{@page.run.id}/pages/#{@page.selected_page.id}/screenshot"
                }
                alt={gettext("Captured page %{path}", path: @page.selected_page.logical_path)}
              />
              <article :if={is_nil(@page.selected_page.screenshot_path)} data-part="text-preview">
                <p data-part="preview-eyebrow">{gettext("Page text snapshot")}</p>
                <h3>{@page.selected_page.title || @page.selected_page.logical_path}</h3>
                <p>{preview_text(@page.selected_page.visible_text)}</p>
              </article>
            </figure>

            <div data-part="replay-controls">
              <Noora.Button.button
                label={gettext("Play replay")}
                variant="secondary"
                size="small"
                type="button"
                data-part="play-button"
                aria-label={gettext("Play replay")}
              >
                <:icon_left>
                  <span data-part="play-icon"><Noora.Icon.icon name="player_play" /></span>
                  <span data-part="pause-icon"><Noora.Icon.icon name="player_pause" /></span>
                </:icon_left>
              </Noora.Button.button>

              <div data-part="replay-transport">
                <div data-part="replay-scrubber">
                  <input
                    id="quality-session-replay-range"
                    type="range"
                    min="0"
                    max={replay_duration}
                    value={replay_position}
                    step="1"
                    aria-label={gettext("Replay position")}
                    style={"--replay-progress: #{replay_position / replay_duration * 100}%;"}
                  />
                  <div data-part="finding-markers" aria-label={gettext("Findings on the replay")}>
                    <button
                      :for={event <- finding_events(@page.session_events)}
                      type="button"
                      data-part="finding-marker"
                      data-time={elapsed_seconds(@page.run, event)}
                      data-severity={event.metadata["severity"] || "medium"}
                      phx-click="select_quality_capture"
                      phx-value-page-id={event.page_id}
                      phx-value-at={elapsed_seconds(@page.run, event)}
                      style={
                        "--marker-position: #{timeline_position(@page.run, event, @page.session_events)}%;"
                      }
                      title={
                        gettext("%{finding} at %{time}",
                          finding: event.label,
                          time: elapsed_time(@page.run, event)
                        )
                      }
                      aria-label={
                        gettext("%{finding} at %{time}",
                          finding: event.label,
                          time: elapsed_time(@page.run, event)
                        )
                      }
                    >
                      <Noora.Icon.icon name="alert_circle" />
                    </button>
                  </div>
                </div>
                <span data-part="replay-time">
                  {format_elapsed_time(replay_position)} / {format_elapsed_time(replay_duration)}
                </span>
              </div>
            </div>
          </div>

          <script :type={Phoenix.LiveView.ColocatedHook} name=".QualitySessionReplay">
            export default {
              mounted() {
                this.playing = false;
                this.refreshData();
                this.position = this.serverPosition();
                this.currentPageId = this.el.dataset.selectedPageId;

                this.playButton = this.el.querySelector('[data-part="play-button"]');
                this.onPlayClick = () => this.playing ? this.pause() : this.play();

                this.onClick = (event) => {
                  const marker = event.target.closest('[data-part="finding-marker"]');
                  if (marker) {
                    this.pause();
                    this.position = Number(marker.dataset.time);
                    this.render();
                  }
                };

                this.onInput = (event) => {
                  if (event.target.id !== 'quality-session-replay-range') return;
                  this.pause();
                  this.position = Number(event.target.value);
                  this.render();
                };

                this.onChange = (event) => {
                  if (event.target.id !== 'quality-session-replay-range') return;
                  this.selectFrame(this.position);
                };

                // A capture is taller than the frame it is shown in, so the pan below is what
                // makes the replay read as a recording of someone scrolling the page. `load`
                // does not bubble, hence the capture-phase listener: it has to fire for the
                // <img> LiveView swaps in on every capture change, before its height is known.
                this.onLoad = (event) => {
                  if (event.target.tagName === 'IMG') this.render();
                };

                this.playButton?.addEventListener('click', this.onPlayClick);
                this.el.addEventListener('click', this.onClick);
                this.el.addEventListener('input', this.onInput);
                this.el.addEventListener('change', this.onChange);
                this.el.addEventListener('load', this.onLoad, true);
                this.render();
              },

              updated() {
                this.refreshData();
                this.currentPageId = this.el.dataset.selectedPageId;
                if (!this.playing) this.position = this.serverPosition();
                this.render();
              },

              destroyed() {
                cancelAnimationFrame(this.animationFrame);
                this.playButton?.removeEventListener('click', this.onPlayClick);
                this.el.removeEventListener('click', this.onClick);
                this.el.removeEventListener('input', this.onInput);
                this.el.removeEventListener('change', this.onChange);
                this.el.removeEventListener('load', this.onLoad, true);
              },

              refreshData() {
                this.duration = Math.max(Number(this.el.dataset.duration), 1);
                this.frames = JSON.parse(this.el.dataset.frames || '[]');
              },

              serverPosition() {
                return Math.min(Math.max(Number(this.el.dataset.position), 0), this.duration);
              },

              play() {
                if (this.position >= this.duration) this.position = 0;
                this.playing = true;
                this.startedAt = performance.now() - this.position * 1000;
                this.render();
                this.tick();
              },

              pause() {
                this.playing = false;
                cancelAnimationFrame(this.animationFrame);
                this.render();
              },

              tick() {
                if (!this.playing) return;
                this.position = Math.min((performance.now() - this.startedAt) / 1000, this.duration);
                this.selectFrame(this.position);
                this.render();

                if (this.position >= this.duration) this.pause();
                else this.animationFrame = requestAnimationFrame(() => this.tick());
              },

              selectFrame(position) {
                const frame = this.frames.reduce(
                  (selected, candidate) => candidate.time <= position ? candidate : selected,
                  this.frames[0]
                );

                if (!frame || frame.pageId === this.currentPageId) return;
                this.currentPageId = frame.pageId;
                this.pushEvent('select_quality_capture', {
                  'page-id': frame.pageId,
                  at: Math.round(position).toString()
                });
              },

              // How far into the currently visible capture the playhead is, from 0 to 1. Each
              // capture owns the stretch of the timeline between its own event and the next
              // one, so a page that was on screen for a long time scrolls slowly.
              captureProgress() {
                if (!this.frames.length) return 0;

                let index = 0;
                this.frames.forEach((frame, frameIndex) => {
                  if (frame.time <= this.position) index = frameIndex;
                });

                const start = this.frames[index].time;
                const end = index + 1 < this.frames.length
                  ? this.frames[index + 1].time
                  : this.duration;
                const span = end - start;

                if (span <= 0) return this.position >= end ? 1 : 0;
                return Math.min(Math.max((this.position - start) / span, 0), 1);
              },

              renderCapture() {
                const capture = this.el.querySelector('#quality-session-capture');
                const image = capture && capture.querySelector('img');
                if (!capture) return;

                const overflow = image ? image.offsetHeight - capture.clientHeight : 0;
                const offset = overflow > 0 ? -overflow * this.captureProgress() : 0;
                capture.style.setProperty('--capture-scroll', `${Math.round(offset)}px`);
              },

              render() {
                const range = this.el.querySelector('#quality-session-replay-range');
                const time = this.el.querySelector('[data-part="replay-time"]');
                const button = this.el.querySelector('[data-part="play-button"]');
                const progress = this.position / this.duration * 100;

                this.el.dataset.playing = this.playing ? 'true' : 'false';
                if (range) {
                  range.value = Math.round(this.position);
                  range.style.setProperty('--replay-progress', `${progress}%`);
                }
                if (time) time.textContent = `${this.formatTime(this.position)} / ${this.formatTime(this.duration)}`;
                if (button) {
                  const label = this.playing ? this.el.dataset.pauseLabel : this.el.dataset.playLabel;
                  button.setAttribute('aria-label', label);
                  const labelNode = button.querySelector(':scope > span:not([data-part])');
                  if (labelNode) labelNode.textContent = label;
                }
                this.renderCapture();
              },

              formatTime(value) {
                const seconds = Math.max(Math.round(value), 0);
                return `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
              }
            }
          </script>

          <section data-part="capture-annotations" aria-label={gettext("Annotations")}>
            <header data-part="section-header">
              <div>
                <h3>{gettext("Agent annotations")}</h3>
                <p>{gettext("Findings recorded while this capture was visible.")}</p>
              </div>
              <Noora.Badge.badge
                label={
                  ngettext(
                    "%{count} finding",
                    "%{count} findings",
                    length(@page.selected_annotations),
                    count: length(@page.selected_annotations)
                  )
                }
                color="neutral"
                style="light-fill"
              />
            </header>
            <Noora.Table.table
              id="quality-capture-annotations"
              rows={@page.selected_annotations}
              row_key={fn occurrence -> "quality-capture-annotation-#{occurrence.id}" end}
            >
              <:col :let={occurrence} label={gettext("Finding")}>
                <Noora.Table.text_and_description_cell
                  label={occurrence.finding.title}
                  description={occurrence.finding.description}
                  icon="alert_circle"
                />
              </:col>
              <:col :let={occurrence} label={gettext("Severity")}>
                <Noora.Table.badge_cell
                  label={humanize(occurrence.finding.severity)}
                  color={severity_color(occurrence.finding.severity)}
                  style="light-fill"
                />
              </:col>
              <:empty_state>
                <Noora.Table.table_empty_state>
                  <.noora_empty_state
                    icon="circle_check"
                    title={gettext("No annotations")}
                    subtitle={gettext("No issues were found on this capture.")}
                  />
                </Noora.Table.table_empty_state>
              </:empty_state>
            </Noora.Table.table>
          </section>
        <% else %>
          <div id="quality-session-capture" data-part="waiting-state">
            <.noora_empty_state
              icon="devices_browser"
              title={
                if terminal_run?(@page.run),
                  do: gettext("Replay evidence expired"),
                  else: gettext("Preparing the browser")
              }
              subtitle={
                if terminal_run?(@page.run),
                  do: gettext("Detailed browser evidence is retained for the 20 most recent runs."),
                  else:
                    gettext(
                      "Captures and annotations will appear here as the agent reviews the site."
                    )
              }
            />
          </div>
        <% end %>
      </Noora.Card.card_section>
    </Noora.Card.card>

    <Noora.Card.card
      id="quality-session-activity"
      icon="timeline_event"
      title={gettext("Agent activity")}
    >
      <Noora.Card.card_section data-part="activity-section">
        <div id="quality-session-events" data-part="timeline">
          <% last_event_index = length(@page.session_events) - 1 %>
          <div
            :for={{event, index} <- Enum.with_index(@page.session_events)}
            data-part="timeline-item"
            data-kind={event.kind}
          >
            <div data-part="timeline-icon" data-color={event_color(event.kind)}>
              <Noora.Icon.icon name={event_icon(event.kind)} />
            </div>
            <div data-part="timeline-content">
              <span data-part="timeline-title">{event.label}</span>
              <span :if={event.detail not in [nil, ""]} data-part="timeline-subtitle">
                {event.detail}
              </span>
            </div>
            <.event_badge
              event={event}
              settled={event_settled?(@page.run, index, last_event_index)}
            />
            <time data-part="timeline-time">{elapsed_time(@page.run, event)}</time>
          </div>

          <div :if={@page.session_events == []} data-part="timeline-empty">
            <.noora_empty_state
              icon="hourglass"
              title={
                if terminal_run?(@page.run),
                  do: gettext("Activity details expired"),
                  else: gettext("Waiting for activity")
              }
              subtitle={
                if terminal_run?(@page.run),
                  do: gettext("Run totals and reviewed findings remain available."),
                  else: gettext("The first browser event will appear here shortly.")
              }
            />
          </div>
        </div>
      </Noora.Card.card_section>
    </Noora.Card.card>

    <.findings_table findings={@page.findings} can_write={@page.can_quality_write} />
    """
  end

  attr :assigns, :map, required: true

  defp settings(%{assigns: page_assigns} = assigns) do
    assigns = assign(assigns, page: page_assigns)

    ~H"""
    <.page_header
      title={gettext("QA settings")}
      description={gettext("Choose the website Glossia inspects when it runs localization QA.")}
    />

    <.form id="quality-profile-form" for={@page.profile_form} phx-submit="save_quality_profile">
      <section data-part="settings-section">
        <header data-part="settings-section-header">
          <h2>{gettext("Website")}</h2>
          <p>
            {gettext(
              "Glossia opens this address and navigates it the way a user would, one locale at a time."
            )}
          </p>
        </header>

        <Noora.Card.card_section data-part="settings-card">
          <Noora.TextInput.text_input
            id="quality-site-url"
            name="profile[site_url]"
            value={@page.site_url}
            label={gettext("Website URL")}
            hint={gettext("For example, https://example.com")}
            placeholder="https://example.com"
            input_type="url"
            required
          />
          <div data-part="settings-actions">
            <Noora.Button.button label={gettext("Save settings")} size="medium" type="submit" />
          </div>
        </Noora.Card.card_section>
      </section>
    </.form>
    """
  end

  attr :event, :any, required: true
  attr :settled, :boolean, required: true

  defp event_badge(assigns) do
    ~H"""
    <Noora.Badge.status_badge
      status={event_status(@event, @settled)}
      label={event_status_label(@event, @settled)}
    />
    """
  end

  attr :runs, :list, required: true
  attr :meta, :any, required: true
  attr :handle, :string, required: true
  attr :project, :any, required: true

  defp runs_table(assigns) do
    ~H"""
    <Noora.Card.card icon="history" title={gettext("QA runs")}>
      <Noora.Card.card_section class="noora-resource-table-card">
        <Noora.Table.table id="quality-runs-table" rows={@runs}>
          <:col :let={run} label={gettext("Status")}>
            <Noora.Table.status_badge_cell
              status={run_status(run.status)}
              label={humanize(run.status)}
            />
          </:col>
          <:col :let={run} label={gettext("Pages")}>
            <Noora.Table.text_cell label={to_string(run.pages_count)} />
          </:col>
          <:col :let={run} label={gettext("Findings")}>
            <Noora.Table.text_cell label={to_string(run.findings_count)} />
          </:col>
          <:col :let={run} label={gettext("Started")}>
            <Noora.Table.time_cell time={run.started_at || run.inserted_at} show_time />
          </:col>
          <:col :let={run} label={gettext("Actions")}>
            <Noora.Table.button_cell>
              <:button>
                <Noora.Button.button
                  label={gettext("View")}
                  variant="secondary"
                  size="small"
                  navigate={~p"/#{@handle}/#{@project.handle}/-/qa/runs/#{run.id}"}
                />
              </:button>
            </Noora.Table.button_cell>
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="checkup_list"
                title={gettext("No QA runs yet")}
                subtitle={gettext("Run QA to compare the localized product experience.")}
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
        <Noora.PaginationGroup.pagination_group
          :if={@meta.total_pages > 1}
          current_page={@meta.current_page}
          number_of_pages={@meta.total_pages}
          page_patch={fn page -> ~p"/#{@handle}/#{@project.handle}/-/qa?#{%{page: page}}" end}
          data-part="pagination"
        />
      </Noora.Card.card_section>
    </Noora.Card.card>
    """
  end

  attr :findings, :list, required: true
  attr :can_write, :boolean, required: true

  defp findings_table(assigns) do
    ~H"""
    <Noora.Card.card icon="alert_circle" title={gettext("Findings")}>
      <Noora.Card.card_section class="noora-resource-table-card">
        <Noora.Table.table id="quality-findings-table" rows={@findings}>
          <:col :let={finding} label={gettext("Finding")}>
            <Noora.Table.text_and_description_cell
              label={finding.title}
              description={finding.description}
            />
          </:col>
          <:col :let={finding} label={gettext("Location")}>
            <Noora.Table.text_and_description_cell
              label={finding.locale || gettext("All locales")}
              description={finding.logical_path || gettext("All paths")}
            />
          </:col>
          <:col :let={finding} label={gettext("Severity")}>
            <Noora.Table.badge_cell
              label={humanize(finding.severity)}
              color={severity_color(finding.severity)}
            />
          </:col>
          <:col :let={finding} label={gettext("Status")}>
            <Noora.Table.status_badge_cell
              status={finding_status(finding.status)}
              label={humanize(finding.status)}
            />
          </:col>
          <:col :let={finding} :if={@can_write}>
            <form
              :if={rememberable_finding?(finding)}
              id={"quality-memory-form-#{finding.id}"}
              phx-submit="remember_translation"
            >
              <input type="hidden" name="finding_id" value={finding.id} />

              <Noora.Modal.modal
                id={"quality-memory-modal-#{finding.id}"}
                title={gettext("Remember translation")}
                description={
                  gettext(
                    "Save an approved translation as project context for future translation runs."
                  )
                }
                header_type="icon"
              >
                <:header_icon><Noora.Icon.language /></:header_icon>
                <:trigger :let={modal_attrs}>
                  <button type="button" hidden {modal_attrs}></button>
                </:trigger>

                <div data-part="memory-modal-content">
                  <Noora.LineDivider.line_divider />
                  <div data-part="memory-modal-body">
                    <Noora.TextInput.text_input
                      id={"quality-memory-#{finding.id}"}
                      name="translation"
                      value=""
                      label={gettext("Approved translation")}
                      placeholder={gettext("Enter the preferred translation")}
                      show_prefix={false}
                      show_suffix={false}
                      required
                      show_required
                    />
                  </div>
                  <Noora.LineDivider.line_divider />
                </div>

                <:footer>
                  <Noora.Modal.modal_footer>
                    <:action>
                      <Noora.Button.button
                        label={gettext("Cancel")}
                        variant="secondary"
                        type="button"
                        phx-click={
                          JS.dispatch("phx:close-modal",
                            detail: %{id: "quality-memory-modal-#{finding.id}"}
                          )
                        }
                      />
                    </:action>
                    <:action>
                      <Noora.Button.button label={gettext("Remember translation")} type="submit" />
                    </:action>
                  </Noora.Modal.modal_footer>
                </:footer>
              </Noora.Modal.modal>
            </form>

            <Noora.Dropdown.dropdown
              id={"quality-finding-actions-#{finding.id}"}
              icon_only
              size="medium"
            >
              <:icon><Noora.Icon.dots_vertical /></:icon>

              <Noora.Dropdown.dropdown_item
                :if={rememberable_finding?(finding)}
                label={gettext("Remember translation")}
                value="remember"
                phx-click={
                  JS.dispatch("phx:open-modal",
                    detail: %{id: "quality-memory-modal-#{finding.id}"}
                  )
                }
              >
                <:left_icon><Noora.Icon.language /></:left_icon>
              </Noora.Dropdown.dropdown_item>

              <Noora.Dropdown.dropdown_separator :if={
                rememberable_finding?(finding) and
                  finding.status not in ["resolved", "dismissed"]
              } />

              <Noora.Dropdown.dropdown_item
                :if={finding.status not in ["resolved", "dismissed"]}
                label={gettext("Resolve")}
                value="resolve"
                phx-click="update_finding"
                phx-value-id={finding.id}
                phx-value-status="resolved"
              >
                <:left_icon><Noora.Icon.circle_check /></:left_icon>
              </Noora.Dropdown.dropdown_item>

              <Noora.Dropdown.dropdown_item
                :if={finding.status not in ["resolved", "dismissed"]}
                label={gettext("Dismiss")}
                value="dismiss"
                phx-click="update_finding"
                phx-value-id={finding.id}
                phx-value-status="dismissed"
              >
                <:left_icon><Noora.Icon.circle_x /></:left_icon>
              </Noora.Dropdown.dropdown_item>
            </Noora.Dropdown.dropdown>
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="circle_check"
                title={gettext("No findings")}
                subtitle={gettext("No localization QA findings match this view.")}
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
      </Noora.Card.card_section>
    </Noora.Card.card>
    """
  end

  defp rememberable_finding?(finding) do
    finding.source_text not in [nil, ""] and finding.locale not in [nil, ""]
  end
end
