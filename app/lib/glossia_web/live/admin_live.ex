defmodule GlossiaWeb.Admin.AdminLive do
  use GlossiaWeb, :live_view

  alias Glossia.Accounts
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Events
  alias Glossia.Discussions
  alias Glossia.Repo

  import Ecto.Query
  import GlossiaWeb.DashboardComponents

  @page_size 25

  @table_prefixes %{
    "users-table" => "",
    "accounts-table" => "a",
    "discussions-table" => "t"
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
        :discussions -> apply_url_params_discussions(socket, params)
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

  defp apply_action(socket, :discussions, _params) do
    assign(socket,
      page_title: gettext("Discussions"),
      discussions: [],
      discussions_total: 0,
      discussions_search: "",
      discussions_sort_key: "created",
      discussions_sort_dir: "desc",
      discussions_page: 1
    )
  end

  defp apply_action(socket, :discussion_show, params) do
    discussion_id = Map.get(params, "discussion_id") || Map.get(params, "ticket_id")
    discussion = Discussions.get_discussion!(discussion_id)

    assign(socket,
      page_title: discussion.title,
      discussion: discussion,
      comment_form: to_form(%{"body" => ""}, as: :comment)
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
  # Discussion admin events
  # ---------------------------------------------------------------------------

  def handle_event("close_discussion", %{"id" => discussion_id}, socket) do
    discussion = Discussions.get_discussion!(discussion_id)
    user = socket.assigns.current_user

    case Discussions.close_discussion(discussion, user) do
      {:ok, updated_discussion} ->
        Events.emit("discussion.closed", updated_discussion.account, user,
          resource_type: "discussion",
          resource_id: to_string(updated_discussion.id),
          resource_path: "/admin/discussions/#{updated_discussion.id}",
          summary: "Closed discussion \"#{updated_discussion.title}\""
        )

        updated_discussion = Discussions.get_discussion!(updated_discussion.id)

        {:noreply,
         socket
         |> assign(discussion: updated_discussion)
         |> put_flash(:info, gettext("Discussion closed."))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to close discussion."))}
    end
  end

  def handle_event("reopen_discussion", %{"id" => discussion_id}, socket) do
    discussion = Discussions.get_discussion!(discussion_id)

    case Discussions.reopen_discussion(discussion, socket.assigns.current_user, via: :dashboard) do
      {:ok, updated_discussion} ->
        updated_discussion = Discussions.get_discussion!(updated_discussion.id)

        {:noreply,
         socket
         |> assign(discussion: updated_discussion)
         |> put_flash(:info, gettext("Discussion reopened."))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to reopen discussion."))}
    end
  end

  def handle_event("admin_comment_discussion", %{"comment" => params}, socket) do
    discussion = socket.assigns.discussion
    user = socket.assigns.current_user

    case Discussions.add_comment(discussion, user, params) do
      {:ok, _comment} ->
        Events.emit("discussion.commented", discussion.account, user,
          resource_type: "discussion",
          resource_id: to_string(discussion.id),
          resource_path: "/admin/discussions/#{discussion.id}",
          summary: "Admin commented on discussion \"#{discussion.title}\""
        )

        discussion = Discussions.get_discussion!(discussion.id)

        {:noreply,
         socket
         |> assign(discussion: discussion, comment_form: to_form(%{"body" => ""}, as: :comment))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not add comment."))}
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
      :discussions -> render_discussions(assigns)
      :discussion_show -> render_discussion_show(assigns)
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
        :discussions -> "/admin/discussions"
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

  defp current_table_state(socket, "discussions-table") do
    %{
      search: socket.assigns[:discussions_search] || "",
      sort: socket.assigns[:discussions_sort_key] || "created",
      dir: socket.assigns[:discussions_sort_dir] || "desc",
      page: socket.assigns[:discussions_page] || 1
    }
  end

  defp current_sort(socket, "users-table"),
    do: {socket.assigns[:users_sort_key] || "created", socket.assigns[:users_sort_dir] || "desc"}

  defp current_sort(socket, "accounts-table"),
    do:
      {socket.assigns[:accounts_sort_key] || "created",
       socket.assigns[:accounts_sort_dir] || "desc"}

  defp current_sort(socket, "discussions-table"),
    do:
      {socket.assigns[:discussions_sort_key] || "created",
       socket.assigns[:discussions_sort_dir] || "desc"}

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
  # Discussions data
  # ---------------------------------------------------------------------------

  defp apply_url_params_discussions(socket, params) do
    search = Map.get(params, "tq", "")
    sort_key = Map.get(params, "tsort", "created")
    sort_dir = Map.get(params, "tdir", "desc")
    page = parse_page(params, "tpage")

    {discussions, total} = list_all_admin_discussions(page, search, sort_key, sort_dir)

    assign(socket,
      discussions: discussions,
      discussions_total: total,
      discussions_search: search,
      discussions_sort_key: sort_key,
      discussions_sort_dir: sort_dir,
      discussions_page: page
    )
  end

  defp list_all_admin_discussions(page, search, sort_key, sort_dir) do
    alias Glossia.Discussions.Discussion

    query = Discussion |> preload([:user, :account])

    query =
      if search != "" do
        pattern = "%#{search}%"
        where(query, [i], ilike(i.title, ^pattern))
      else
        query
      end

    query = apply_discussion_sort(query, sort_key, sort_dir)
    total = Repo.aggregate(query, :count)

    discussions =
      query
      |> limit(@page_size)
      |> offset(^(max(page - 1, 0) * @page_size))
      |> Repo.all()

    {discussions, total}
  end

  defp apply_discussion_sort(query, "title", "asc"), do: order_by(query, asc: :title)
  defp apply_discussion_sort(query, "title", _), do: order_by(query, desc: :title)
  defp apply_discussion_sort(query, "status", "asc"), do: order_by(query, asc: :status)
  defp apply_discussion_sort(query, "status", _), do: order_by(query, desc: :status)
  defp apply_discussion_sort(query, _key, "asc"), do: order_by(query, asc: :inserted_at)
  defp apply_discussion_sort(query, _key, _), do: order_by(query, desc: :inserted_at)

  # ---------------------------------------------------------------------------
  # Render: Discussions
  # ---------------------------------------------------------------------------

  defp render_discussions(assigns) do
    ~H"""
    <.page_header
      title={gettext("Discussions")}
      description={gettext("%{count} discussions total", count: @discussions_total)}
    />

    <.resource_table
      id="discussions-table"
      rows={@discussions}
      search={@discussions_search}
      search_placeholder={gettext("Search by title...")}
      sort_key={@discussions_sort_key}
      sort_dir={@discussions_sort_dir}
      page={@discussions_page}
      per_page={@page_size}
      total={@discussions_total}
    >
      <:col :let={discussion} label="#" key="number" sortable>
        <a href={~p"/admin/discussions/#{discussion.id}"} class="admin-link">
          {"##{discussion.number}"}
        </a>
      </:col>
      <:col :let={discussion} label={gettext("Title")} key="title" sortable>
        <a href={~p"/admin/discussions/#{discussion.id}"} class="admin-link">
          {discussion.title}
        </a>
      </:col>
      <:col :let={discussion} label={gettext("Account")}>
        {discussion.account.handle}
      </:col>
      <:col :let={discussion} label={gettext("Status")} key="status" sortable>
        <.badge variant={discussion_status_variant(discussion.status)}>
          {discussion_status_label(discussion.status)}
        </.badge>
      </:col>
      <:col
        :let={discussion}
        label={gettext("Created")}
        key="created"
        sortable
        class="resource-col-nowrap"
      >
        {Calendar.strftime(discussion.inserted_at, "%Y-%m-%d")}
      </:col>
      <:empty>
        <span class="resource-empty-text">{gettext("No discussions found.")}</span>
      </:empty>
    </.resource_table>
    """
  end

  defp render_discussion_show(assigns) do
    ~H"""
    <.page_header
      title={@discussion.title}
      description={gettext("Discussion from %{handle}", handle: @discussion.account.handle)}
    />

    <div class="ticket-detail-meta">
      <.badge variant={discussion_status_variant(@discussion.status)}>
        {discussion_status_label(@discussion.status)}
      </.badge>
      <span class="ticket-detail-date">
        {gettext("Opened %{date}", date: Calendar.strftime(@discussion.inserted_at, "%b %d, %Y"))}
      </span>
    </div>

    <div style="margin-bottom: var(--space-4);">
      <%= if @discussion.status == "open" do %>
        <button
          phx-click="close_discussion"
          phx-value-id={@discussion.id}
          class="dash-btn dash-btn-secondary"
        >
          {gettext("Close discussion")}
        </button>
      <% else %>
        <button
          phx-click="reopen_discussion"
          phx-value-id={@discussion.id}
          class="dash-btn dash-btn-secondary"
        >
          {gettext("Reopen discussion")}
        </button>
      <% end %>
    </div>

    <div class="ticket-conversation">
      <div class="ticket-comment" id="ticket-body">
        <div class="ticket-comment-header">
          <span class="ticket-comment-author">
            {@discussion.user.name || @discussion.user.email}
          </span>
          <span class="ticket-comment-time">
            {Calendar.strftime(@discussion.inserted_at, "%b %d, %Y at %H:%M")}
          </span>
        </div>
        <div class="ticket-comment-body">{@discussion.body}</div>
      </div>

      <div
        :for={comment <- @discussion.comments}
        class="ticket-comment"
        id={"comment-" <> comment.id}
      >
        <div class="ticket-comment-header">
          <span class="ticket-comment-author">
            {comment.user.name || comment.user.email}
          </span>
          <span class="ticket-comment-time">
            {Calendar.strftime(comment.inserted_at, "%b %d, %Y at %H:%M")}
          </span>
        </div>
        <div class="ticket-comment-body">{comment.body}</div>
      </div>
    </div>

    <.form
      for={@comment_form}
      id="admin-comment-form"
      phx-submit="admin_comment_discussion"
      class="ticket-reply-form"
    >
      <textarea
        name="comment[body]"
        id="admin_comment_body"
        rows="3"
        placeholder={gettext("Write a comment...")}
        required
      >{@comment_form[:body].value}</textarea>
      <button type="submit" class="dash-btn dash-btn-primary">
        {gettext("Add comment")}
      </button>
    </.form>
    """
  end

  defp discussion_status_variant("open"), do: "success"
  defp discussion_status_variant("closed"), do: "neutral"
  defp discussion_status_variant(_), do: "neutral"

  defp discussion_status_label("open"), do: gettext("Open")
  defp discussion_status_label("closed"), do: gettext("Closed")
  defp discussion_status_label(other), do: other
end
