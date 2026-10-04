defmodule GlossiaWeb.LLMUsageLive do
  use GlossiaWeb, :live_view

  alias Glossia.Translations.TokenUsage
  alias Noora.Filter

  def mount(_params, _session, socket) do
    authorize!(socket)
    values = TokenUsage.filter_values(socket.assigns.account)

    filters = [
      %Filter.Filter{
        id: "model",
        field: :model,
        display_name: gettext("Model"),
        type: :option,
        operator: :==,
        options: values.models,
        options_display_names: %{},
        searchable: true
      },
      %Filter.Filter{
        id: "project",
        field: :project_id,
        display_name: gettext("Project"),
        type: :option,
        operator: :==,
        options: Enum.map(values.projects, &elem(&1, 0)),
        options_display_names: Map.new(values.projects),
        searchable: true
      },
      %Filter.Filter{
        id: "locale",
        field: :locale,
        display_name: gettext("Language"),
        type: :option,
        operator: :==,
        options: values.locales,
        options_display_names: %{},
        searchable: true
      }
    ]

    {:ok,
     assign(socket,
       available_filters: filters,
       page_title: gettext("Token usage"),
       breadcrumb_items: [
         {gettext("Settings"), nil},
         {gettext("Models"), ~p"/#{socket.assigns.handle}/-/settings/models"},
         {gettext("Token usage"), nil}
       ]
     )}
  end

  def handle_params(params, uri, socket) do
    authorize!(socket)
    params = Map.reject(params, fn {key, value} -> key == "handle" or not is_binary(value) end)

    filters =
      Filter.Operations.decode_filters_from_query(params, socket.assigns.available_filters)

    usage = TokenUsage.overview(socket.assigns.account, params, filters)

    {:noreply,
     assign(socket,
       params: params,
       uri: URI.parse(uri),
       active_filters: filters,
       usage: usage,
       canonical_url:
         GlossiaWeb.Endpoint.url() |> URI.merge(URI.parse(uri).path) |> URI.to_string(),
       og_image_url:
         GlossiaWeb.DashboardSocial.image_url(socket.assigns.account, nil, :llm_models)
     )}
  end

  def handle_event("search_usage", %{"q" => search}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         usage_path(socket.assigns.handle, socket.assigns.params, %{"q" => search, "page" => "1"})
     )}
  end

  def handle_event("usage_period", %{"days" => days}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         usage_path(socket.assigns.handle, socket.assigns.params, %{"days" => days, "page" => "1"})
     )}
  end

  def handle_event("add_filter", %{"value" => id}, socket) do
    if Enum.any?(socket.assigns.available_filters, &(&1.id == id)) do
      params = Filter.Operations.add_filter_to_query(id, socket, socket.assigns.params)

      {:noreply,
       push_patch(socket, to: usage_path(socket.assigns.handle, params, %{"page" => "1"}))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_filter", params, socket) do
    params = Filter.Operations.update_filters_in_query(params, socket, socket.assigns.params)

    {:noreply,
     push_patch(socket, to: usage_path(socket.assigns.handle, params, %{"page" => "1"}))}
  end

  defp authorize!(socket) do
    unless Glossia.Authz.authorize?(
             :llm_model_read,
             socket.assigns.current_user,
             socket.assigns.account
           ) do
      raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end
  end

  defp usage_path(handle, params, overrides) do
    params = params |> Map.merge(overrides) |> Map.reject(fn {_key, value} -> value == "" end)
    ~p"/#{handle}/-/settings/models/usage?#{params}"
  end

  defp sort_path(handle, params, usage, column) do
    direction =
      cond do
        usage.sort == column -> if usage.direction == "asc", do: "desc", else: "asc"
        column == "label" -> "asc"
        true -> "desc"
      end

    usage_path(handle, params, %{"sort" => column, "dir" => direction, "page" => "1"})
  end

  defp number(value) do
    value
    |> to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        metrics: [
          {gettext("Total tokens"),
           assigns.usage.totals.input_tokens + assigns.usage.totals.output_tokens},
          {gettext("Input tokens"), assigns.usage.totals.input_tokens},
          {gettext("Output tokens"), assigns.usage.totals.output_tokens},
          {gettext("Cached input tokens"), assigns.usage.totals.cached_tokens}
        ],
        columns: [
          {"input_tokens", gettext("Input")},
          {"output_tokens", gettext("Output")},
          {"cached_tokens", gettext("Cached input")},
          {"total_tokens", gettext("Total")},
          {"calls", gettext("Responses")}
        ],
        dimensions: [
          {"projects", gettext("Projects")},
          {"languages", gettext("Languages")},
          {"files", gettext("Files")}
        ]
      )

    ~H"""
    <div id="llm-usage-page" class="dash-page">
      <Noora.Card.card title={gettext("Token usage")} icon="chart_bar_popular">
        <:actions>
          <.form for={%{}} id="usage-period" phx-change="usage_period">
            <Noora.Select.select
              id="usage-days"
              name="days"
              value={to_string(@usage.days)}
              label={gettext("Last %{days} days", days: @usage.days)}
            >
              <:item value="7" label={gettext("Last 7 days")} />
              <:item value="30" label={gettext("Last 30 days")} />
              <:item value="90" label={gettext("Last 90 days")} />
            </Noora.Select.select>
          </.form>
        </:actions>
        <Noora.Card.card_section>
          <p data-part="description">
            {gettext(
              "Provider-reported usage for generative translations, including retries and rejected outputs. Cached input is included in input tokens, not added to the total again. Dates are UTC."
            )}
          </p>
        </Noora.Card.card_section>
        <div data-part="metrics">
          <Noora.Card.card_section :for={{title, value} <- @metrics} data-part="metric">
            <span data-part="metric-title">{title}</span>
            <span data-part="metric-value">{number(value)}</span>
          </Noora.Card.card_section>
        </div>
        <Noora.Card.card_section :if={@usage.totals.calls > 0} data-part="chart">
          <Noora.Chart.chart
            id="token-usage-chart"
            type="bar"
            stacked={true}
            labels={Enum.map(@usage.daily, &Date.to_iso8601(&1.date))}
            series={[
              %{name: gettext("Input"), values: Enum.map(@usage.daily, & &1.input_tokens)},
              %{name: gettext("Output"), values: Enum.map(@usage.daily, & &1.output_tokens)}
            ]}
          />
        </Noora.Card.card_section>
        <Noora.Card.card_section>
          <div data-part="toolbar">
            <div data-part="dimensions" aria-label={gettext("Usage breakdown")}>
              <Noora.Button.button
                :for={{dimension, label} <- @dimensions}
                patch={
                  usage_path(@handle, @params, %{"dimension" => dimension, "q" => "", "page" => "1"})
                }
                label={label}
                variant={if @usage.dimension == dimension, do: "primary", else: "secondary"}
                aria-pressed={to_string(@usage.dimension == dimension)}
                size="medium"
              />
            </div>
            <.form for={%{}} id="usage-search" phx-change="search_usage">
              <Noora.TextInput.text_input
                id="usage-query"
                name="q"
                value={@usage.search}
                placeholder={gettext("Search breakdown")}
                aria-label={gettext("Search breakdown")}
                phx-debounce="300"
              />
            </.form>
            <Noora.Filter.filter_dropdown
              id="usage-filters"
              label={gettext("Filter")}
              available_filters={@available_filters}
              active_filters={@active_filters}
            />
          </div>
          <div :if={@active_filters != []} data-part="active-filters">
            <Noora.Filter.active_filter :for={filter <- @active_filters} filter={filter} />
          </div>
          <p data-part="description">
            {gettext(
              "Model, project, and language filters apply to totals, chart, and breakdown. Search narrows the breakdown only. Unassigned includes requests without project or file metadata."
            )}
          </p>
          <Noora.Table.table id="token-usage-table" rows={@usage.rows}>
            <:col
              :let={row}
              label={gettext("Name")}
              patch={sort_path(@handle, @params, @usage, "label")}
              sort_order={if @usage.sort == "label", do: @usage.direction}
            >
              <Noora.Table.text_cell
                label={row.label}
                sublabel={if @usage.dimension == "files", do: row.project}
              />
            </:col>
            <:col
              :let={row}
              :for={{column, label} <- @columns}
              label={label}
              patch={sort_path(@handle, @params, @usage, column)}
              sort_order={if @usage.sort == column, do: @usage.direction}
            >
              <Noora.Table.text_cell label={number(Map.fetch!(row, String.to_existing_atom(column)))} />
            </:col>
            <:empty_state>
              <Noora.Table.table_empty_state
                title={gettext("No reported usage")}
                subtitle={
                  gettext(
                    "Usage appears after a provider reports token counts. Historical translations, local Pi sessions, and decision evaluations are not included."
                  )
                }
              />
            </:empty_state>
          </Noora.Table.table>
          <div :if={@usage.total_rows > 50} class="glossia-pagination">
            <Noora.PaginationGroup.pagination_group
              current_page={@usage.page}
              number_of_pages={ceil(@usage.total_rows / 50)}
              page_patch={fn page -> usage_path(@handle, @params, %{"page" => to_string(page)}) end}
            />
          </div>
        </Noora.Card.card_section>
      </Noora.Card.card>
      <p data-part="description">
        {gettext(
          "Only provider-reported counts are shown. Historical translations, local Pi sessions, and decision evaluations are not included."
        )}
      </p>
    </div>
    """
  end
end
