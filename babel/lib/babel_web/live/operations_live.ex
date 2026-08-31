defmodule BabelWeb.OperationsLive do
  use BabelWeb, :live_view
  use Noora

  alias Babel.Organizations
  alias Babel.Organizations.Interaction
  alias Babel.Organizations.Organization
  alias Noora.Filter

  def mount(_params, _session, socket) do
    {:ok, assign(socket, available_filters: account_filters())}
  end

  def handle_params(params, uri, socket) do
    live_action = socket.assigns.live_action
    uri = parse_uri(uri)

    active_filters =
      Filter.Operations.decode_filters_from_query(params, socket.assigns.available_filters)

    account_search = params["search"] || ""
    account_sort_by = account_sort_by_param(params["sort_by"])
    account_sort_order = account_sort_order_param(params["sort_order"])
    account = visible_account(live_action, params)

    socket =
      assign(socket,
        account: account,
        account_usage: account_usage(account),
        account_summary: Organizations.summary(),
        accounts:
          visible_accounts(
            live_action,
            account_list_options(
              active_filters,
              account_search,
              account_sort_by,
              account_sort_order
            )
          ),
        current_path: uri.path,
        account_form: new_account_form(),
        organization_edit_form: edit_organization_form(account),
        interaction_form: new_interaction_form(),
        page_favicon: organization_favicon_url(account),
        page_title: page_title(live_action, account),
        uri: uri,
        active_filters: active_filters,
        account_search: account_search,
        account_sort_by: account_sort_by,
        account_sort_order: account_sort_order
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path} live_action={@live_action}>
      <main
        id="operations"
        data-page={@live_action}
        phx-hook="OrganizationVisuals"
        data-favicon-href={@page_favicon}
        data-default-favicon-href={~p"/favicon.ico"}
      >
        <.button
          :if={@live_action == :organization}
          id="organization-list-button"
          label="Organizations"
          size="medium"
          variant="secondary"
          navigate={~p"/growth"}
        >
          <:icon_left><.icon name="arrow_left" /></:icon_left>
        </.button>

        <div data-part="header">
          <%= if @live_action == :organization && @account do %>
            <div data-part="organization-header-identity">
              <.avatar
                id="organization-page-avatar"
                name={@account.name}
                image_href={@page_favicon}
                data-src={@page_favicon}
                fallback="placeholder"
                color="azure"
                size="large"
              />
              <div data-part="copy">
                <p data-part="eyebrow">{page_eyebrow(@live_action)}</p>
                <h1 data-part="title">{page_title(@live_action, @account)}</h1>
                <p data-part="description">{page_description(@live_action)}</p>
              </div>
            </div>
          <% else %>
            <div data-part="copy">
              <p data-part="eyebrow">{page_eyebrow(@live_action)}</p>
              <h1 data-part="title">{page_title(@live_action, @account)}</h1>
              <p data-part="description">{page_description(@live_action)}</p>
            </div>
          <% end %>
        </div>

        <%= if @live_action == :overview do %>
          <.overview account_summary={@account_summary} />
        <% else %>
          <%= if @live_action == :go_to_market do %>
          <.go_to_market
            accounts={@accounts}
            account_summary={@account_summary}
            active_filters={@active_filters}
            available_filters={@available_filters}
            account_search={@account_search}
            account_sort_by={@account_sort_by}
            account_sort_order={@account_sort_order}
            account_form={@account_form}
            uri={@uri}
          />
          <% else %>
          <.organization
            account={@account}
            account_usage={@account_usage}
            organization_edit_form={@organization_edit_form}
            interaction_form={@interaction_form}
          />
          <% end %>
        <% end %>
      </main>
    </Layouts.app>
    """
  end

  attr :account_summary, :map, required: true

  def overview(assigns) do
    ~H"""
    <div id="overview">
      <.card title="Growth" icon="building" id="overview-go-to-market-card">
        <:actions>
          <.button label="Open" size="small" variant="secondary" navigate={~p"/growth"}>
            <:icon_left><.icon name="arrow_right" /></:icon_left>
          </.button>
        </:actions>
        <.card_section data-part="widgets">
          <.metric_widget label="Organizations" value={@account_summary.total} tone="primary" />
          <.metric_widget label="Researching" value={@account_summary.researching} tone="warning" />
          <.metric_widget label="Qualified" value={@account_summary.qualified} tone="success" />
          <.metric_widget
            label="Demos scheduled"
            value={@account_summary.demos_scheduled}
            tone="information"
          />
        </.card_section>
      </.card>
    </div>
    """
  end

  attr :accounts, :list, required: true
  attr :account_summary, :map, required: true
  attr :active_filters, :list, required: true
  attr :available_filters, :list, required: true
  attr :account_search, :string, required: true
  attr :account_sort_by, :string, required: true
  attr :account_sort_order, :string, required: true
  attr :account_form, :any, required: true
  attr :uri, :any, required: true

  def go_to_market(assigns) do
    ~H"""
    <div id="go-to-market">
      <.card title="Organization summary" icon="chart_donut_4" id="go-to-market-summary-card">
        <.card_section data-part="widgets">
          <.metric_widget label="Organizations" value={@account_summary.total} tone="primary" />
          <.metric_widget label="Researching" value={@account_summary.researching} tone="warning" />
          <.metric_widget label="Qualified" value={@account_summary.qualified} tone="success" />
          <.metric_widget label="Demos scheduled" value={@account_summary.demos_scheduled} tone="information" />
        </.card_section>
      </.card>

      <.card title="Organizations" icon="building" id="go-to-market-organization-card">
        <:actions>
          <.form id="go-to-market-organization-form" for={@account_form} phx-submit="save_account">
            <.modal
              id="add-go-to-market-organization-modal"
              title="Add organization"
              description="Record a company for research or an existing Glossia customer."
              header_type="icon"
            >
              <:trigger :let={attrs}>
                <.button label="Add organization" size="small" variant="primary" {attrs}>
                  <:icon_left><.icon name="plus" /></:icon_left>
                </.button>
              </:trigger>
              <:header_icon><.icon name="building" /></:header_icon>
              <.organization_form_fields form={@account_form} id_prefix="go-to-market-organization" />
              <:footer>
                <.modal_footer>
                  <:action>
                    <.button label="Add organization" size="medium" variant="primary" type="submit">
                      <:icon_left><.icon name="plus" /></:icon_left>
                    </.button>
                  </:action>
                </.modal_footer>
              </:footer>
            </.modal>
          </.form>
        </:actions>
        <.card_section>
          <div data-part="filters">
            <.form for={%{}} phx-change="search_accounts" phx-debounce="200">
              <.text_input
                type="search"
                id="search-go-to-market-organizations"
                name="search"
                placeholder="Search organizations..."
                show_suffix={false}
                data-part="search"
                value={@account_search}
                aria-label="Search organizations"
              />
            </.form>
            <.filter_dropdown
              id="go-to-market-organizations-filter"
              label="Filter"
              available_filters={@available_filters}
              active_filters={@active_filters}
            />
          </div>
          <div :if={Enum.any?(@active_filters)} data-part="active-filters">
            <.active_filter :for={filter <- @active_filters} filter={filter} />
          </div>
          <.table
            id="go-to-market-organizations"
            rows={@accounts}
            row_navigate={fn account -> ~p"/organizations/#{account}" end}
          >
            <:col
              :let={account}
              label="Organization"
              patch={account_sort_patch(assigns, "name")}
              sort_order={@account_sort_by == "name" && @account_sort_order}
            >
              <.text_and_description_cell
                label={account.name}
                description={account.translation_tool || "Translation tool to verify"}
              >
                <:image>
                  <.avatar
                    id={"organization-#{account.id}-avatar"}
                    name={account.name}
                    image_href={organization_favicon_url(account)}
                    data-src={organization_favicon_url(account)}
                    fallback="placeholder"
                    color="azure"
                    size="medium"
                  />
                </:image>
              </.text_and_description_cell>
            </:col>
            <:col
              :let={account}
              label="State"
              patch={account_sort_patch(assigns, "state")}
              sort_order={@account_sort_by == "state" && @account_sort_order}
            >
              <.badge_cell
                label={account_state_label(account.state)}
                color={account_state_color(account.state)}
                style="light-fill"
              />
            </:col>
            <:col
              :let={account}
              label="Description"
              patch={account_sort_patch(assigns, "notes")}
              sort_order={@account_sort_by == "notes" && @account_sort_order}
            >
              <.text_cell label={account.notes || "No notes yet"} />
            </:col>
            <:empty_state>
              <.table_empty_state
                icon="building"
                title="No organizations yet"
                subtitle="Create an organization when public research is ready for review."
              />
            </:empty_state>
          </.table>
        </.card_section>
      </.card>

    </div>
    """
  end

  attr :form, :any, required: true
  attr :id_prefix, :string, required: true

  def organization_form_fields(assigns) do
    ~H"""
    <div data-part="organization-form-fields">
      <.text_input
        field={@form[:name]}
        id={"#{@id_prefix}-name"}
        label="Company name"
        placeholder="Acme"
        required
        show_required
      />
      <.text_input
        field={@form[:website_url]}
        id={"#{@id_prefix}-website-url"}
        label="Website"
        placeholder="https://example.com"
        input_type="url"
        required
        show_required
      />
      <.text_input
        field={@form[:origin_url]}
        id={"#{@id_prefix}-origin-url"}
        label="Origin URL"
        placeholder="https://example.com/customer-story"
        input_type="url"
        hint="The public source that led to this organization."
      />
      <div data-part="dropdown">
        <.label label="State" />
        <.select field={@form[:state]} id={"#{@id_prefix}-state"} label="State">
          <:item
            :for={state <- Organization.states()}
            value={state}
            label={account_state_label(state)}
          />
        </.select>
      </div>
      <.text_input
        field={@form[:translation_tool]}
        id={"#{@id_prefix}-translation-tool"}
        label="Translation tool"
        placeholder="Optional"
      />
      <.text_input
        field={@form[:glossia_organization_id]}
        id={"#{@id_prefix}-glossia-organization-id"}
        label="Glossia organization identifier"
        placeholder="Optional UUID"
        hint="Connects this organization to its Glossia usage data."
      />
      <.text_area
        field={@form[:notes]}
        id={"#{@id_prefix}-notes"}
        label="Description"
        placeholder="Optional organization context"
        rows={4}
        max_length={2_000}
      />
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :tone, :string, default: "primary"

  def metric_widget(assigns) do
    ~H"""
    <.card_section data-part="widget" data-tone={@tone}>
      <div data-part="widget-header">
        <div data-part="widget-legend"></div>
        <span data-part="widget-label">{@label}</span>
      </div>
      <span data-part="widget-value">{@value}</span>
    </.card_section>
    """
  end

  attr :account, :any, required: true
  attr :account_usage, :any, required: true
  attr :organization_edit_form, :any, required: true
  attr :interaction_form, :any, required: true

  def organization(%{account: nil} = assigns) do
    ~H"""
    <div id="organization">
      <.card title="Organization not found" icon="building">
        <.card_section>
          <p data-part="empty-organization">The requested organization is no longer available.</p>
        </.card_section>
      </.card>
    </div>
    """
  end

  def organization(assigns) do
    ~H"""
    <div id="organization">
      <.card title="Summary" icon="building" id="organization-summary-card">
        <:actions>
          <.form id="edit-organization-form" for={@organization_edit_form} phx-submit="update_organization">
            <.modal
              id="edit-organization-modal"
              title="Edit organization"
              description="Update its company context and relationship state."
              header_type="icon"
            >
              <:trigger :let={attrs}>
                <.button label="Edit organization" size="small" variant="secondary" {attrs}>
                  <:icon_left><.icon name="pencil" /></:icon_left>
                </.button>
              </:trigger>
              <:header_icon><.icon name="building" /></:header_icon>
              <.organization_form_fields form={@organization_edit_form} id_prefix="edit-organization" />
              <:footer>
                <.modal_footer>
                  <:action>
                    <.button label="Save changes" size="medium" variant="primary" type="submit">
                      <:icon_left><.icon name="check" /></:icon_left>
                    </.button>
                  </:action>
                </.modal_footer>
              </:footer>
            </.modal>
          </.form>
        </:actions>
        <.card_section>
          <dl data-part="organization-facts">
            <div data-part="organization-fact">
              <dt>State</dt>
              <dd>
                <.badge
                  label={account_state_label(@account.state)}
                  color={account_state_color(@account.state)}
                  style="light-fill"
                />
              </dd>
            </div>
            <div data-part="organization-fact">
              <dt>Translation tool</dt>
              <dd>{@account.translation_tool || "To verify"}</dd>
            </div>
            <div data-part="organization-fact">
              <dt>Website</dt>
              <dd>
                <Noora.Button.link_button
                  label="Open website"
                  href={@account.website_url}
                  variant="secondary"
                  target="_blank"
                  rel="noreferrer"
                />
              </dd>
            </div>
            <div :if={@account.origin_url} data-part="organization-fact">
              <dt>Origin</dt>
              <dd>
                <Noora.Button.link_button
                  label="Open origin"
                  href={@account.origin_url}
                  variant="secondary"
                  target="_blank"
                  rel="noreferrer"
                />
              </dd>
            </div>
            <div :if={@account.glossia_organization_id} data-part="organization-fact">
              <dt>Glossia organization identifier</dt>
              <dd data-part="organization-identifier">{@account.glossia_organization_id}</dd>
            </div>
          </dl>
          <p :if={@account.notes} data-part="organization-notes">{@account.notes}</p>
        </.card_section>
      </.card>

      <.card
        :if={@account.glossia_organization_id}
        title="Glossia usage"
        icon="chart_donut_4"
        id="organization-usage-card"
      >
        <.card_section :if={match?({:ok, _usage}, @account_usage)} data-part="widgets">
          <% {:ok, usage} = @account_usage %>
          <.metric_widget label="Projects" value={usage.projects} tone="primary" />
          <.metric_widget label="Members" value={usage.members} tone="success" />
          <.metric_widget
            label="Translation sessions"
            value={usage.translation_sessions}
            tone="information"
          />
        </.card_section>
        <.card_section :if={@account_usage == {:error, :organization_not_found}}>
          <p data-part="usage-message">No Glossia organization was found for this identifier.</p>
        </.card_section>
        <.card_section :if={@account_usage in [{:error, :invalid_organization_id}, {:error, :unavailable}]}>
          <p data-part="usage-message">Glossia usage data is unavailable right now.</p>
        </.card_section>
      </.card>

      <.card title="Interaction timeline" icon="checkup_list" id="organization-timeline-card">
        <.card_section>
          <.form
            id="organization-interaction-form"
            for={@interaction_form}
            phx-submit="save_interaction"
            data-part="interaction-composer"
          >
            <div data-part="interaction-composer-input">
              <.text_input
                field={@interaction_form[:summary]}
                id="organization-interaction-summary"
                placeholder="Record an interaction..."
                aria-label="Record an interaction"
                required
                show_suffix={false}
              />
            </div>
            <div data-part="interaction-composer-actions">
              <.button label="Add event" size="small" variant="primary" type="submit">
                <:icon_left><.icon name="plus" /></:icon_left>
              </.button>
            </div>
          </.form>
          <ol :if={@account.interactions != []} data-part="timeline">
            <li :for={interaction <- @account.interactions} data-part="timeline-item">
              <div data-part="timeline-marker">
                <.icon name={interaction_icon(interaction.kind)} />
              </div>
              <div data-part="timeline-content">
                <div data-part="timeline-header">
                  <.badge
                    label={interaction_kind_label(interaction.kind)}
                    color={interaction_kind_color(interaction.kind)}
                    style="light-fill"
                  />
                  <time datetime={DateTime.to_iso8601(interaction.occurred_at)}>
                    {format_datetime(interaction.occurred_at)}
                  </time>
                </div>
                <p data-part="timeline-summary">{interaction.summary}</p>
                <p :if={interaction.body} data-part="timeline-body">{interaction.body}</p>
                <Noora.Button.link_button
                  :if={interaction.source_url}
                  label="Open public source"
                  href={interaction.source_url}
                  variant="secondary"
                  target="_blank"
                  rel="noreferrer"
                />
              </div>
            </li>
          </ol>
          <p :if={@account.interactions == []} data-part="empty-organization">
            No interactions have been recorded for this organization yet.
          </p>
        </.card_section>
      </.card>
    </div>
    """
  end

  def handle_event("save_account", %{"account" => attributes}, socket) do
    case Organizations.create_organization(attributes) do
      {:ok, account} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization added.")
         |> push_navigate(to: ~p"/organizations/#{account}")}

      {:error, changeset} ->
        {:noreply, assign(socket, account_form: to_form(changeset, as: :account))}
    end
  end

  def handle_event("update_organization", %{"organization" => attributes}, socket) do
    case Organizations.update_organization(socket.assigns.account, attributes) do
      {:ok, organization} ->
        account = Organizations.get_organization(organization.id)

        {:noreply,
         socket
         |> assign(
           account: account,
           account_usage: account_usage(account),
           organization_edit_form: edit_organization_form(account),
           page_favicon: organization_favicon_url(account),
           page_title: page_title(:organization, account)
         )
         |> put_flash(:info, "Organization updated.")}

      {:error, changeset} ->
        {:noreply, assign(socket, organization_edit_form: to_form(changeset, as: :organization))}
    end
  end

  def handle_event("save_interaction", %{"interaction" => attributes}, socket) do
    attributes =
      attributes
      |> Map.put("kind", "note")
      |> Map.put("occurred_at", DateTime.utc_now(:second))

    case Organizations.create_interaction(socket.assigns.account, attributes) do
      {:ok, _interaction} ->
        {:noreply,
         socket
         |> assign(
           account: Organizations.get_organization(socket.assigns.account.id),
           interaction_form: new_interaction_form()
         )
         |> put_flash(:info, "Timeline event recorded.")}

      {:error, changeset} ->
        {:noreply, assign(socket, interaction_form: to_form(changeset, as: :interaction))}
    end
  end

  def handle_event("search_accounts", %{"search" => search}, socket) do
    params =
      socket.assigns.uri.query
      |> URI.decode_query()
      |> Map.put("search", search)

    {:noreply, push_patch(socket, to: ~p"/growth?#{params}", replace: true)}
  end

  def handle_event("add_filter", %{"value" => filter_id}, socket) do
    params = Filter.Operations.add_filter_to_query(filter_id, socket)

    {:noreply,
     socket
     |> push_patch(to: ~p"/growth?#{params}")
     |> push_event("open-dropdown", %{id: "filter-#{filter_id}-value-dropdown"})}
  end

  def handle_event("update_filter", params, socket) do
    updated_params = Filter.Operations.update_filters_in_query(params, socket)

    {:noreply,
     socket
     |> push_patch(to: ~p"/growth?#{updated_params}")
     |> push_event("close-dropdown", %{all: true})
     |> push_event("close-popover", %{all: true})}
  end

  defp visible_accounts(:go_to_market, options), do: Organizations.list_organizations(options)
  defp visible_accounts(_live_action, _options), do: []

  defp visible_account(:organization, %{"id" => id}), do: Organizations.get_organization(id)
  defp visible_account(_live_action, _params), do: nil

  defp account_usage(%Organization{} = organization), do: Organizations.usage(organization)

  defp account_usage(_account), do: :not_connected

  defp organization_favicon_url(%Organization{} = organization),
    do: Organizations.favicon_url(organization)

  defp organization_favicon_url(_organization), do: nil

  defp page_eyebrow(:organization), do: "Babel"
  defp page_eyebrow(_live_action), do: "Babel"

  defp page_title(:overview, _account), do: "Overview"
  defp page_title(:go_to_market, _account), do: "Growth"
  defp page_title(:organization, %{name: name}), do: name
  defp page_title(:organization, _account), do: "Organization"

  defp page_description(:overview) do
    "A snapshot of the work currently underway in Babel."
  end

  defp page_description(:go_to_market) do
    "Public-source research, organization context, and reviewable introductions to Glossia."
  end

  defp page_description(:organization) do
    "Research, product usage, and relationship history for one company."
  end

  defp account_state_label(state) do
    state
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp account_state_color("qualified"), do: "success"
  defp account_state_color("engaging"), do: "primary"
  defp account_state_color("demo_scheduled"), do: "information"
  defp account_state_color("customer"), do: "success"
  defp account_state_color("not_a_fit"), do: "neutral"
  defp account_state_color(_state), do: "warning"

  defp interaction_kind_label(kind) do
    kind
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp interaction_kind_color("message_sent"), do: "primary"
  defp interaction_kind_color("demo"), do: "information"
  defp interaction_kind_color("state_change"), do: "attention"
  defp interaction_kind_color("introduction_draft"), do: "success"
  defp interaction_kind_color(_kind), do: "neutral"

  defp interaction_icon("research"), do: "search"
  defp interaction_icon("introduction_draft"), do: "file_text"
  defp interaction_icon("message_sent"), do: "cube_send"
  defp interaction_icon("demo"), do: "calendar_week"
  defp interaction_icon("state_change"), do: "circle_dashed"
  defp interaction_icon(_kind), do: "checkup_list"

  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%b %-d, %Y at %H:%M UTC")

  defp account_filters do
    states = Organization.states()

    [
      %Filter.Filter{
        id: "state",
        field: "state",
        display_name: "State",
        type: :option,
        options: states,
        options_display_names: Map.new(states, &{&1, account_state_label(&1)}),
        operator: :==,
        value: nil
      }
    ]
  end

  defp account_list_options(active_filters, search, sort_by, sort_order) do
    [search: search, sort_by: sort_by, sort_order: sort_order]
    |> Keyword.merge(account_state_filter_options(active_filters))
  end

  defp account_state_filter_options(active_filters) do
    case Enum.find(active_filters, &(&1.id == "state" and &1.value not in [nil, ""])) do
      %{operator: :==, value: value} -> [state: value]
      %{operator: :!=, value: value} -> [state_not: value]
      _filter -> []
    end
  end

  defp account_sort_by_param(value) when value in ["name", "state", "notes"], do: value
  defp account_sort_by_param(_value), do: "name"

  defp account_sort_order_param(value) when value in ["asc", "desc"], do: value
  defp account_sort_order_param(_value), do: "asc"

  defp account_sort_patch(assigns, column) do
    next_order =
      if assigns.account_sort_by == column and assigns.account_sort_order == "asc",
        do: "desc",
        else: "asc"

    params =
      assigns.uri.query
      |> URI.decode_query()
      |> Map.put("sort_by", column)
      |> Map.put("sort_order", next_order)

    ~p"/growth?#{params}"
  end

  defp parse_uri(uri) do
    uri = URI.parse(uri)
    %{uri | query: uri.query || ""}
  end

  defp new_interaction_form do
    %Interaction{}
    |> Interaction.changeset(%{kind: "note"})
    |> to_form(as: :interaction)
  end

  defp new_account_form do
    %Organization{}
    |> Organization.changeset(%{state: "researching"})
    |> to_form(as: :account)
  end

  defp edit_organization_form(%Organization{} = organization) do
    organization
    |> Organization.changeset(%{})
    |> to_form(as: :organization)
  end

  defp edit_organization_form(_organization), do: nil
end
