defmodule BabelWeb.OperationsLive do
  use BabelWeb, :live_view
  use Noora

  alias Babel.Operations

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, uri, socket) do
    dashboard = Operations.dashboard()
    live_action = socket.assigns.live_action

    {:noreply,
     assign(socket,
       current_path: URI.parse(uri).path,
       dashboard: dashboard,
       page_title: page_title(live_action),
       visible_work_items: visible_work_items(live_action, dashboard.work_items)
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} live_action={@live_action}>
      <main id="operations" data-page={@live_action}>
        <div data-part="header">
          <div data-part="copy">
            <p data-part="eyebrow">Babel</p>
            <h1 data-part="title">{page_title(@live_action)}</h1>
            <p data-part="description">{page_description(@live_action)}</p>
          </div>
          <.button
            id="work-queue-button"
            label="View work queue"
            size="medium"
            variant="secondary"
            navigate={~p"/work-items"}
          >
            <:icon_left><.icon name="checkup_list" /></:icon_left>
          </.button>
        </div>

        <%= if @live_action == :overview do %>
          <section aria-label="Operational summary" data-part="metrics">
            <.metric_card label="Open work" value={@dashboard.open_count} icon="checkup_list" />
            <.metric_card label="Blocked" value={@dashboard.blocked_count} icon="alert_triangle" tone="warning" />
            <.metric_card
              label="Due this week"
              value={@dashboard.due_this_week_count}
              icon="calendar_week"
            />
            <.metric_card
              label="Completed"
              value={@dashboard.completed_count}
              icon="circle_check"
              tone="success"
            />
          </section>
        <% end %>

        <.card title={card_title(@live_action)} icon={card_icon(@live_action)} id="operations-work-card">
          <.card_section>
            <.table id="operations-work-items" rows={@visible_work_items}>
              <:col :let={work_item} label="Work item">
                <.text_and_description_cell
                  label={work_item.summary}
                  description={work_item.area}
                />
              </:col>
              <:col :let={work_item} label="Owner">
                <.text_cell label={work_item.assignee || "Unassigned"} />
              </:col>
              <:col :let={work_item} label="Priority">
                <.badge_cell
                  label={work_item.priority}
                  color={priority_color(work_item.priority)}
                  style="light-fill"
                />
              </:col>
              <:col :let={work_item} label="Due">
                <.text_cell label={format_date(work_item.due_on)} />
              </:col>
              <:col :let={work_item} label="Status">
                <.status_badge_cell
                  label={work_item.status}
                  status={status_kind(work_item.status)}
                />
              </:col>
              <:empty_state>
                <.table_empty_state
                  icon="checkup_list"
                  title="No work items yet"
                  subtitle="Seed or create an operational work item to start tracking it in Babel."
                />
              </:empty_state>
            </.table>
          </.card_section>
        </.card>
      </main>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :icon, :string, required: true
  attr :tone, :string, default: "primary"

  def metric_card(assigns) do
    ~H"""
    <.card title={@label} icon={@icon} data-part="metric-card" data-tone={@tone}>
      <.card_section>
        <p data-part="metric-value">{@value}</p>
      </.card_section>
    </.card>
    """
  end

  defp visible_work_items(:customers, work_items) do
    Enum.filter(work_items, &(&1.area == "Customer success"))
  end

  defp visible_work_items(:finance, work_items) do
    Enum.filter(work_items, &(&1.area == "Finance"))
  end

  defp visible_work_items(_live_action, work_items), do: work_items

  defp page_title(:overview), do: "Operations overview"
  defp page_title(:customers), do: "Customer operations"
  defp page_title(:work_items), do: "Work queue"
  defp page_title(:finance), do: "Finance operations"

  defp page_description(:overview), do: "A shared view of the work that keeps Glossia moving."

  defp page_description(:customers),
    do: "Customer commitments, adoption follow-up, and renewal preparation."

  defp page_description(:work_items), do: "The cross-functional queue for the operations team."
  defp page_description(:finance), do: "Commercial and finance work that needs a clear owner."

  defp card_title(:overview), do: "Priority queue"
  defp card_title(:customers), do: "Customer work"
  defp card_title(:work_items), do: "All work items"
  defp card_title(:finance), do: "Finance work"

  defp card_icon(:overview), do: "chart_donut_4"
  defp card_icon(:customers), do: "users"
  defp card_icon(:work_items), do: "checkup_list"
  defp card_icon(:finance), do: "file_text"

  defp priority_color("Urgent"), do: "destructive"
  defp priority_color("High"), do: "warning"
  defp priority_color("Normal"), do: "primary"
  defp priority_color(_priority), do: "neutral"

  defp status_kind("Done"), do: "success"
  defp status_kind("Blocked"), do: "error"
  defp status_kind("In progress"), do: "in_progress"
  defp status_kind(_status), do: "attention"

  defp format_date(nil), do: "No due date"
  defp format_date(due_on), do: Calendar.strftime(due_on, "%b %-d")
end
