defmodule GlossiaWeb.DashboardComponents do
  @moduledoc """
  Reusable dashboard UI components inspired by Shopify Polaris patterns.

  These components are designed for resource index pages (tables with search,
  filter, and sort controls).
  """

  use Phoenix.Component
  use Gettext, backend: GlossiaWeb.Gettext

  # ---------------------------------------------------------------------------
  # Resource Table
  # ---------------------------------------------------------------------------

  @doc """
  Renders a Polaris-style resource table with a toolbar containing search,
  filter, and sortable column headers.

  The component is presentational: it fires LiveView events that the parent
  handles to update state. Expected events:

    * `"resource_search"` -- `%{"search" => value, "id" => table_id}`
    * `"resource_sort"` -- `%{"key" => column_key, "id" => table_id}`
    * `"resource_filter"` -- `%{"filter_<key>" => value, "id" => table_id}`
    * `"resource_clear_filters"` -- `%{"id" => table_id}`

  ## Slots

    * `:col` -- defines both a column header and the cell template.
      Accepts `:let` for the row item.
    * `:empty` -- optional; rendered when `rows` is empty.

  ## Examples

      <.resource_table id="events" rows={@events} search={@search} sort_key={@sort_key} sort_dir={@sort_dir}>
        <:col :let={e} label="Event" key="summary" sortable>
          {e.summary}
        </:col>
        <:col :let={e} label="Date" key="date" sortable class="resource-col-nowrap">
          {Calendar.strftime(e.inserted_at, "%b %d, %Y %H:%M")}
        </:col>
      </.resource_table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :search, :string, default: ""
  attr :search_placeholder, :string, default: nil
  attr :sort_key, :string, default: nil
  attr :sort_dir, :string, values: ~w(asc desc), default: "desc"
  attr :filters, :list, default: []
  attr :active_filters, :map, default: %{}
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 25
  attr :total, :integer, default: nil

  slot :col, required: true do
    attr :label, :string
    attr :key, :string
    attr :sortable, :boolean
    attr :class, :string
  end

  slot :action, doc: "optional action column rendered as last column per row"
  slot :empty

  def resource_table(assigns) do
    assigns = assign(assigns, :total_pages, total_pages(assigns.total, assigns.per_page))

    ~H"""
    <div class="resource-index" id={@id}>
      <div class="resource-toolbar">
        <form phx-change="resource_search" class="resource-search-form">
          <input type="hidden" name="table_id" value={@id} />
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
              name="search"
              value={@search}
              placeholder={@search_placeholder || gettext("Search...")}
              phx-debounce="300"
              class="resource-search"
            />
          </div>
        </form>
        <%= if @filters != [] do %>
          <div
            class="rf-dropdown"
            id={"#{@id}-filter-dropdown"}
            phx-hook=".ResourceFilterDropdown"
            phx-update="ignore"
            data-filters={
              JSON.encode!(
                Enum.map(@filters, fn f ->
                  base = %{key: f.key, label: f.label, type: Map.get(f, :type, "select")}

                  if Map.has_key?(f, :options) do
                    Map.put(
                      base,
                      :options,
                      Enum.map(f.options, fn o -> %{value: o.value, label: o.label} end)
                    )
                  else
                    base
                  end
                end)
              )
            }
            data-active={JSON.encode!(@active_filters)}
            data-table-id={@id}
          >
            <button type="button" class="rf-trigger" aria-expanded="false" aria-haspopup="true">
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
                <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
              </svg>
              <span>{gettext("Filter")}</span>
            </button>
            <div class="rf-panel" role="menu"></div>
          </div>
        <% end %>
      </div>

      <%= if has_active_filters?(@active_filters, @filters) do %>
        <div class="resource-filter-chips">
          <%= for {key, values} <- @active_filters, chip <- chip_items(@filters, key, values) do %>
            <span class="resource-filter-chip">
              <span class="resource-filter-chip-label">
                {chip.label}: {chip.display}
              </span>
              <button
                type="button"
                class="resource-filter-chip-remove"
                phx-click={chip.remove_event}
                phx-value-table_id={@id}
                phx-value-key={key}
                phx-value-filter_value={chip.remove_value}
                aria-label={gettext("Remove filter")}
              >
                <svg
                  width="12"
                  height="12"
                  viewBox="0 0 20 20"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2.5"
                  stroke-linecap="round"
                  aria-hidden="true"
                >
                  <line x1="5" y1="5" x2="15" y2="15" /><line x1="15" y1="5" x2="5" y2="15" />
                </svg>
              </button>
            </span>
          <% end %>
          <button
            type="button"
            class="resource-clear-filters"
            phx-click="resource_clear_filters"
            phx-value-table_id={@id}
          >
            {gettext("Clear all")}
          </button>
        </div>
      <% end %>

      <div class="resource-table-wrap">
        <table class="resource-table">
          <thead>
            <tr>
              <%= for col <- @col do %>
                <th
                  class={[
                    col[:class],
                    col[:sortable] && "resource-col-sortable"
                  ]}
                  phx-click={col[:sortable] && "resource_sort"}
                  phx-value-key={col[:sortable] && col[:key]}
                  phx-value-table_id={col[:sortable] && @id}
                  aria-sort={sort_aria(@sort_key, @sort_dir, col[:key])}
                >
                  <span class="resource-col-header">
                    {col[:label]}
                    <%= if col[:sortable] do %>
                      <span class="resource-sort-indicator" aria-hidden="true">
                        <%= cond do %>
                          <% @sort_key == col[:key] && @sort_dir == "asc" -> %>
                            <svg
                              width="14"
                              height="14"
                              viewBox="0 0 16 16"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                            >
                              <polyline points="4 10 8 6 12 10" />
                            </svg>
                          <% @sort_key == col[:key] && @sort_dir == "desc" -> %>
                            <svg
                              width="14"
                              height="14"
                              viewBox="0 0 16 16"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                            >
                              <polyline points="4 6 8 10 12 6" />
                            </svg>
                          <% true -> %>
                            <svg
                              width="14"
                              height="14"
                              viewBox="0 0 16 16"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="1.5"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="resource-sort-inactive"
                            >
                              <polyline points="5 6.5 8 3.5 11 6.5" />
                              <polyline points="5 9.5 8 12.5 11 9.5" />
                            </svg>
                        <% end %>
                      </span>
                    <% end %>
                  </span>
                </th>
              <% end %>
              <%= if @action != [] do %>
                <th class="resource-col-actions">
                  <span class="sr-only">{gettext("Actions")}</span>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= if @rows == [] do %>
              <tr>
                <td
                  colspan={length(@col) + if(@action != [], do: 1, else: 0)}
                  class="resource-empty-cell"
                >
                  <%= if @empty != [] do %>
                    {render_slot(@empty)}
                  <% else %>
                    <span class="resource-empty-text">{gettext("No results found.")}</span>
                  <% end %>
                </td>
              </tr>
            <% else %>
              <%= for row <- @rows do %>
                <tr>
                  <%= for col <- @col do %>
                    <td class={col[:class]}>{render_slot(col, row)}</td>
                  <% end %>
                  <%= if @action != [] do %>
                    <td class="resource-col-actions">
                      <div class="resource-col-actions-inner">
                        {render_slot(@action, row)}
                      </div>
                    </td>
                  <% end %>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @total && @total > @per_page do %>
        <% first = (@page - 1) * @per_page + 1
        last = min(@page * @per_page, @total) %>
        <div class="resource-pagination">
          <span class="resource-pagination-info">
            {gettext("Showing %{first}-%{last} of %{total}",
              first: first,
              last: last,
              total: @total
            )}
          </span>
          <div class="resource-pagination-controls">
            <button
              type="button"
              class="resource-pagination-btn"
              phx-click="resource_page"
              phx-value-page={@page - 1}
              phx-value-table_id={@id}
              disabled={@page <= 1}
              aria-label={gettext("Previous page")}
            >
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
            </button>
            <span class="resource-pagination-page">
              {gettext("Page %{page} of %{total}", page: @page, total: @total_pages)}
            </span>
            <button
              type="button"
              class="resource-pagination-btn"
              phx-click="resource_page"
              phx-value-page={@page + 1}
              phx-value-table_id={@id}
              disabled={@page >= @total_pages}
              aria-label={gettext("Next page")}
            >
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
                <polyline points="8 4 14 10 8 16" />
              </svg>
            </button>
          </div>
        </div>
      <% end %>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ResourceFilterDropdown">
      export default {
        mounted() {
          this.filters = JSON.parse(this.el.dataset.filters);
          this.active = JSON.parse(this.el.dataset.active);
          this.tableId = this.el.dataset.tableId;
          this.trigger = this.el.querySelector(".rf-trigger");
          this.panel = this.el.querySelector(".rf-panel");
          this.step = "columns";
          this.selectedFilter = null;

          this.trigger.addEventListener("click", (e) => {
            e.stopPropagation();
            if (this.el.classList.contains("open")) {
              this.close();
            } else {
              this.open();
            }
          });

          this._onDocClick = () => this.close();
          document.addEventListener("click", this._onDocClick);
          this.panel.addEventListener("click", (e) => e.stopPropagation());

          this._onEsc = (e) => { if (e.key === "Escape") this.close(); };
          document.addEventListener("keydown", this._onEsc);

          this.handleEvent("filters_updated:" + this.tableId, ({ active }) => {
            this.active = active;
          });
        },

        destroyed() {
          document.removeEventListener("click", this._onDocClick);
          document.removeEventListener("keydown", this._onEsc);
        },

        open() {
          this.step = "columns";
          this.selectedFilter = null;
          this.renderColumns();
          this.el.classList.add("open");
          this.trigger.setAttribute("aria-expanded", "true");
        },

        close() {
          this.el.classList.remove("open");
          this.trigger.setAttribute("aria-expanded", "false");
        },

        renderColumns() {
          const items = this.filters.map(f =>
            '<button type="button" class="rf-option" data-key="' + this.esc(f.key) + '">' +
              this.esc(f.label) +
            '</button>'
          ).join("");
          this.panel.innerHTML =
            '<div class="rf-header">Filter by\u2026</div>' +
            '<div class="rf-list">' + items + '</div>';
          this.panel.querySelectorAll(".rf-option").forEach(btn => {
            btn.addEventListener("click", () => {
              this.selectedFilter = this.filters.find(f => f.key === btn.dataset.key);
              this.step = "value";
              this.renderValue();
            });
          });
        },

        renderValue() {
          const f = this.selectedFilter;
          const type = f.type || "select";
          const backBtn = '<button type="button" class="rf-back">\u2190 ' + this.esc(f.label) + '</button>';

          if (type === "select") {
            this.renderSelect(f, backBtn);
          } else if (type === "text") {
            this.renderText(f, backBtn);
          } else if (type === "date_range") {
            this.renderDateRange(f, backBtn);
          }
        },

        renderSelect(f, backBtn) {
          const activeVals = this.active[f.key] || [];
          const opts = (f.options || []).map(o =>
            '<button type="button" class="rf-option' +
              (activeVals.includes(o.value) ? ' rf-option-active' : '') +
            '" data-value="' + this.esc(o.value) + '">' +
              '<span class="rf-check">' + (activeVals.includes(o.value) ? '\u2713' : '') + '</span>' +
              this.esc(o.label) +
            '</button>'
          ).join("");
          this.panel.innerHTML = backBtn + '<div class="rf-list">' + opts + '</div>';
          this.wireBack();
          this.panel.querySelectorAll(".rf-option").forEach(btn => {
            btn.addEventListener("click", () => {
              const val = btn.dataset.value;
              if ((this.active[f.key] || []).includes(val)) {
                this.pushEvent("resource_remove_filter", {
                  table_id: this.tableId, key: f.key, filter_value: val
                });
              } else {
                this.pushEvent("resource_filter", {
                  table_id: this.tableId, key: f.key, value: val
                });
              }
              this.close();
            });
          });
        },

        renderText(f, backBtn) {
          const currentVal = (this.active[f.key] || [""])[0] || "";
          this.panel.innerHTML = backBtn +
            '<div class="rf-text-body">' +
              '<input type="text" class="rf-text-input" placeholder="' + this.esc(f.label) + '\u2026" value="' + this.esc(currentVal) + '" />' +
              '<button type="button" class="rf-apply">Apply</button>' +
            '</div>';
          this.wireBack();
          const input = this.panel.querySelector(".rf-text-input");
          const applyBtn = this.panel.querySelector(".rf-apply");
          input.focus();
          const apply = () => {
            this.pushEvent("resource_filter_text", {
              table_id: this.tableId, key: f.key, value: input.value
            });
            this.close();
          };
          applyBtn.addEventListener("click", apply);
          input.addEventListener("keydown", (e) => {
            if (e.key === "Enter") { e.preventDefault(); apply(); }
          });
        },

        renderDateRange(f, backBtn) {
          const rangeVal = (this.active[f.key] || [""])[0] || "";
          let fromVal = "", toVal = "", fromTime = "00:00", toTime = "23:59";
          if (rangeVal && rangeVal.includes("..")) {
            const parts = rangeVal.split("..");
            const fromPart = parts[0] || "";
            const toPart = parts[1] || "";
            if (fromPart.includes("T")) {
              fromVal = fromPart.split("T")[0];
              fromTime = fromPart.split("T")[1] || "00:00";
            } else { fromVal = fromPart; }
            if (toPart.includes("T")) {
              toVal = toPart.split("T")[0];
              toTime = toPart.split("T")[1] || "23:59";
            } else { toVal = toPart; }
          }

          this.panel.innerHTML = backBtn +
            '<div class="rf-date-presets">' +
              '<button type="button" class="rf-preset" data-preset="today">Today</button>' +
              '<button type="button" class="rf-preset" data-preset="yesterday">Yesterday</button>' +
              '<button type="button" class="rf-preset" data-preset="last7">Last 7 days</button>' +
              '<button type="button" class="rf-preset" data-preset="last30">Last 30 days</button>' +
              '<button type="button" class="rf-preset" data-preset="this_month">This month</button>' +
              '<button type="button" class="rf-preset" data-preset="last_month">Last month</button>' +
            '</div>' +
            '<div class="rf-date-divider"></div>' +
            '<div class="rf-date-custom">' +
              '<span class="rf-date-custom-label">Custom range</span>' +
              '<div class="rf-date-row">' +
                '<label>From</label>' +
                '<input type="date" class="rf-date-input" name="from" value="' + fromVal + '" />' +
                '<input type="time" class="rf-time-input" name="from_time" value="' + fromTime + '" />' +
              '</div>' +
              '<div class="rf-date-row">' +
                '<label>To</label>' +
                '<input type="date" class="rf-date-input" name="to" value="' + toVal + '" />' +
                '<input type="time" class="rf-time-input" name="to_time" value="' + toTime + '" />' +
              '</div>' +
              '<button type="button" class="rf-apply">Apply</button>' +
            '</div>';
          this.wireBack();

          this.panel.querySelectorAll(".rf-preset").forEach(btn => {
            btn.addEventListener("click", () => {
              const range = this.computePreset(btn.dataset.preset);
              this.applyDateRange(f.key, range.from, range.to);
            });
          });

          this.panel.querySelector(".rf-apply").addEventListener("click", () => {
            const fromD = this.panel.querySelector('[name="from"]').value;
            const toD = this.panel.querySelector('[name="to"]').value;
            const fromT = this.panel.querySelector('[name="from_time"]').value || "00:00";
            const toT = this.panel.querySelector('[name="to_time"]').value || "23:59";
            const from = fromD ? fromD + "T" + fromT : "";
            const to = toD ? toD + "T" + toT : "";
            this.applyDateRange(f.key, from, to);
          });
        },

        applyDateRange(key, from, to) {
          this.pushEvent("resource_filter_date_range", {
            table_id: this.tableId, key: key, from: from, to: to
          });
          this.close();
        },

        computePreset(preset) {
          const today = new Date();
          const fmt = (d) => d.toISOString().split("T")[0];
          const sod = (d) => fmt(d) + "T00:00";
          const eod = (d) => fmt(d) + "T23:59";
          switch (preset) {
            case "today":
              return { from: sod(today), to: eod(today) };
            case "yesterday": {
              const y = new Date(today); y.setDate(y.getDate() - 1);
              return { from: sod(y), to: eod(y) };
            }
            case "last7": {
              const d = new Date(today); d.setDate(d.getDate() - 7);
              return { from: sod(d), to: eod(today) };
            }
            case "last30": {
              const d = new Date(today); d.setDate(d.getDate() - 30);
              return { from: sod(d), to: eod(today) };
            }
            case "this_month": {
              const s = new Date(today.getFullYear(), today.getMonth(), 1);
              return { from: sod(s), to: eod(today) };
            }
            case "last_month": {
              const s = new Date(today.getFullYear(), today.getMonth() - 1, 1);
              const e = new Date(today.getFullYear(), today.getMonth(), 0);
              return { from: sod(s), to: eod(e) };
            }
            default: return { from: "", to: "" };
          }
        },

        wireBack() {
          const back = this.panel.querySelector(".rf-back");
          if (back) back.addEventListener("click", () => {
            this.step = "columns";
            this.renderColumns();
          });
        },

        esc(s) {
          if (!s) return "";
          const d = document.createElement("div");
          d.textContent = s;
          return d.innerHTML;
        }
      }
    </script>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp total_pages(nil, _per_page), do: 1
  defp total_pages(total, per_page), do: ceil(total / per_page)

  defp sort_aria(sort_key, sort_dir, col_key) do
    if sort_key == col_key do
      if sort_dir == "asc", do: "ascending", else: "descending"
    end
  end

  defp humanize_filter(key) when is_binary(key) do
    key |> String.replace("_", " ") |> String.capitalize()
  end

  defp humanize_filter(key) when is_atom(key), do: humanize_filter(Atom.to_string(key))

  defp has_active_filters?(active_filters, _filter_defs) do
    Enum.any?(active_filters, fn {_key, values} ->
      values = List.wrap(values)
      values != [] and values != [""]
    end)
  end

  defp find_filter_type(filter_defs, key) do
    case Enum.find(filter_defs, fn f -> f.key == key end) do
      %{type: type} -> type
      _ -> "select"
    end
  end

  defp filter_label(filters, key) do
    case Enum.find(filters, fn f -> f.key == key end) do
      %{label: label} -> label
      _ -> humanize_filter(key)
    end
  end

  defp chip_items(filter_defs, key, values) do
    filter_type = find_filter_type(filter_defs, key)
    label = filter_label(filter_defs, key)

    case filter_type do
      "text" ->
        values = List.wrap(values)

        case values do
          [text] when is_binary(text) and text != "" ->
            [
              %{
                label: label,
                display: text,
                remove_event: "resource_remove_filter",
                remove_value: text
              }
            ]

          _ ->
            []
        end

      "date_range" ->
        values = List.wrap(values)

        case values do
          [range] when is_binary(range) and range != "" ->
            [
              %{
                label: label,
                display: format_date_range(range),
                remove_event: "resource_remove_filter",
                remove_value: range
              }
            ]

          _ ->
            []
        end

      _select ->
        values
        |> List.wrap()
        |> Enum.map(fn value ->
          %{
            label: label,
            display: filter_value_label(filter_defs, key, value),
            remove_event: "resource_remove_filter",
            remove_value: value
          }
        end)
    end
  end

  defp filter_value_label(filters, key, value) do
    case Enum.find(filters, fn f -> f.key == key end) do
      %{options: options} ->
        case Enum.find(options, fn o -> o.value == value end) do
          %{label: label} -> label
          _ -> value
        end

      _ ->
        value
    end
  end

  defp format_date_range(range) do
    case String.split(range, "..", parts: 2) do
      [from, to] ->
        from_str = format_date_short(from)
        to_str = format_date_short(to)

        case {from_str, to_str} do
          {"", ""} -> ""
          {f, ""} -> "from #{f}"
          {"", t} -> "until #{t}"
          {f, t} -> "#{f} - #{t}"
        end

      _ ->
        range
    end
  end

  defp format_date_short(""), do: ""

  defp format_date_short(date_str) do
    # Strip time component if present (e.g. "2026-01-15T14:30" -> "2026-01-15")
    date_only = date_str |> String.split("T") |> List.first()

    case Date.from_iso8601(date_only) do
      {:ok, date} -> Calendar.strftime(date, "%b %d, %Y")
      _ -> date_str
    end
  end

  # ---------------------------------------------------------------------------
  # Page Header
  # ---------------------------------------------------------------------------

  @doc """
  Renders a dashboard page header with title, optional description, and actions.

  ## Examples

      <.page_header title="Glossary" description="Define approved terms and translations.">
        <:actions>
          <button class="dash-btn dash-btn-primary">Save</button>
        </:actions>
      </.page_header>
  """
  attr :title, :string, required: true
  attr :description, :string, default: nil

  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="dash-page-header">
      <div class="dash-page-header-text">
        <h1>{@title}</h1>
        <p :if={@description} class="dash-page-header-desc">{@description}</p>
      </div>
      <div :if={@actions != []} class="dash-page-header-actions">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Breadcrumb navigation
  # ---------------------------------------------------------------------------

  @doc """
  Renders breadcrumb navigation for dashboard sub-pages.

  ## Examples

      <.breadcrumb items={[
        {gettext("Account tokens"), "/" <> @handle <> "/-/settings/tokens"},
        {gettext("New token"), "/" <> @handle <> "/-/settings/tokens/new"}
      ]} />
  """
  attr :items, :list,
    required: true,
    doc: "List of {label, path} tuples. Last item is current page."

  def breadcrumb(assigns) do
    ~H"""
    <nav class="dash-breadcrumbs" aria-label={gettext("Breadcrumbs")}>
      <%= for {{label, path}, idx} <- Enum.with_index(@items) do %>
        <%= if idx > 0 do %>
          <span class="dash-breadcrumb-sep" aria-hidden="true">/</span>
        <% end %>
        <%= cond do %>
          <% idx == length(@items) - 1 -> %>
            <span class="dash-breadcrumb-current">{label}</span>
          <% is_nil(path) -> %>
            <span class="dash-breadcrumb-text">{label}</span>
          <% true -> %>
            <.link patch={path} class="dash-breadcrumb-link">{label}</.link>
        <% end %>
      <% end %>
    </nav>
    """
  end

  # ---------------------------------------------------------------------------
  # Form Save Bar (simplified sticky bar for creation/edit forms)
  # ---------------------------------------------------------------------------

  @doc """
  Renders a simplified sticky save bar for creation and edit forms.

  Unlike `save_bar/1`, this variant has no change-note input, no LLM summary,
  and no JS hook. It simply shows Save and Cancel buttons in a sticky bar.

  Must be placed inside a `<form>` element. The form's `phx-submit` handles saving.

  ## Examples

      <.form_save_bar
        id="token-save-bar"
        visible={@token_form_valid?}
        cancel_path={"/" <> @handle <> "/-/settings/tokens"}
      />
  """
  attr :id, :string, required: true
  attr :visible, :boolean, default: false
  attr :cancel_path, :string, required: true, doc: "Path to navigate to on cancel"

  def form_save_bar(assigns) do
    ~H"""
    <div class={["voice-save-bar", @visible && "visible"]} id={@id}>
      <div class="voice-save-bar-inner">
        <span class="voice-save-bar-label">{gettext("Ready to save")}</span>
        <div class="voice-save-bar-actions">
          <.link patch={@cancel_path} class="dash-btn dash-btn-secondary">
            {gettext("Cancel")}
          </.link>
          <button type="submit" class="dash-btn dash-btn-primary">
            {gettext("Save")}
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Save Bar (reusable sticky bottom bar for versioned forms)
  # ---------------------------------------------------------------------------

  @doc """
  Renders a fixed save bar at the bottom of the dashboard for confirming
  or discarding unsaved changes. Includes a required change-note input
  that can be auto-populated by an LLM-generated summary.

  Must be placed inside a `<form>` element. The form's `phx-submit`
  handles saving; the discard button fires a separate LiveView event.

  ## Examples

      <.save_bar
        id="voice-save-bar"
        visible={@changed?}
        discard_event="discard_changes"
        change_summary={@change_summary}
        generating_summary?={@generating_summary?}
      />
  """
  attr :id, :string, required: true
  attr :visible, :boolean, default: false
  attr :discard_event, :string, required: true
  attr :change_summary, :string, default: ""
  attr :generating_summary?, :boolean, default: false
  attr :submit_label, :string, default: nil
  attr :state_label, :string, default: nil
  attr :note_placeholder, :string, default: nil
  attr :show_note, :boolean, default: true
  attr :form, :string, default: nil

  def save_bar(assigns) do
    assigns = assign_new(assigns, :submit_label, fn -> gettext("Save") end)
    assigns = assign_new(assigns, :state_label, fn -> gettext("Unsaved changes") end)

    assigns =
      assign_new(assigns, :note_placeholder, fn -> gettext("Describe your changes...") end)

    ~H"""
    <div class={["voice-save-bar", @visible && "visible"]} id={@id}>
      <div class="voice-save-bar-inner">
        <span class="voice-save-bar-label">{@state_label}</span>
        <div class="voice-save-bar-actions">
          <%= if @show_note do %>
            <div
              class="voice-save-bar-note-wrap"
              id={"#{@id}-hook"}
              phx-hook=".SaveBarSummary"
              phx-update="ignore"
              data-generating={to_string(@generating_summary?)}
            >
              <input
                type="text"
                id={"#{@id}-note"}
                name="change_note"
                class="voice-save-bar-note"
                placeholder={@note_placeholder}
                form={@form}
                required
              />
            </div>
          <% end %>
          <button
            type="button"
            class="dash-btn dash-btn-secondary"
            phx-click={@discard_event}
          >
            {gettext("Discard")}
          </button>
          <button type="submit" class="dash-btn dash-btn-primary" form={@form}>
            {@submit_label}
          </button>
        </div>
      </div>
    </div>
    <script :if={@show_note} :type={Phoenix.LiveView.ColocatedHook} name=".SaveBarSummary">
      export default {
        mounted() {
          this.input = this.el.querySelector("input[name='change_note']");
          this.userEdited = false;
          this.defaultPlaceholder = this.input.placeholder;

          if (this.el.dataset.generating === "true") {
            this.input.placeholder = "Generating...";
          }

          this.input.addEventListener("input", () => {
            this.userEdited = true;
          });

          const barId = this.el.id.replace("-hook", "");

          this.handleEvent("summary_generating:" + barId, () => {
            this.el.dataset.generating = "true";
            this.input.placeholder = "Generating...";
            this.userEdited = false;
          });

          this.handleEvent("summary_generated:" + barId, ({summary}) => {
            if (!this.userEdited && summary) {
              this.input.value = summary;
            }
            this.el.dataset.generating = "false";
            this.input.placeholder = this.defaultPlaceholder;
          });
        },

        destroyed() {
          this.userEdited = false;
        }
      }
    </script>
    """
  end

  # ---------------------------------------------------------------------------
  # Locale Picker (searchable combobox)
  # ---------------------------------------------------------------------------

  @doc """
  Renders a searchable locale picker combobox.

  The input field displays only the locale code (e.g. "es"). The dropdown
  shows the full label (e.g. "es - Spanish") and filters as the user types.

  ## Examples

      <.locale_picker
        id="locale-0-1"
        name="entries[0][translations][1][locale]"
        value="es"
      />
  """
  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :placeholder, :string, default: nil

  def locale_picker(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".LocalePicker"
      phx-update="ignore"
      class="locale-picker"
      data-value={@value || ""}
      data-name={@name}
      data-disabled={to_string(@disabled)}
      data-placeholder={@placeholder || gettext("Search language...")}
    >
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LocalePicker">
      const LOCALES = [
        ["ar", "Arabic"], ["bn", "Bengali"], ["zh", "Chinese"],
        ["zh-TW", "Chinese (Traditional)"], ["cs", "Czech"], ["da", "Danish"],
        ["nl", "Dutch"], ["en", "English"], ["fi", "Finnish"], ["fr", "French"],
        ["de", "German"], ["el", "Greek"], ["he", "Hebrew"], ["hi", "Hindi"],
        ["hu", "Hungarian"], ["id", "Indonesian"], ["it", "Italian"],
        ["ja", "Japanese"], ["ko", "Korean"], ["ms", "Malay"],
        ["nb", "Norwegian"], ["pl", "Polish"], ["pt", "Portuguese"],
        ["pt-BR", "Portuguese (Brazil)"], ["ro", "Romanian"], ["ru", "Russian"],
        ["es", "Spanish"], ["es-MX", "Spanish (Mexico)"], ["sv", "Swedish"],
        ["th", "Thai"], ["tr", "Turkish"], ["uk", "Ukrainian"], ["vi", "Vietnamese"]
      ];

      export default {
        mounted() { this.setup(); },
        updated() { this.setup(); },

        setup() {
          const el = this.el;
          const name = el.dataset.name;
          const disabled = el.dataset.disabled === "true";
          const placeholder = el.dataset.placeholder || "Search language...";
          let value = el.dataset.value || "";

          el.innerHTML = "";

          const hidden = document.createElement("input");
          hidden.type = "hidden";
          hidden.name = name;
          hidden.value = value;
          el.appendChild(hidden);

          const input = document.createElement("input");
          input.type = "text";
          input.className = "locale-picker-input";
          input.placeholder = placeholder;
          input.autocomplete = "off";
          input.value = value || "";
          if (disabled) input.disabled = true;
          el.appendChild(input);

          const list = document.createElement("div");
          list.className = "locale-picker-dropdown";
          el.appendChild(list);

          let highlighted = -1;

          const render = (filter) => {
            const q = (filter || "").toLowerCase();
            const matches = LOCALES.filter(([code, name]) =>
              code.toLowerCase().includes(q) || name.toLowerCase().includes(q)
            ).sort((a, b) => {
              const aCode = a[0].toLowerCase().startsWith(q) ? 0 : 1;
              const bCode = b[0].toLowerCase().startsWith(q) ? 0 : 1;
              return aCode - bCode;
            });
            list.innerHTML = "";
            highlighted = -1;
            matches.forEach(([code, name]) => {
              const opt = document.createElement("div");
              opt.className = "locale-picker-option" + (code === value ? " selected" : "");
              opt.dataset.value = code;
              opt.textContent = code + " - " + name;
              opt.addEventListener("mousedown", (e) => {
                e.preventDefault();
                pick(code);
              });
              list.appendChild(opt);
            });
          };

          const pick = (code) => {
            value = code;
            hidden.value = code;
            input.value = code;
            list.classList.remove("open");
            hidden.dispatchEvent(new Event("input", { bubbles: true }));
          };

          const highlightAt = (idx) => {
            const opts = list.querySelectorAll(".locale-picker-option");
            opts.forEach(o => o.classList.remove("highlighted"));
            if (idx >= 0 && idx < opts.length) {
              opts[idx].classList.add("highlighted");
              opts[idx].scrollIntoView({ block: "nearest" });
              highlighted = idx;
            }
          };

          if (!disabled) {
            input.addEventListener("focus", () => {
              input.select();
              render(input.value === value ? "" : input.value);
              list.classList.add("open");
            });

            input.addEventListener("input", () => {
              render(input.value);
              list.classList.add("open");
            });

            input.addEventListener("blur", () => {
              list.classList.remove("open");
              input.value = value || "";
            });

            input.addEventListener("keydown", (e) => {
              const opts = list.querySelectorAll(".locale-picker-option");
              if (e.key === "ArrowDown") {
                e.preventDefault();
                highlightAt(Math.min(highlighted + 1, opts.length - 1));
              } else if (e.key === "ArrowUp") {
                e.preventDefault();
                highlightAt(Math.max(highlighted - 1, 0));
              } else if (e.key === "Enter") {
                e.preventDefault();
                if (highlighted >= 0 && opts[highlighted]) {
                  pick(opts[highlighted].dataset.value);
                }
              } else if (e.key === "Escape") {
                input.blur();
              }
            });
          }
        }
      }
    </script>
    """
  end

  # ---------------------------------------------------------------------------
  # Country Picker (searchable combobox)
  # ---------------------------------------------------------------------------

  @doc """
  Renders a searchable country picker combobox with flag emojis.

  Pushes a `"country_selected"` event with `%{code: "XX"}` when a country
  is picked. This is designed for multi-select workflows where the parent
  LiveView manages the list of selected countries.

  ## Examples

      <.country_picker
        id="voice-country-picker"
        exclude={["US", "JP"]}
      />
  """
  attr :id, :string, required: true
  attr :exclude, :list, default: []
  attr :disabled, :boolean, default: false

  def country_picker(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".CountryPicker"
      phx-update="ignore"
      class="locale-picker"
      data-exclude={JSON.encode!(@exclude)}
      data-disabled={to_string(@disabled)}
      data-placeholder={gettext("Search country...")}
    >
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".CountryPicker">
      const COUNTRIES = [
        ["AD", "\u{1F1E6}\u{1F1E9}", "Andorra"], ["AE", "\u{1F1E6}\u{1F1EA}", "United Arab Emirates"],
        ["AR", "\u{1F1E6}\u{1F1F7}", "Argentina"], ["AT", "\u{1F1E6}\u{1F1F9}", "Austria"],
        ["AU", "\u{1F1E6}\u{1F1FA}", "Australia"], ["BE", "\u{1F1E7}\u{1F1EA}", "Belgium"],
        ["BG", "\u{1F1E7}\u{1F1EC}", "Bulgaria"], ["BR", "\u{1F1E7}\u{1F1F7}", "Brazil"],
        ["CA", "\u{1F1E8}\u{1F1E6}", "Canada"], ["CH", "\u{1F1E8}\u{1F1ED}", "Switzerland"],
        ["CL", "\u{1F1E8}\u{1F1F1}", "Chile"], ["CN", "\u{1F1E8}\u{1F1F3}", "China"],
        ["CO", "\u{1F1E8}\u{1F1F4}", "Colombia"], ["CZ", "\u{1F1E8}\u{1F1FF}", "Czech Republic"],
        ["DE", "\u{1F1E9}\u{1F1EA}", "Germany"], ["DK", "\u{1F1E9}\u{1F1F0}", "Denmark"],
        ["EG", "\u{1F1EA}\u{1F1EC}", "Egypt"], ["ES", "\u{1F1EA}\u{1F1F8}", "Spain"],
        ["FI", "\u{1F1EB}\u{1F1EE}", "Finland"], ["FR", "\u{1F1EB}\u{1F1F7}", "France"],
        ["GB", "\u{1F1EC}\u{1F1E7}", "United Kingdom"], ["GR", "\u{1F1EC}\u{1F1F7}", "Greece"],
        ["HK", "\u{1F1ED}\u{1F1F0}", "Hong Kong"], ["HR", "\u{1F1ED}\u{1F1F7}", "Croatia"],
        ["HU", "\u{1F1ED}\u{1F1FA}", "Hungary"], ["ID", "\u{1F1EE}\u{1F1E9}", "Indonesia"],
        ["IE", "\u{1F1EE}\u{1F1EA}", "Ireland"], ["IL", "\u{1F1EE}\u{1F1F1}", "Israel"],
        ["IN", "\u{1F1EE}\u{1F1F3}", "India"], ["IT", "\u{1F1EE}\u{1F1F9}", "Italy"],
        ["JP", "\u{1F1EF}\u{1F1F5}", "Japan"], ["KR", "\u{1F1F0}\u{1F1F7}", "South Korea"],
        ["MA", "\u{1F1F2}\u{1F1E6}", "Morocco"], ["MX", "\u{1F1F2}\u{1F1FD}", "Mexico"],
        ["MY", "\u{1F1F2}\u{1F1FE}", "Malaysia"], ["NG", "\u{1F1F3}\u{1F1EC}", "Nigeria"],
        ["NL", "\u{1F1F3}\u{1F1F1}", "Netherlands"], ["NO", "\u{1F1F3}\u{1F1F4}", "Norway"],
        ["NZ", "\u{1F1F3}\u{1F1FF}", "New Zealand"], ["PE", "\u{1F1F5}\u{1F1EA}", "Peru"],
        ["PH", "\u{1F1F5}\u{1F1ED}", "Philippines"], ["PK", "\u{1F1F5}\u{1F1F0}", "Pakistan"],
        ["PL", "\u{1F1F5}\u{1F1F1}", "Poland"], ["PT", "\u{1F1F5}\u{1F1F9}", "Portugal"],
        ["RO", "\u{1F1F7}\u{1F1F4}", "Romania"], ["SA", "\u{1F1F8}\u{1F1E6}", "Saudi Arabia"],
        ["SE", "\u{1F1F8}\u{1F1EA}", "Sweden"], ["SG", "\u{1F1F8}\u{1F1EC}", "Singapore"],
        ["TH", "\u{1F1F9}\u{1F1ED}", "Thailand"], ["TR", "\u{1F1F9}\u{1F1F7}", "Turkey"],
        ["TW", "\u{1F1F9}\u{1F1FC}", "Taiwan"], ["UA", "\u{1F1FA}\u{1F1E6}", "Ukraine"],
        ["US", "\u{1F1FA}\u{1F1F8}", "United States"], ["VN", "\u{1F1FB}\u{1F1F3}", "Vietnam"],
        ["ZA", "\u{1F1FF}\u{1F1E6}", "South Africa"]
      ];

      export default {
        mounted() {
          this.setup();
          this.handleEvent("update_country_exclude", ({ exclude: newExclude }) => {
            this._exclude = newExclude || [];
          });
        },
        updated() { this.setup(); },

        setup() {
          const el = this.el;
          const disabled = el.dataset.disabled === "true";
          const placeholder = el.dataset.placeholder || "Search country...";
          let exclude = [];
          try { exclude = JSON.parse(el.dataset.exclude || "[]"); } catch(e) {}
          this._exclude = exclude;

          el.innerHTML = "";

          const input = document.createElement("input");
          input.type = "text";
          input.className = "locale-picker-input";
          input.placeholder = placeholder;
          input.autocomplete = "off";
          if (disabled) input.disabled = true;
          el.appendChild(input);

          const list = document.createElement("div");
          list.className = "locale-picker-dropdown";
          el.appendChild(list);

          let highlighted = -1;
          const hook = this;

          const render = (filter) => {
            const q = (filter || "").toLowerCase();
            const currentExclude = hook._exclude || [];
            const matches = COUNTRIES.filter(([code, flag, name]) =>
              !currentExclude.includes(code) &&
              (code.toLowerCase().includes(q) || name.toLowerCase().includes(q))
            ).sort((a, b) => {
              const aCode = a[0].toLowerCase().startsWith(q) ? 0 : 1;
              const bCode = b[0].toLowerCase().startsWith(q) ? 0 : 1;
              return aCode - bCode;
            });
            list.innerHTML = "";
            highlighted = -1;
            matches.forEach(([code, flag, name]) => {
              const opt = document.createElement("div");
              opt.className = "locale-picker-option";
              opt.dataset.value = code;
              opt.textContent = flag + " " + name;
              opt.addEventListener("mousedown", (e) => {
                e.preventDefault();
                pick(code);
              });
              list.appendChild(opt);
            });
          };

          const pick = (code) => {
            input.value = "";
            list.classList.remove("open");
            hook.pushEvent("add_country", { code: code });
          };

          const highlightAt = (idx) => {
            const opts = list.querySelectorAll(".locale-picker-option");
            opts.forEach(o => o.classList.remove("highlighted"));
            if (idx >= 0 && idx < opts.length) {
              opts[idx].classList.add("highlighted");
              opts[idx].scrollIntoView({ block: "nearest" });
              highlighted = idx;
            }
          };

          if (!disabled) {
            input.addEventListener("focus", () => {
              render("");
              list.classList.add("open");
            });

            input.addEventListener("input", () => {
              render(input.value);
              list.classList.add("open");
            });

            input.addEventListener("blur", () => {
              list.classList.remove("open");
              input.value = "";
            });

            input.addEventListener("keydown", (e) => {
              const opts = list.querySelectorAll(".locale-picker-option");
              if (e.key === "ArrowDown") {
                e.preventDefault();
                highlightAt(Math.min(highlighted + 1, opts.length - 1));
              } else if (e.key === "ArrowUp") {
                e.preventDefault();
                highlightAt(Math.max(highlighted - 1, 0));
              } else if (e.key === "Enter") {
                e.preventDefault();
                if (highlighted >= 0 && opts[highlighted]) {
                  pick(opts[highlighted].dataset.value);
                }
              } else if (e.key === "Escape") {
                input.blur();
              }
            });
          }
        }
      }
    </script>
    """
  end

  @country_map %{
    "AD" => {"\u{1F1E6}\u{1F1E9}", "Andorra"},
    "AE" => {"\u{1F1E6}\u{1F1EA}", "United Arab Emirates"},
    "AR" => {"\u{1F1E6}\u{1F1F7}", "Argentina"},
    "AT" => {"\u{1F1E6}\u{1F1F9}", "Austria"},
    "AU" => {"\u{1F1E6}\u{1F1FA}", "Australia"},
    "BE" => {"\u{1F1E7}\u{1F1EA}", "Belgium"},
    "BG" => {"\u{1F1E7}\u{1F1EC}", "Bulgaria"},
    "BR" => {"\u{1F1E7}\u{1F1F7}", "Brazil"},
    "CA" => {"\u{1F1E8}\u{1F1E6}", "Canada"},
    "CH" => {"\u{1F1E8}\u{1F1ED}", "Switzerland"},
    "CL" => {"\u{1F1E8}\u{1F1F1}", "Chile"},
    "CN" => {"\u{1F1E8}\u{1F1F3}", "China"},
    "CO" => {"\u{1F1E8}\u{1F1F4}", "Colombia"},
    "CZ" => {"\u{1F1E8}\u{1F1FF}", "Czech Republic"},
    "DE" => {"\u{1F1E9}\u{1F1EA}", "Germany"},
    "DK" => {"\u{1F1E9}\u{1F1F0}", "Denmark"},
    "EG" => {"\u{1F1EA}\u{1F1EC}", "Egypt"},
    "ES" => {"\u{1F1EA}\u{1F1F8}", "Spain"},
    "FI" => {"\u{1F1EB}\u{1F1EE}", "Finland"},
    "FR" => {"\u{1F1EB}\u{1F1F7}", "France"},
    "GB" => {"\u{1F1EC}\u{1F1E7}", "United Kingdom"},
    "GR" => {"\u{1F1EC}\u{1F1F7}", "Greece"},
    "HK" => {"\u{1F1ED}\u{1F1F0}", "Hong Kong"},
    "HR" => {"\u{1F1ED}\u{1F1F7}", "Croatia"},
    "HU" => {"\u{1F1ED}\u{1F1FA}", "Hungary"},
    "ID" => {"\u{1F1EE}\u{1F1E9}", "Indonesia"},
    "IE" => {"\u{1F1EE}\u{1F1EA}", "Ireland"},
    "IL" => {"\u{1F1EE}\u{1F1F1}", "Israel"},
    "IN" => {"\u{1F1EE}\u{1F1F3}", "India"},
    "IT" => {"\u{1F1EE}\u{1F1F9}", "Italy"},
    "JP" => {"\u{1F1EF}\u{1F1F5}", "Japan"},
    "KR" => {"\u{1F1F0}\u{1F1F7}", "South Korea"},
    "MA" => {"\u{1F1F2}\u{1F1E6}", "Morocco"},
    "MX" => {"\u{1F1F2}\u{1F1FD}", "Mexico"},
    "MY" => {"\u{1F1F2}\u{1F1FE}", "Malaysia"},
    "NG" => {"\u{1F1F3}\u{1F1EC}", "Nigeria"},
    "NL" => {"\u{1F1F3}\u{1F1F1}", "Netherlands"},
    "NO" => {"\u{1F1F3}\u{1F1F4}", "Norway"},
    "NZ" => {"\u{1F1F3}\u{1F1FF}", "New Zealand"},
    "PE" => {"\u{1F1F5}\u{1F1EA}", "Peru"},
    "PH" => {"\u{1F1F5}\u{1F1ED}", "Philippines"},
    "PK" => {"\u{1F1F5}\u{1F1F0}", "Pakistan"},
    "PL" => {"\u{1F1F5}\u{1F1F1}", "Poland"},
    "PT" => {"\u{1F1F5}\u{1F1F9}", "Portugal"},
    "RO" => {"\u{1F1F7}\u{1F1F4}", "Romania"},
    "SA" => {"\u{1F1F8}\u{1F1E6}", "Saudi Arabia"},
    "SE" => {"\u{1F1F8}\u{1F1EA}", "Sweden"},
    "SG" => {"\u{1F1F8}\u{1F1EC}", "Singapore"},
    "TH" => {"\u{1F1F9}\u{1F1ED}", "Thailand"},
    "TR" => {"\u{1F1F9}\u{1F1F7}", "Turkey"},
    "TW" => {"\u{1F1F9}\u{1F1FC}", "Taiwan"},
    "UA" => {"\u{1F1FA}\u{1F1E6}", "Ukraine"},
    "US" => {"\u{1F1FA}\u{1F1F8}", "United States"},
    "VN" => {"\u{1F1FB}\u{1F1F3}", "Vietnam"},
    "ZA" => {"\u{1F1FF}\u{1F1E6}", "South Africa"}
  }

  def country_flag(code), do: elem(Map.get(@country_map, code, {"", code}), 0)
  def country_name(code), do: elem(Map.get(@country_map, code, {"", code}), 1)

  # ---------------------------------------------------------------------------
  # Badge
  # ---------------------------------------------------------------------------

  @doc """
  Renders a status badge with a variant color.

  ## Examples

      <.badge variant="success">Active</.badge>
      <.badge variant="warning">Ticket</.badge>
      <.badge variant="info">In progress</.badge>
  """
  attr :variant, :string, values: ~w(neutral info success warning), default: "neutral"
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["badge", "badge-#{@variant}", @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders a markdown editor with Write/Preview tabs and image upload support.

  The editor uses a colocated JS hook to manage tab switching, image paste/drop,
  and preview rendering. The textarea value flows via standard form `name` attribute.

  ## Examples

      <.markdown_editor
        id="ticket-body-editor"
        name="ticket[body]"
        value={@form[:body].value}
        placeholder="Describe the ticket..."
        upload={@uploads.ticket_images}
      />
  """
  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :rows, :integer, default: 6
  attr :required, :boolean, default: false
  attr :upload, :any, default: nil, doc: "The upload assign from allow_upload"

  def markdown_editor(assigns) do
    ~H"""
    <div class="md-editor" id={@id} phx-hook=".MarkdownEditor">
      <div class="md-editor-tabs">
        <button type="button" class="md-editor-tab active" data-tab="write">
          {gettext("Write")}
        </button>
        <button type="button" class="md-editor-tab" data-tab="preview">
          {gettext("Preview")}
        </button>
      </div>
      <div class="md-editor-write">
        <textarea
          name={@name}
          id={"#{@id}-textarea"}
          rows={@rows}
          placeholder={@placeholder}
          required={@required}
        >{@value}</textarea>
        <div class="md-editor-drop-hint">{gettext("Drop image to upload")}</div>
      </div>
      <div class="md-editor-preview" style="display:none;">
        <div class="prose md-editor-preview-content"></div>
      </div>
      <.live_file_input :if={@upload} upload={@upload} class="sr-only" />
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".MarkdownEditor">
      export default {
        mounted() {
          const el = this.el;
          const textarea = el.querySelector("textarea");
          const writePane = el.querySelector(".md-editor-write");
          const previewPane = el.querySelector(".md-editor-preview");
          const previewContent = el.querySelector(".md-editor-preview-content");
          const tabs = el.querySelectorAll(".md-editor-tab");
          const dropHint = el.querySelector(".md-editor-drop-hint");
          const fileInput = el.querySelector("input[type='file']");

          tabs.forEach(tab => {
            tab.addEventListener("click", () => {
              tabs.forEach(t => t.classList.remove("active"));
              tab.classList.add("active");
              if (tab.dataset.tab === "write") {
                writePane.style.display = "";
                previewPane.style.display = "none";
                textarea.focus();
              } else {
                writePane.style.display = "none";
                previewPane.style.display = "";
                this.pushEvent("markdown_preview", {
                  source: textarea.value,
                  editor_id: el.id
                }, (reply) => {
                  previewContent.innerHTML = reply.html;
                  this.highlightCode(previewContent);
                  this.addCopyButtons(previewContent);
                });
              }
            });
          });

          textarea.addEventListener("paste", (e) => {
            const items = e.clipboardData && e.clipboardData.items;
            if (!items || !fileInput) return;
            for (let i = 0; i < items.length; i++) {
              if (items[i].type.startsWith("image/")) {
                e.preventDefault();
                const file = items[i].getAsFile();
                const dt = new DataTransfer();
                dt.items.add(file);
                fileInput.files = dt.files;
                fileInput.dispatchEvent(new Event("change", { bubbles: true }));
                break;
              }
            }
          });

          textarea.addEventListener("dragover", (e) => {
            e.preventDefault();
            dropHint.classList.add("visible");
          });
          textarea.addEventListener("dragleave", () => {
            dropHint.classList.remove("visible");
          });
          textarea.addEventListener("drop", (e) => {
            dropHint.classList.remove("visible");
            const files = e.dataTransfer && e.dataTransfer.files;
            if (!files || !files.length || !fileInput) return;
            const imageFiles = [];
            for (let i = 0; i < files.length; i++) {
              if (files[i].type.startsWith("image/")) imageFiles.push(files[i]);
            }
            if (!imageFiles.length) return;
            e.preventDefault();
            const dt = new DataTransfer();
            imageFiles.forEach(f => dt.items.add(f));
            fileInput.files = dt.files;
            fileInput.dispatchEvent(new Event("change", { bubbles: true }));
          });

          this.handleEvent("image_uploaded:" + el.id, ({ url, filename }) => {
            const start = textarea.selectionStart;
            const before = textarea.value.substring(0, start);
            const after = textarea.value.substring(textarea.selectionEnd);
            const mdImage = "![" + filename + "](" + url + ")";
            textarea.value = before + mdImage + after;
            textarea.selectionStart = textarea.selectionEnd = start + mdImage.length;
            textarea.dispatchEvent(new Event("input", { bubbles: true }));
          });

          this.handleEvent("clear_editor:" + el.id, () => {
            textarea.value = "";
            tabs.forEach(t => t.classList.remove("active"));
            tabs[0].classList.add("active");
            writePane.style.display = "";
            previewPane.style.display = "none";
            previewContent.innerHTML = "";
          });

          this.handleEvent("quote_editor:" + el.id, ({ text }) => {
            tabs.forEach(t => t.classList.remove("active"));
            tabs[0].classList.add("active");
            writePane.style.display = "";
            previewPane.style.display = "none";
            const start = textarea.selectionStart;
            const before = textarea.value.substring(0, start);
            const after = textarea.value.substring(textarea.selectionEnd);
            const prefix = before.length > 0 && !before.endsWith("\n") ? "\n" : "";
            textarea.value = before + prefix + text + after;
            const newPos = (before + prefix + text).length;
            textarea.selectionStart = textarea.selectionEnd = newPos;
            textarea.focus();
            textarea.dispatchEvent(new Event("input", { bubbles: true }));
          });
        },
        highlightCode(container) {
          if (!window.hljs) {
            if (this._hljsLoading) return;
            this._hljsLoading = true;
            const link = document.createElement("link");
            link.rel = "stylesheet";
            link.href = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/styles/github.min.css";
            document.head.appendChild(link);
            const script = document.createElement("script");
            script.src = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/highlight.min.js";
            script.onload = () => {
              this._hljsLoading = false;
              container.querySelectorAll("pre code").forEach(block => window.hljs.highlightElement(block));
              this.addCopyButtons(container);
            };
            document.head.appendChild(script);
          } else {
            container.querySelectorAll("pre code").forEach(block => window.hljs.highlightElement(block));
          }
        },
        addCopyButtons(container) {
          const copyIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>';
          const checkIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
          container.querySelectorAll("pre").forEach(pre => {
            if (pre.querySelector(".code-copy-btn")) return;
            const btn = document.createElement("button");
            btn.className = "code-copy-btn";
            btn.setAttribute("type", "button");
            btn.setAttribute("aria-label", "Copy code");
            btn.innerHTML = copyIcon;
            btn.addEventListener("click", () => {
              const code = pre.querySelector("code");
              const text = code ? code.textContent : pre.textContent;
              navigator.clipboard.writeText(text).then(() => {
                btn.innerHTML = checkIcon;
                btn.classList.add("copied");
                setTimeout(() => { btn.innerHTML = copyIcon; btn.classList.remove("copied"); }, 1500);
              });
            });
            pre.appendChild(btn);
          });
        }
      }
    </script>
    """
  end
end
