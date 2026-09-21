defmodule BabelWeb.ErrorsLive.Show do
  @moduledoc """
  Issue detail page. Renders the issue header (title, culprit, level,
  status, seen timestamps), the resolve/reopen/ignore actions, panels
  for the latest event (stack trace, tags, contexts, request,
  breadcrumbs, additional data, modules, SDK), and a table of recent
  events linking through to the single-event view.
  """

  use BabelWeb, :live_view
  use Noora

  import BabelWeb.ErrorsLive.Components

  alias Babel.Errors
  alias Babel.Errors.LiveHelpers
  alias BabelWeb.Layouts

  def mount(%{"id" => id}, _session, socket) do
    organization = LiveHelpers.current_organization()

    case Errors.get_issue(organization.id, id) do
      {:ok, issue} ->
        events = Errors.list_events_for_issue(organization.id, issue.id, limit: 25)
        latest_event = List.first(events)
        latest_payload = event_payload(latest_event)

        {:ok,
         socket
         |> assign(:organization, organization)
         |> assign(:issue, issue)
         |> assign(:events, events)
         |> assign(:latest_event, latest_event)
         |> assign(:latest_payload, latest_payload)
         |> assign(:page_title, "Issue · #{issue.title}")}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Issue not found.")
         |> push_navigate(to: ~p"/errors")}
    end
  end

  def handle_params(_params, uri, socket) do
    parsed = URI.parse(uri)
    {:noreply, assign(socket, current_path: parsed.path || "/errors")}
  end

  def handle_event("resolve", _params, socket), do: transition(socket, :resolve)
  def handle_event("unresolve", _params, socket), do: transition(socket, :unresolve)
  def handle_event("ignore", _params, socket), do: transition(socket, :ignore)

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} live_action={@live_action}>
      <section id="error-issue">
        <div data-part="header">
          <div data-part="title-group">
            <div data-part="breadcrumbs">
              <.link navigate={~p"/errors"}>Errors</.link>
              <span data-part="separator">/</span>
              <span>{@issue.title |> truncate_title()}</span>
            </div>
            <h1 title={@issue.title}>{@issue.title}</h1>
            <p :if={@issue.culprit}>{@issue.culprit}</p>
          </div>
          <div data-part="header-actions">
            <.button
              :if={@issue.status != :resolved}
              variant="primary"
              label="Resolve"
              phx-click="resolve"
            />
            <.button
              :if={@issue.status == :resolved}
              variant="secondary"
              label="Reopen"
              phx-click="unresolve"
            />
            <.button
              :if={@issue.status != :ignored}
              variant="secondary"
              label="Ignore"
              phx-click="ignore"
            />
          </div>
        </div>

        <div data-part="summary">
          <.card title="Overview" icon="info_circle" id="error-overview-card">
            <.card_section>
              <dl data-part="stats">
                <div>
                  <dt>Status</dt>
                  <dd><.issue_status_badge status={@issue.status} /></dd>
                </div>
                <div>
                  <dt>Level</dt>
                  <dd><.issue_level_badge level={@issue.level} /></dd>
                </div>
                <div>
                  <dt>Events</dt>
                  <dd>{format_integer(@issue.event_count)}</dd>
                </div>
                <div>
                  <dt>Platform</dt>
                  <dd>{@issue.platform || "-"}</dd>
                </div>
                <div>
                  <dt>First seen</dt>
                  <dd title={format_datetime(@issue.first_seen)}>{relative_time(@issue.first_seen)}</dd>
                </div>
                <div>
                  <dt>Last seen</dt>
                  <dd title={format_datetime(@issue.last_seen)}>{relative_time(@issue.last_seen)}</dd>
                </div>
              </dl>
            </.card_section>
          </.card>
        </div>

        <.event_panels :if={@latest_event} issue={@issue} event={@latest_event} payload={@latest_payload} />

        <.card
          :if={@events != []}
          title="Recent events"
          icon="list_tree"
          id="error-events-card"
        >
          <.card_section>
            <.table id="error-events-table" rows={@events}>
              <:col :let={event} label="Time">
                <.link
                  navigate={~p"/errors/#{@issue.id}/events/#{normalize_event_id(event.event_id)}"}
                  data-part="event-link"
                >
                  <span title={format_datetime(event.timestamp)}>
                    {relative_time(event.timestamp)}
                  </span>
                </.link>
              </:col>
              <:col :let={event} label="Level"><.issue_level_badge level={event.level} /></:col>
              <:col :let={event} label="Environment">{event.environment || "-"}</:col>
              <:col :let={event} label="Release">{event.release || "-"}</:col>
              <:empty_state>
                <.table_empty_state
                  icon="list_tree"
                  title="No recent events"
                  subtitle="Events for this issue will appear here."
                />
              </:empty_state>
            </.table>
          </.card_section>
        </.card>
      </section>
    </Layouts.app>
    """
  end

  defp transition(socket, action) do
    result =
      case action do
        :resolve -> Errors.resolve_issue(socket.assigns.issue)
        :unresolve -> Errors.unresolve_issue(socket.assigns.issue)
        :ignore -> Errors.ignore_issue(socket.assigns.issue)
      end

    case result do
      {:ok, updated} ->
        {:noreply, assign(socket, :issue, updated)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update the issue.")}
    end
  end

  defp event_payload(nil), do: %{}

  defp event_payload(event) do
    case event.payload do
      %{} = payload ->
        payload

      payload when is_binary(payload) ->
        case JSON.decode(payload) do
          {:ok, %{} = decoded} -> decoded
          _ -> %{}
        end

      _ ->
        %{}
    end
  end
end
