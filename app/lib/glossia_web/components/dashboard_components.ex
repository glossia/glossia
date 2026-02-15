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
        {gettext("Account tokens"), "/" <> @handle <> "/api/tokens"},
        {gettext("New token"), "/" <> @handle <> "/api/tokens/new"}
      ]} />
  """
  attr :items, :list,
    required: true,
    doc: "List of {label, path} tuples. Last item is current page."

  def breadcrumb(assigns) do
    ~H"""
    <nav class="dash-breadcrumbs" aria-label={gettext("Breadcrumbs")}>
      <%= for {{label, _path}, idx} <- Enum.with_index(@items) do %>
        <%= if idx > 0 do %>
          <span class="dash-breadcrumb-sep" aria-hidden="true">/</span>
        <% end %>
        <%= if idx == length(@items) - 1 do %>
          <span class="dash-breadcrumb-current">{label}</span>
        <% else %>
          <.link patch={elem(Enum.at(@items, idx), 1)} class="dash-breadcrumb-link">{label}</.link>
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
        cancel_path={"/" <> @handle <> "/api/tokens"}
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

  def save_bar(assigns) do
    ~H"""
    <div class={["voice-save-bar", @visible && "visible"]} id={@id}>
      <div class="voice-save-bar-inner">
        <span class="voice-save-bar-label">{gettext("Unsaved changes")}</span>
        <div class="voice-save-bar-actions">
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
              placeholder={gettext("Describe your changes...")}
              required
            />
          </div>
          <button
            type="button"
            class="dash-btn dash-btn-secondary"
            phx-click={@discard_event}
          >
            {gettext("Discard")}
          </button>
          <button type="submit" class="dash-btn dash-btn-primary">
            {gettext("Save")}
          </button>
        </div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".SaveBarSummary">
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
      <.badge variant="warning">Issue</.badge>
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
end
