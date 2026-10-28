defmodule GlossiaEnterpriseWeb.AuditLogsLive do
  use GlossiaWeb, :live_view
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext
  use Noora

  alias GlossiaEnterprise.Audit
  alias Noora.Filter

  def mount(_params, _session, socket) do
    values = Audit.filter_values(socket.assigns.account, socket.assigns.current_user)

    {:ok,
     assign(socket,
       page_title: gettext("Audit logs"),
       breadcrumb_items: [{gettext("Audit logs"), nil}],
       available_filters: [
         %Filter.Filter{
           id: "event",
           field: :name,
           display_name: gettext("Event"),
           type: :option,
           operator: :==,
           options: values,
           options_display_names: %{},
           searchable: true
         }
       ]
     )}
  end

  def handle_params(params, _uri, socket) do
    params = Map.reject(params, fn {key, value} -> key == "handle" or not is_binary(value) end)

    filters =
      Filter.Operations.decode_filters_from_query(params, socket.assigns.available_filters)

    result =
      Audit.list_events(socket.assigns.account, socket.assigns.current_user, params, filters)

    {:noreply, assign(socket, params: params, active_filters: filters, result: result)}
  end

  def handle_event("search", %{"q" => search}, socket) do
    patch(socket, Map.merge(socket.assigns.params, %{"q" => search, "page" => "1"}))
  end

  def handle_event("add_filter", %{"value" => id}, socket) do
    if id == "event" do
      params = Filter.Operations.add_filter_to_query(id, socket, socket.assigns.params)
      patch(socket, Map.put(params, "page", "1"))
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_filter", params, socket) do
    params = Filter.Operations.update_filters_in_query(params, socket, socket.assigns.params)
    patch(socket, Map.put(params, "page", "1"))
  end

  defp patch(socket, params),
    do: {:noreply, push_patch(socket, to: audit_path(socket.assigns.handle, params))}

  defp audit_path(handle, params), do: ~p"/#{handle}/-/audit-logs?#{params}"

  defp sort_path(assigns, column) do
    direction =
      if assigns.result.sort == column and assigns.result.direction == "desc",
        do: "asc",
        else: "desc"

    audit_path(
      assigns.handle,
      Map.merge(assigns.params, %{"sort" => column, "dir" => direction, "page" => "1"})
    )
  end

  def render(assigns) do
    ~H"""
    <div id="audit-logs-page">
      <GlossiaWeb.DashboardComponents.page_header
        title={gettext("Audit logs")}
        description={gettext("Account changes and organization sign-ins. Dates are UTC.")}
      />
      <.badge label={gettext("Enterprise")} />
      <.card title={gettext("Events")} icon="file_text">
        <.card_section data-empty={@result.rows == []}>
          <div data-part="filters">
            <.filter_dropdown
              id="audit-filters"
              label={gettext("Filter")}
              available_filters={@available_filters}
              active_filters={@active_filters}
            />
            <.form for={%{}} id="audit-search" phx-change="search" phx-submit="search">
              <.text_input
                id="audit-query"
                name="q"
                type="search"
                show_suffix={false}
                value={@result.search}
                placeholder={gettext("Search events or actors")}
                aria-label={gettext("Search events or actors")}
                phx-debounce="300"
              />
            </.form>
          </div>
          <div :if={@active_filters != []} data-part="active-filters">
            <.active_filter :for={filter <- @active_filters} filter={filter} />
          </div>
          <Noora.Table.table id="audit-events" rows={@result.rows}>
            <:col
              :let={event}
              label={gettext("Time (UTC)")}
              patch={sort_path(assigns, "occurred_at")}
              sort_order={if @result.sort == "occurred_at", do: @result.direction}
            >
              <Noora.Table.text_cell label={Calendar.strftime(event.occurred_at, "%Y-%m-%d %H:%M:%S")} />
            </:col>
            <:col
              :let={event}
              label={gettext("Event")}
              patch={sort_path(assigns, "name")}
              sort_order={if @result.sort == "name", do: @result.direction}
            >
              <Noora.Table.text_and_description_cell
                label={event.summary || event.name}
                description={event.name}
                title={event.summary || event.name}
              />
            </:col>
            <:col
              :let={event}
              label={gettext("Actor")}
              patch={sort_path(assigns, "actor_handle")}
              sort_order={if @result.sort == "actor_handle", do: @result.direction}
            >
              <Noora.Table.text_and_description_cell
                label={event.actor_handle || event.actor_email || gettext("System")}
                description={event.actor_email}
                title={event.actor_email}
              />
            </:col>
            <:col :let={event} label={gettext("Resource")}>
              <Noora.Table.text_and_description_cell
                label={event.resource_type || "—"}
                description={event.resource_id}
                title={event.resource_id}
              />
            </:col>
            <:empty_state>
              <Noora.Table.table_empty_state
                icon="file_text"
                title={
                  if @result.search != "" or @active_filters != [],
                    do: gettext("No matching events"),
                    else: gettext("No audit events yet")
                }
                subtitle={
                  if @result.search != "" or @active_filters != [],
                    do: gettext("Change the search or filters to see more events."),
                    else:
                      gettext(
                        "New account changes and organization sign-ins will appear here. Earlier activity is not backfilled."
                      )
                }
              />
            </:empty_state>
          </Noora.Table.table>
          <div :if={@result.total > 50} class="glossia-pagination">
            <.pagination_group
              current_page={@result.page}
              number_of_pages={ceil(@result.total / 50)}
              page_patch={
                fn page -> audit_path(@handle, Map.put(@params, "page", to_string(page))) end
              }
            />
          </div>
        </.card_section>
      </.card>
    </div>
    """
  end
end
