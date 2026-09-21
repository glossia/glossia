defmodule BabelWeb.ErrorsLive.Index do
  @moduledoc """
  Issue list for the errors dashboard. URL-driven: `q` (search),
  `status` (filter), `sort` + `order` (column sort), `page`
  (pagination). Every interaction patches the URL so the table view is
  shareable and survives navigation.
  """

  use BabelWeb, :live_view
  use Noora

  import BabelWeb.ErrorsLive.Components

  alias Babel.Errors
  alias Babel.Errors.Issue
  alias Babel.Errors.LiveHelpers
  alias BabelWeb.Layouts
  alias Noora.Filter

  @page_size 25
  @sort_columns ~w(last_seen first_seen event_count title)

  def mount(_params, _session, socket) do
    organization = LiveHelpers.current_organization()

    {:ok,
     socket
     |> assign(:organization, organization)
     |> assign(:page_title, "Errors")
     |> assign(:available_filters, define_filters())}
  end

  def handle_params(params, uri, socket) do
    uri = URI.parse(uri)

    active_filters =
      Filter.Operations.decode_filters_from_query(params, socket.assigns.available_filters)

    query = params["q"] || ""
    {sort, order} = parse_sort(params)
    page = parse_page(params["page"])

    list_opts =
      [
        page: page,
        page_size: @page_size,
        sort: sort,
        direction: order,
        search: present_string(query)
      ]
      |> put_status_filter(active_filters)

    {issues, meta} = Errors.list_issues(socket.assigns.organization.id, list_opts)

    socket =
      socket
      |> assign(:current_path, uri.path || "/errors")
      |> assign(:uri, uri)
      |> assign(:issues, issues)
      |> assign(:issues_meta, meta)
      |> assign(:query, query)
      |> assign(:sort, sort)
      |> assign(:order, order)
      |> assign(:active_filters, active_filters)
      |> assign(:search_form, to_form(%{"query" => query}, as: :search))

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    trimmed = present_string(query)

    params =
      socket
      |> current_query_params()
      |> Map.delete("page")
      |> then(fn params ->
        if trimmed, do: Map.put(params, "q", trimmed), else: Map.delete(params, "q")
      end)

    {:noreply, push_patch(socket, to: patch_url(params), replace: true)}
  end

  def handle_event("add_filter", %{"value" => filter_id}, socket) do
    updated_params =
      socket
      |> current_query_params()
      |> Map.delete("page")
      |> then(&Filter.Operations.add_filter_to_query(filter_id, socket, &1))

    {:noreply,
     socket
     |> push_patch(to: patch_url(updated_params))
     |> push_event("open-dropdown", %{id: "filter-#{filter_id}-value-dropdown"})
     |> push_event("open-popover", %{id: "filter-#{filter_id}-value-popover"})}
  end

  def handle_event("update_filter", params, socket) do
    updated_params =
      socket
      |> current_query_params()
      |> Map.delete("page")
      |> then(&Filter.Operations.update_filters_in_query(params, socket, &1))

    {:noreply,
     socket
     |> push_patch(to: patch_url(updated_params))
     |> push_event("close-dropdown", %{id: "all", all: true})
     |> push_event("close-popover", %{id: "all", all: true})}
  end

  def handle_event("resolve_issue", %{"id" => id}, socket),
    do: transition_status(socket, id, :resolve)

  def handle_event("unresolve_issue", %{"id" => id}, socket),
    do: transition_status(socket, id, :unresolve)

  def handle_event("ignore_issue", %{"id" => id}, socket),
    do: transition_status(socket, id, :ignore)

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} live_action={@live_action}>
      <section id="errors">
        <div data-part="header">
          <div data-part="title-group">
            <h1>Errors</h1>
            <p>
              Unhandled exceptions captured from Glossia deployments and from Babel itself.
            </p>
          </div>
        </div>

        <.card title="Issues" icon="alert_circle" id="errors-issues-card">
          <.card_section>
            <div data-part="table-toolbar">
              <div data-part="left-controls">
                <.filter_dropdown
                  id="errors-filter"
                  label="Filter"
                  available_filters={@available_filters}
                  active_filters={@active_filters}
                  on_select="add_filter"
                />
              </div>

              <div data-part="search">
                <.form
                  id="errors-search-form"
                  for={@search_form}
                  phx-change="search"
                  phx-submit="search"
                >
                  <.text_input
                    id="errors-search"
                    field={@search_form[:query]}
                    type="search"
                    show_suffix={false}
                    placeholder="Search title or culprit..."
                  />
                </.form>
              </div>
            </div>

            <div :if={@active_filters != []} data-part="active-filters">
              <.active_filter :for={filter <- @active_filters} filter={filter} />
            </div>

            <.table id="errors-table" rows={@issues}>
              <:col
                :let={issue}
                label="Issue"
                patch={sort_patch(assigns, "title")}
                sort_order={@sort == :title && @order}
              >
                <.link navigate={~p"/errors/#{issue.id}"} data-part="issue-link">
                  <div data-part="issue-cell">
                    <div data-part="issue-title-row">
                      <span data-part="issue-title" title={issue.title}>
                        {truncate_title(issue.title)}
                      </span>
                    </div>
                    <span data-part="issue-meta">
                      <.issue_level_badge level={issue.level} />
                      <.issue_status_badge status={issue.status} />
                      <span data-part="culprit">{issue.culprit || "No location"}</span>
                    </span>
                  </div>
                </.link>
              </:col>
              <:col
                :let={issue}
                label="Last seen"
                patch={sort_patch(assigns, "last_seen")}
                sort_order={@sort == :last_seen && @order}
              >
                <span data-part="relative" title={format_datetime(issue.last_seen)}>
                  {relative_time(issue.last_seen)}
                </span>
              </:col>
              <:col
                :let={issue}
                label="Age"
                patch={sort_patch(assigns, "first_seen")}
                sort_order={@sort == :first_seen && @order}
              >
                <span data-part="relative" title={format_datetime(issue.first_seen)}>
                  {relative_time(issue.first_seen)}
                </span>
              </:col>
              <:col
                :let={issue}
                label="Events"
                patch={sort_patch(assigns, "event_count")}
                sort_order={@sort == :event_count && @order}
              >
                <span data-part="events">{format_integer(issue.event_count)}</span>
              </:col>
              <:col :let={issue} label="">
                <div data-part="row-actions">
                  <.button
                    :if={issue.status == :unresolved}
                    variant="secondary"
                    size="small"
                    label="Resolve"
                    phx-click="resolve_issue"
                    phx-value-id={issue.id}
                  />
                  <.button
                    :if={issue.status == :resolved}
                    variant="secondary"
                    size="small"
                    label="Reopen"
                    phx-click="unresolve_issue"
                    phx-value-id={issue.id}
                  />
                  <.button
                    :if={issue.status != :ignored}
                    variant="secondary"
                    size="small"
                    label="Ignore"
                    phx-click="ignore_issue"
                    phx-value-id={issue.id}
                  />
                </div>
              </:col>
              <:empty_state>
                <.table_empty_state
                  icon="alert_circle"
                  title="No issues yet"
                  subtitle={empty_subtitle(assigns)}
                />
              </:empty_state>
            </.table>

            <div :if={@issues_meta.total_pages > 1} data-part="pagination">
              <.button
                variant="secondary"
                label="Prev"
                disabled={@issues_meta.current_page <= 1}
                patch={page_link(assigns, max(1, @issues_meta.current_page - 1))}
              />
              <.button
                variant="secondary"
                label="Next"
                disabled={@issues_meta.current_page >= @issues_meta.total_pages}
                patch={
                  page_link(
                    assigns,
                    min(@issues_meta.total_pages, @issues_meta.current_page + 1)
                  )
                }
              />
            </div>
          </.card_section>
        </.card>
      </section>
    </Layouts.app>
    """
  end

  ## Sorting + URL helpers

  defp parse_sort(params) do
    sort =
      case params["sort"] do
        s when is_binary(s) and s in @sort_columns -> String.to_atom(s)
        _ -> :last_seen
      end

    order =
      case params["order"] do
        "asc" -> :asc
        _ -> :desc
      end

    {sort, order}
  end

  defp parse_page(nil), do: 1

  defp parse_page(value) do
    case Integer.parse(value) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  defp sort_patch(assigns, column) do
    current = current_query_params(assigns)
    current_sort = Atom.to_string(assigns.sort)
    current_order = Atom.to_string(assigns.order)

    next_order =
      cond do
        current_sort == column and current_order == "asc" -> "desc"
        current_sort == column and current_order == "desc" -> "asc"
        true -> "desc"
      end

    patch_url(
      current
      |> Map.put("sort", column)
      |> Map.put("order", next_order)
      |> Map.delete("page")
    )
  end

  defp page_link(assigns, page) do
    patch_url(Map.put(current_query_params(assigns), "page", Integer.to_string(page)))
  end

  defp patch_url(params) do
    case URI.encode_query(params) do
      "" -> ~p"/errors"
      query -> ~p"/errors" <> "?" <> query
    end
  end

  defp current_query_params(%{assigns: %{uri: %URI{query: query}}}) when is_binary(query),
    do: URI.decode_query(query)

  defp current_query_params(%{uri: %URI{query: query}}) when is_binary(query),
    do: URI.decode_query(query)

  defp current_query_params(_), do: %{}

  defp put_status_filter(opts, active_filters) do
    case Enum.find(active_filters, &(&1.id == "status")) do
      %{operator: :==, value: value} when is_binary(value) and value != "" ->
        Keyword.put(opts, :status, String.to_existing_atom(value))

      _ ->
        opts
    end
  end

  defp present_string(nil), do: nil

  defp present_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp empty_subtitle(%{query: q, active_filters: filters}) when q != "" or filters != [],
    do: "Adjust your search or filters to see more issues."

  defp empty_subtitle(_assigns),
    do: "Send events to POST /api/<project_id>/envelope/ to start recording issues."

  defp transition_status(socket, id, action) do
    organization_id = socket.assigns.organization.id

    with {:ok, issue} <- Errors.get_issue(organization_id, id),
         {:ok, _} <- apply_transition(issue, action) do
      {:noreply, push_patch(socket, to: patch_url(current_query_params(socket)), replace: true)}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update the issue.")}
    end
  end

  defp apply_transition(issue, :resolve), do: Errors.resolve_issue(issue)
  defp apply_transition(issue, :unresolve), do: Errors.unresolve_issue(issue)
  defp apply_transition(issue, :ignore), do: Errors.ignore_issue(issue)

  defp define_filters do
    status_options = Enum.map(Issue.statuses(), &Atom.to_string/1)

    [
      %Filter.Filter{
        id: "status",
        display_name: "Status",
        type: :option,
        options: status_options,
        options_display_names: Map.new(status_options, &{&1, status_label(String.to_atom(&1))}),
        operator: :==,
        searchable: false,
        value: nil
      }
    ]
  end
end
