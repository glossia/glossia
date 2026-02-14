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
          <div class="resource-filter-controls">
            <%= for filter <- @filters do %>
              <form phx-change="resource_filter" class="resource-filter-form">
                <input type="hidden" name="table_id" value={@id} />
                <input type="hidden" name="key" value={filter.key} />
                <select name="value" class="resource-filter-select">
                  <option value="">{filter.label}</option>
                  <%= for opt <- filter.options do %>
                    <option
                      value={opt.value}
                      selected={Map.get(@active_filters, filter.key) == opt.value}
                    >
                      {opt.label}
                    </option>
                  <% end %>
                </select>
              </form>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @active_filters != %{} do %>
        <div class="resource-filter-chips">
          <%= for {key, value} <- @active_filters do %>
            <span class="resource-filter-chip">
              <span class="resource-filter-chip-label">{humanize_filter(key)}: {value}</span>
              <button
                type="button"
                class="resource-filter-chip-remove"
                phx-click="resource_filter"
                phx-value-table_id={@id}
                phx-value-key={key}
                phx-value-value=""
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
                    <td class="resource-col-actions">{render_slot(@action, row)}</td>
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
end
