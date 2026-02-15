defmodule GlossiaWeb.Admin.AdminLive do
  use GlossiaWeb, :live_view

  alias Glossia.Accounts
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Auditing
  alias Glossia.Repo
  alias Glossia.Support

  import Ecto.Query
  import GlossiaWeb.DashboardComponents

  @page_size 25

  @table_prefixes %{
    "users-table" => "",
    "accounts-table" => "a",
    "tickets-table" => "t"
  }

  # ---------------------------------------------------------------------------
  # Mount
  # ---------------------------------------------------------------------------

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_size: @page_size,
       show_impersonate_modal: false,
       impersonate_user_id: nil,
       impersonate_email: nil
     )}
  end

  # ---------------------------------------------------------------------------
  # Handle params (dispatches per live_action)
  # ---------------------------------------------------------------------------

  def handle_params(params, _uri, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)

    socket =
      case socket.assigns.live_action do
        :users -> apply_url_params_users(socket, params)
        :accounts -> apply_url_params_accounts(socket, params)
        :tickets -> apply_url_params_tickets(socket, params)
        _ -> socket
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :home, _params) do
    user_count = Repo.aggregate(User, :count)
    account_count = Repo.aggregate(Account, :count)

    org_count =
      Account
      |> where(type: "organization")
      |> Repo.aggregate(:count)

    assign(socket,
      page_title: gettext("Admin Overview"),
      user_count: user_count,
      account_count: account_count,
      org_count: org_count
    )
  end

  defp apply_action(socket, :users, _params) do
    assign(socket,
      page_title: gettext("Users"),
      users: [],
      users_total: 0,
      users_search: "",
      users_sort_key: "created",
      users_sort_dir: "desc",
      users_page: 1
    )
  end

  defp apply_action(socket, :accounts, _params) do
    assign(socket,
      page_title: gettext("Accounts"),
      accounts: [],
      accounts_total: 0,
      accounts_search: "",
      accounts_sort_key: "created",
      accounts_sort_dir: "desc",
      accounts_page: 1
    )
  end

  defp apply_action(socket, :tickets, _params) do
    assign(socket,
      page_title: gettext("Tickets"),
      tickets: [],
      tickets_total: 0,
      tickets_search: "",
      tickets_sort_key: "created",
      tickets_sort_dir: "desc",
      tickets_page: 1
    )
  end

  defp apply_action(socket, :ticket_show, %{"ticket_id" => ticket_id}) do
    ticket = Support.get_ticket!(ticket_id)

    assign(socket,
      page_title: ticket.title,
      ticket: ticket,
      message_form: to_form(%{"body" => ""}, as: :message)
    )
  end

  defp apply_url_params_users(socket, params) do
    search = Map.get(params, "q", "")
    sort_key = Map.get(params, "sort", "created")
    sort_dir = Map.get(params, "dir", "desc")
    page = parse_page(params, "page")

    {users, total} = list_users(page, search, sort_key, sort_dir)

    assign(socket,
      users: users,
      users_total: total,
      users_search: search,
      users_sort_key: sort_key,
      users_sort_dir: sort_dir,
      users_page: page
    )
  end

  defp apply_url_params_accounts(socket, params) do
    search = Map.get(params, "aq", "")
    sort_key = Map.get(params, "asort", "created")
    sort_dir = Map.get(params, "adir", "desc")
    page = parse_page(params, "apage")

    {accounts, total} = list_accounts(page, search, sort_key, sort_dir)

    assign(socket,
      accounts: accounts,
      accounts_total: total,
      accounts_search: search,
      accounts_sort_key: sort_key,
      accounts_sort_dir: sort_dir,
      accounts_page: page
    )
  end

  # ---------------------------------------------------------------------------
  # Resource table events
  # ---------------------------------------------------------------------------

  def handle_event("resource_search", %{"search" => q, "table_id" => table_id}, socket) do
    {:noreply, push_table_params(socket, table_id, %{search: q, page: 1})}
  end

  def handle_event("resource_sort", %{"key" => key, "table_id" => table_id}, socket) do
    {cur_key, cur_dir} = current_sort(socket, table_id)
    dir = if cur_key == key && cur_dir == "asc", do: "desc", else: "asc"
    {:noreply, push_table_params(socket, table_id, %{sort: key, dir: dir})}
  end

  def handle_event("resource_page", %{"page" => page, "table_id" => table_id}, socket) do
    {:noreply, push_table_params(socket, table_id, %{page: String.to_integer(page)})}
  end

  # ---------------------------------------------------------------------------
  # Mutation events
  # ---------------------------------------------------------------------------

  def handle_event("grant_access", %{"email" => email}, socket) do
    case Accounts.grant_access(email) do
      {:ok, _user} ->
        {users, total} = reload_users(socket)
        {:noreply, assign(socket, users: users, users_total: total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to grant access."))}
    end
  end

  def handle_event("revoke_access", %{"email" => email}, socket) do
    case Accounts.revoke_access(email) do
      {:ok, _user} ->
        {users, total} = reload_users(socket)
        {:noreply, assign(socket, users: users, users_total: total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to revoke access."))}
    end
  end

  def handle_event("toggle_super_admin", %{"user-id" => user_id, "value" => value}, socket) do
    new_value = value == "true"

    case Accounts.set_super_admin(user_id, new_value) do
      {:ok, _user} ->
        {users, total} = reload_users(socket)
        {:noreply, assign(socket, users: users, users_total: total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update super admin status."))}
    end
  end

  # ---------------------------------------------------------------------------
  # Ticket admin events
  # ---------------------------------------------------------------------------

  def handle_event("update_ticket_status", %{"id" => ticket_id, "status" => status}, socket) do
    ticket = Support.get_ticket!(ticket_id)
    user = socket.assigns.current_user

    resolved_by = if status in ~w(resolved implemented), do: user, else: nil

    case Support.update_ticket_status(ticket, status, resolved_by) do
      {:ok, updated_ticket} ->
        Auditing.record("ticket.status_changed", updated_ticket.account, user,
          resource_type: "ticket",
          resource_id: to_string(updated_ticket.id),
          summary: "Changed ticket status to \"#{status}\""
        )

        updated_ticket = Support.get_ticket!(updated_ticket.id)

        {:noreply,
         socket
         |> assign(ticket: updated_ticket)
         |> put_flash(:info, gettext("Ticket status updated."))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update ticket status."))}
    end
  end

  def handle_event("admin_reply_ticket", %{"message" => params}, socket) do
    ticket = socket.assigns.ticket
    user = socket.assigns.current_user

    case Support.add_message(ticket, user, params, is_staff: true) do
      {:ok, _message} ->
        Auditing.record("ticket.replied", ticket.account, user,
          resource_type: "ticket",
          resource_id: to_string(ticket.id),
          summary: "Staff replied to ticket \"#{ticket.title}\""
        )

        ticket = Support.get_ticket!(ticket.id)

        {:noreply,
         socket
         |> assign(ticket: ticket, message_form: to_form(%{"body" => ""}, as: :message))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not send message."))}
    end
  end

  # ---------------------------------------------------------------------------
  # Impersonation modal events
  # ---------------------------------------------------------------------------

  def handle_event("start_impersonate", %{"user-id" => user_id, "email" => email}, socket) do
    {:noreply,
     assign(socket,
       show_impersonate_modal: true,
       impersonate_user_id: user_id,
       impersonate_email: email
     )}
  end

  def handle_event("cancel_impersonate", _params, socket) do
    {:noreply, assign(socket, show_impersonate_modal: false)}
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  def render(assigns) do
    case assigns.live_action do
      :home -> render_home(assigns)
      :users -> render_users(assigns)
      :accounts -> render_accounts(assigns)
      :tickets -> render_tickets(assigns)
      :ticket_show -> render_ticket_show(assigns)
    end
  end

  defp render_home(assigns) do
    ~H"""
    <.page_header
      title={gettext("Overview")}
      description={gettext("System-wide metrics at a glance.")}
    />

    <div class="admin-stat-grid">
      <div class="admin-stat-card">
        <div class="admin-stat-label">{gettext("Users")}</div>
        <div class="admin-stat-value">{@user_count}</div>
      </div>
      <div class="admin-stat-card">
        <div class="admin-stat-label">{gettext("Accounts")}</div>
        <div class="admin-stat-value">{@account_count}</div>
      </div>
      <div class="admin-stat-card">
        <div class="admin-stat-label">{gettext("Organizations")}</div>
        <div class="admin-stat-value">{@org_count}</div>
      </div>
    </div>
    """
  end

  defp render_users(assigns) do
    ~H"""
    <.page_header
      title={gettext("Users")}
      description={gettext("%{count} users total", count: @users_total)}
    />

    <.resource_table
      id="users-table"
      rows={@users}
      search={@users_search}
      search_placeholder={gettext("Search by email or name...")}
      sort_key={@users_sort_key}
      sort_dir={@users_sort_dir}
      page={@users_page}
      per_page={@page_size}
      total={@users_total}
    >
      <:col :let={user} label={gettext("Email")} key="email" sortable>
        {user.email}
      </:col>
      <:col :let={user} label={gettext("Name")} key="name" sortable>
        {user.name || "-"}
      </:col>
      <:col :let={user} label={gettext("Access")}>
        <.badge variant={if(user.has_access, do: "success", else: "neutral")}>
          {if user.has_access, do: gettext("Yes"), else: gettext("No")}
        </.badge>
      </:col>
      <:col :let={user} label={gettext("Super Admin")}>
        <.badge variant={if(user.super_admin, do: "warning", else: "neutral")}>
          {if user.super_admin, do: gettext("Yes"), else: gettext("No")}
        </.badge>
      </:col>
      <:col :let={user} label={gettext("Created")} key="created" sortable class="resource-col-nowrap">
        {Calendar.strftime(user.inserted_at, "%Y-%m-%d")}
      </:col>
      <:action :let={user}>
        <div class="admin-action-group">
          <%= if user.has_access do %>
            <button
              phx-click="revoke_access"
              phx-value-email={user.email}
              class="dash-btn dash-btn-secondary admin-action-btn"
            >
              {gettext("Revoke")}
            </button>
          <% else %>
            <button
              phx-click="grant_access"
              phx-value-email={user.email}
              class="dash-btn dash-btn-primary admin-action-btn"
            >
              {gettext("Grant")}
            </button>
          <% end %>
          <button
            phx-click="toggle_super_admin"
            phx-value-user-id={user.id}
            phx-value-value={if user.super_admin, do: "false", else: "true"}
            class="dash-btn dash-btn-secondary admin-action-btn"
          >
            {if user.super_admin, do: gettext("Remove admin"), else: gettext("Make admin")}
          </button>
          <button
            :if={user.id != @current_user.id}
            phx-click="start_impersonate"
            phx-value-user-id={user.id}
            phx-value-email={user.email}
            class="dash-btn dash-btn-secondary admin-action-btn"
          >
            {gettext("Impersonate")}
          </button>
        </div>
      </:action>
      <:empty>
        <span class="resource-empty-text">{gettext("No users found.")}</span>
      </:empty>
    </.resource_table>

    <%= if @show_impersonate_modal do %>
      <div class="impersonate-modal-overlay" id="impersonate-modal">
        <div class="impersonate-modal">
          <h3>{gettext("Impersonate %{email}", email: @impersonate_email)}</h3>
          <p class="impersonate-modal-desc">
            {gettext(
              "Provide a reason for this impersonation. This will be recorded in the audit log."
            )}
          </p>
          <form method="post" action={~p"/admin/impersonate"} id="impersonate-form">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <input type="hidden" name="user_id" value={@impersonate_user_id} />
            <div class="impersonate-modal-field">
              <input
                type="text"
                name="reason"
                placeholder={gettext("Reason for impersonation...")}
                required
                class="resource-search"
                autofocus
              />
            </div>
            <div class="impersonate-modal-actions">
              <button
                type="button"
                phx-click="cancel_impersonate"
                class="dash-btn dash-btn-secondary"
              >
                {gettext("Cancel")}
              </button>
              <button type="submit" class="dash-btn dash-btn-primary">
                {gettext("Impersonate")}
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_accounts(assigns) do
    ~H"""
    <.page_header
      title={gettext("Accounts")}
      description={gettext("%{count} accounts total", count: @accounts_total)}
    />

    <.resource_table
      id="accounts-table"
      rows={@accounts}
      search={@accounts_search}
      search_placeholder={gettext("Search by handle...")}
      sort_key={@accounts_sort_key}
      sort_dir={@accounts_sort_dir}
      page={@accounts_page}
      per_page={@page_size}
      total={@accounts_total}
    >
      <:col :let={account} label={gettext("Handle")} key="handle" sortable>
        <a href={~p"/#{account.handle}"} class="admin-link">{account.handle}</a>
      </:col>
      <:col :let={account} label={gettext("Type")} key="type" sortable>
        <.badge variant={if(account.type == "organization", do: "info", else: "neutral")}>
          {account.type}
        </.badge>
      </:col>
      <:col :let={account} label={gettext("Visibility")}>
        {account.visibility || "private"}
      </:col>
      <:col :let={account} label={gettext("Access")}>
        <.badge variant={if(account.has_access, do: "success", else: "neutral")}>
          {if account.has_access, do: gettext("Yes"), else: gettext("No")}
        </.badge>
      </:col>
      <:col
        :let={account}
        label={gettext("Created")}
        key="created"
        sortable
        class="resource-col-nowrap"
      >
        {Calendar.strftime(account.inserted_at, "%Y-%m-%d")}
      </:col>
      <:empty>
        <span class="resource-empty-text">{gettext("No accounts found.")}</span>
      </:empty>
    </.resource_table>
    """
  end

  # ---------------------------------------------------------------------------
  # Table URL helpers
  # ---------------------------------------------------------------------------

  defp push_table_params(socket, table_id, overrides) do
    prefix = Map.get(@table_prefixes, table_id, "")
    current = current_table_state(socket, table_id)
    merged = Map.merge(current, overrides)

    query_params =
      []
      |> maybe_add_param(prefix <> "q", merged[:search], "")
      |> maybe_add_param(prefix <> "sort", merged[:sort], default_sort_key(table_id))
      |> maybe_add_param(prefix <> "dir", merged[:dir], default_sort_dir(table_id))
      |> maybe_add_param(prefix <> "page", merged[:page], 1)

    path =
      case socket.assigns.live_action do
        :users -> "/admin/users"
        :accounts -> "/admin/accounts"
        :tickets -> "/admin/tickets"
        _ -> "/admin"
      end

    url = if query_params == [], do: path, else: path <> "?" <> URI.encode_query(query_params)
    push_patch(socket, to: url)
  end

  defp current_table_state(socket, "users-table") do
    %{
      search: socket.assigns[:users_search] || "",
      sort: socket.assigns[:users_sort_key] || "created",
      dir: socket.assigns[:users_sort_dir] || "desc",
      page: socket.assigns[:users_page] || 1
    }
  end

  defp current_table_state(socket, "accounts-table") do
    %{
      search: socket.assigns[:accounts_search] || "",
      sort: socket.assigns[:accounts_sort_key] || "created",
      dir: socket.assigns[:accounts_sort_dir] || "desc",
      page: socket.assigns[:accounts_page] || 1
    }
  end

  defp current_table_state(socket, "tickets-table") do
    %{
      search: socket.assigns[:tickets_search] || "",
      sort: socket.assigns[:tickets_sort_key] || "created",
      dir: socket.assigns[:tickets_sort_dir] || "desc",
      page: socket.assigns[:tickets_page] || 1
    }
  end

  defp current_sort(socket, "users-table"),
    do: {socket.assigns[:users_sort_key] || "created", socket.assigns[:users_sort_dir] || "desc"}

  defp current_sort(socket, "accounts-table"),
    do:
      {socket.assigns[:accounts_sort_key] || "created",
       socket.assigns[:accounts_sort_dir] || "desc"}

  defp current_sort(socket, "tickets-table"),
    do:
      {socket.assigns[:tickets_sort_key] || "created",
       socket.assigns[:tickets_sort_dir] || "desc"}

  defp default_sort_key(_table_id), do: "created"
  defp default_sort_dir(_table_id), do: "desc"

  defp maybe_add_param(params, _key, value, default) when value == default, do: params
  defp maybe_add_param(params, key, value, _default), do: params ++ [{key, to_string(value)}]

  # ---------------------------------------------------------------------------
  # Data helpers
  # ---------------------------------------------------------------------------

  defp reload_users(socket) do
    list_users(
      socket.assigns.users_page,
      socket.assigns.users_search,
      socket.assigns.users_sort_key,
      socket.assigns.users_sort_dir
    )
  end

  defp list_users(page, search, sort_key, sort_dir) do
    query = User |> preload(:account)

    query =
      if search != "" do
        pattern = "%#{search}%"
        where(query, [u], ilike(u.email, ^pattern) or ilike(u.name, ^pattern))
      else
        query
      end

    query = apply_user_sort(query, sort_key, sort_dir)
    total = Repo.aggregate(query, :count)

    users =
      query
      |> limit(@page_size)
      |> offset(^(max(page - 1, 0) * @page_size))
      |> Repo.all()

    {users, total}
  end

  defp apply_user_sort(query, "email", "asc"), do: order_by(query, asc: :email)
  defp apply_user_sort(query, "email", _), do: order_by(query, desc: :email)
  defp apply_user_sort(query, "name", "asc"), do: order_by(query, asc: :name)
  defp apply_user_sort(query, "name", _), do: order_by(query, desc: :name)
  defp apply_user_sort(query, _key, "asc"), do: order_by(query, asc: :inserted_at)
  defp apply_user_sort(query, _key, _), do: order_by(query, desc: :inserted_at)

  defp list_accounts(page, search, sort_key, sort_dir) do
    query = Account

    query =
      if search != "" do
        pattern = "%#{search}%"
        where(query, [a], ilike(a.handle, ^pattern))
      else
        query
      end

    query = apply_account_sort(query, sort_key, sort_dir)
    total = Repo.aggregate(query, :count)

    accounts =
      query
      |> limit(@page_size)
      |> offset(^(max(page - 1, 0) * @page_size))
      |> Repo.all()

    {accounts, total}
  end

  defp apply_account_sort(query, "handle", "asc"), do: order_by(query, asc: :handle)
  defp apply_account_sort(query, "handle", _), do: order_by(query, desc: :handle)
  defp apply_account_sort(query, "type", "asc"), do: order_by(query, asc: :type)
  defp apply_account_sort(query, "type", _), do: order_by(query, desc: :type)
  defp apply_account_sort(query, _key, "asc"), do: order_by(query, asc: :inserted_at)
  defp apply_account_sort(query, _key, _), do: order_by(query, desc: :inserted_at)

  defp parse_page(params, key) do
    case Integer.parse(Map.get(params, key, "1")) do
      {page, _} when page > 0 -> page
      _ -> 1
    end
  end

  # ---------------------------------------------------------------------------
  # Tickets data
  # ---------------------------------------------------------------------------

  defp apply_url_params_tickets(socket, params) do
    search = Map.get(params, "tq", "")
    sort_key = Map.get(params, "tsort", "created")
    sort_dir = Map.get(params, "tdir", "desc")
    page = parse_page(params, "tpage")

    {tickets, total} = list_all_tickets(page, search, sort_key, sort_dir)

    assign(socket,
      tickets: tickets,
      tickets_total: total,
      tickets_search: search,
      tickets_sort_key: sort_key,
      tickets_sort_dir: sort_dir,
      tickets_page: page
    )
  end

  defp list_all_tickets(page, search, sort_key, sort_dir) do
    alias Glossia.Support.Ticket

    query = Ticket |> preload([:user, :account])

    query =
      if search != "" do
        pattern = "%#{search}%"
        where(query, [t], ilike(t.title, ^pattern))
      else
        query
      end

    query = apply_ticket_sort(query, sort_key, sort_dir)
    total = Repo.aggregate(query, :count)

    tickets =
      query
      |> limit(@page_size)
      |> offset(^(max(page - 1, 0) * @page_size))
      |> Repo.all()

    {tickets, total}
  end

  defp apply_ticket_sort(query, "title", "asc"), do: order_by(query, asc: :title)
  defp apply_ticket_sort(query, "title", _), do: order_by(query, desc: :title)
  defp apply_ticket_sort(query, "status", "asc"), do: order_by(query, asc: :status)
  defp apply_ticket_sort(query, "status", _), do: order_by(query, desc: :status)
  defp apply_ticket_sort(query, _key, "asc"), do: order_by(query, asc: :inserted_at)
  defp apply_ticket_sort(query, _key, _), do: order_by(query, desc: :inserted_at)

  # ---------------------------------------------------------------------------
  # Render: Tickets
  # ---------------------------------------------------------------------------

  defp render_tickets(assigns) do
    ~H"""
    <.page_header
      title={gettext("Tickets")}
      description={gettext("%{count} tickets total", count: @tickets_total)}
    />

    <.resource_table
      id="tickets-table"
      rows={@tickets}
      search={@tickets_search}
      search_placeholder={gettext("Search by title...")}
      sort_key={@tickets_sort_key}
      sort_dir={@tickets_sort_dir}
      page={@tickets_page}
      per_page={@page_size}
      total={@tickets_total}
    >
      <:col :let={ticket} label="#" key="number" sortable>
        <a href={~p"/admin/tickets/#{ticket.id}"} class="admin-link">{"##{ticket.number}"}</a>
      </:col>
      <:col :let={ticket} label={gettext("Title")} key="title" sortable>
        <a href={~p"/admin/tickets/#{ticket.id}"} class="admin-link">{ticket.title}</a>
      </:col>
      <:col :let={ticket} label={gettext("Account")}>
        {ticket.account.handle}
      </:col>
      <:col :let={ticket} label={gettext("Type")}>
        <.badge variant={ticket_type_variant(ticket.type)}>
          {ticket_type_label(ticket.type)}
        </.badge>
      </:col>
      <:col :let={ticket} label={gettext("Status")} key="status" sortable>
        <.badge variant={ticket_status_variant(ticket.status)}>
          {ticket_status_label(ticket.status)}
        </.badge>
      </:col>
      <:col
        :let={ticket}
        label={gettext("Created")}
        key="created"
        sortable
        class="resource-col-nowrap"
      >
        {Calendar.strftime(ticket.inserted_at, "%Y-%m-%d")}
      </:col>
      <:empty>
        <span class="resource-empty-text">{gettext("No tickets found.")}</span>
      </:empty>
    </.resource_table>
    """
  end

  defp render_ticket_show(assigns) do
    ~H"""
    <.page_header
      title={@ticket.title}
      description={gettext("Ticket from %{handle}", handle: @ticket.account.handle)}
    />

    <div class="ticket-detail-meta">
      <.badge variant={ticket_type_variant(@ticket.type)}>
        {ticket_type_label(@ticket.type)}
      </.badge>
      <.badge variant={ticket_status_variant(@ticket.status)}>
        {ticket_status_label(@ticket.status)}
      </.badge>
      <span class="ticket-detail-date">
        {gettext("Opened %{date}", date: Calendar.strftime(@ticket.inserted_at, "%b %d, %Y"))}
      </span>
    </div>

    <div style="margin-bottom: var(--space-4);">
      <label
        for="ticket-status-select"
        style="font-weight: var(--weight-medium); margin-right: var(--space-2);"
      >
        {gettext("Change status:")}
      </label>
      <select
        id="ticket-status-select"
        phx-change="update_ticket_status"
        name="status"
        phx-value-id={@ticket.id}
        style="padding: var(--space-1) var(--space-2); border-radius: var(--radius-md); border: 1px solid var(--color-border);"
      >
        <option value="open" selected={@ticket.status == "open"}>{gettext("Open")}</option>
        <option value="in_progress" selected={@ticket.status == "in_progress"}>
          {gettext("In progress")}
        </option>
        <option value="resolved" selected={@ticket.status == "resolved"}>
          {gettext("Resolved")}
        </option>
        <option value="implemented" selected={@ticket.status == "implemented"}>
          {gettext("Implemented")}
        </option>
      </select>
    </div>

    <div class="ticket-conversation">
      <div class="ticket-message ticket-message-user" id="ticket-description">
        <div class="ticket-message-header">
          <span class="ticket-message-author">{@ticket.user.name || @ticket.user.email}</span>
          <span class="ticket-message-time">
            {Calendar.strftime(@ticket.inserted_at, "%b %d, %Y at %H:%M")}
          </span>
        </div>
        <div class="ticket-message-body">{@ticket.description}</div>
      </div>

      <div
        :for={msg <- @ticket.messages}
        class={[
          "ticket-message",
          if(msg.is_staff, do: "ticket-message-staff", else: "ticket-message-user")
        ]}
        id={"msg-" <> msg.id}
      >
        <div class="ticket-message-header">
          <span class="ticket-message-author">
            {msg.user.name || msg.user.email}
            <.badge :if={msg.is_staff} variant="info">{gettext("Staff")}</.badge>
          </span>
          <span class="ticket-message-time">
            {Calendar.strftime(msg.inserted_at, "%b %d, %Y at %H:%M")}
          </span>
        </div>
        <div class="ticket-message-body">{msg.body}</div>
      </div>
    </div>

    <.form
      for={@message_form}
      id="admin-message-form"
      phx-submit="admin_reply_ticket"
      class="ticket-reply-form"
    >
      <textarea
        name="message[body]"
        id="admin_message_body"
        rows="3"
        placeholder={gettext("Write a staff reply...")}
        required
      >{@message_form[:body].value}</textarea>
      <button type="submit" class="dash-btn dash-btn-primary">
        {gettext("Send staff reply")}
      </button>
    </.form>
    """
  end

  defp ticket_status_variant("open"), do: "neutral"
  defp ticket_status_variant("in_progress"), do: "info"
  defp ticket_status_variant("resolved"), do: "success"
  defp ticket_status_variant("implemented"), do: "success"
  defp ticket_status_variant(_), do: "neutral"

  defp ticket_status_label("open"), do: gettext("Open")
  defp ticket_status_label("in_progress"), do: gettext("In progress")
  defp ticket_status_label("resolved"), do: gettext("Resolved")
  defp ticket_status_label("implemented"), do: gettext("Implemented")
  defp ticket_status_label(other), do: other

  defp ticket_type_variant("issue"), do: "warning"
  defp ticket_type_variant("request"), do: "info"
  defp ticket_type_variant(_), do: "neutral"

  defp ticket_type_label("issue"), do: gettext("Issue")
  defp ticket_type_label("request"), do: gettext("Feature request")
  defp ticket_type_label(other), do: other
end
