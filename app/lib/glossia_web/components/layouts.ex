defmodule GlossiaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use GlossiaWeb, :html

  import Noora.Breadcrumbs, only: [breadcrumb: 1, breadcrumb_item: 1, breadcrumbs: 1]
  import Noora.Dropdown, only: [dropdown: 1, dropdown_item: 1]
  import Noora.Sidebar, only: [sidebar: 1, sidebar_group: 1, sidebar_item: 1]

  alias Noora.Icon

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  @doc """
  Renders the shared sidebar shell (`<aside class="gl-sidebar">`).

  An optional `:header` slot renders above the nav content (e.g., the user avatar + name in the
  profile layout). The default slot renders the nav content (gl-nav sections with gl-nav-item links).
  """
  attr :id, :string, default: "gl-sidebar"

  slot :header, doc: "Optional content rendered above the nav (e.g., user identity header)"
  slot :inner_block, required: true, doc: "Nav content (gl-nav sections)"

  def gl_sidebar(assigns) do
    ~H"""
    <aside class="gl-sidebar" id={@id}>
      {render_slot(@header)}
      {render_slot(@inner_block)}
    </aside>
    """
  end

  @doc """
  Renders the full application shell shared by the platform and profile layouts.

  Slots that differ between layouts:
  - `:topbar_prepend` -- content before the logo (e.g., sidebar toggle button in the platform layout)
  - `:topbar_context` -- breadcrumb / account-switcher area in the topbar
  - `:avatar_menu_extra` -- extra avatar dropdown items rendered before "Log out"
  - `:extra_banner` -- optional full-width banner between topbar and body (e.g., impersonation)
  - `:sidebar_header` -- optional content above the nav in the sidebar (e.g., user identity)
  - `:sidebar` -- sidebar nav content; when empty, no sidebar is rendered

  The `inner_block` slot is the main page content rendered inside `gl-content`.
  """
  attr :current_scope, :any, default: nil, doc: "The current Scope struct (Phoenix 1.8 pattern)"
  attr :current_user, :map, required: true
  attr :data_sidebar, :string, default: "visible"
  attr :show_sidebar, :boolean, default: true

  slot :topbar_prepend, doc: "Content before the logo in topbar-left (e.g., sidebar toggle)"

  slot :topbar_context,
    doc: "Content inside the topbar context nav (breadcrumbs, account switcher)"

  slot :avatar_menu_extra, doc: "Extra avatar menu items before Log out"
  slot :extra_banner, doc: "Optional banner between topbar and body"
  slot :sidebar_header, doc: "Optional header inside gl-sidebar (e.g., profile user info)"
  slot :sidebar, doc: "Sidebar nav content"
  slot :inner_block, required: true, doc: "Main page content inside gl-content"

  def app_shell(assigns) do
    ~H"""
    <div class="noora-shell" id="noora-shell" data-sidebar={@data_sidebar}>
      <header class="noora-shell__headerbar" id="noora-shell-headerbar">
        <div class="noora-shell__headerbar-left">
          {render_slot(@topbar_prepend)}
          <a class="noora-shell__brand" href={if @current_user, do: ~p"/dashboard", else: ~p"/"}>
            <img
              src={~p"/images/logo-rounded.png"}
              alt="Glossia"
              class="noora-shell__brand-logo"
            />
          </a>
          <nav class="noora-shell__context" aria-label={gettext("Context")}>
            {render_slot(@topbar_context)}
          </nav>
        </div>
        <div class="noora-shell__headerbar-right">
          <Noora.Button.button
            href={~p"/docs"}
            variant="secondary"
            size="medium"
            icon_only
            aria-label={gettext("Docs")}
          >
            <Icon.book />
          </Noora.Button.button>
          <%= if @current_user do %>
            <div class="noora-shell__user-menu">
              <% avatar = user_avatar_url(@current_user) %>
              <.dropdown id="noora-user-menu" icon_only size="medium">
                <:icon>
                  <img
                    src={avatar.src}
                    alt={@current_user.name || @current_user.email}
                    class="noora-shell__avatar"
                    data-fallback={avatar.fallback}
                    onload="if(this.naturalWidth===0){this.src=this.dataset.fallback}"
                    onerror="this.src=this.dataset.fallback"
                  />
                </:icon>
                {render_slot(@avatar_menu_extra)}
                <.dropdown_item
                  value="logout"
                  label={gettext("Log out")}
                  href={~p"/auth/logout"}
                  data-method="delete"
                >
                  <:left_icon><Icon.logout /></:left_icon>
                </.dropdown_item>
              </.dropdown>
            </div>
          <% else %>
            <Noora.Button.button
              href={~p"/auth/login"}
              variant="primary"
              size="medium"
              label={gettext("Sign in")}
            />
          <% end %>
        </div>
      </header>
      {render_slot(@extra_banner)}
      <div class="noora-shell__main">
        <div :if={@show_sidebar} class="noora-shell__sidebar" id="noora-shell-sidebar">
          {render_slot(@sidebar_header)}
          {render_slot(@sidebar)}
        </div>
        <div
          :if={@show_sidebar}
          class="noora-shell__backdrop"
          id="noora-shell-sidebar-backdrop"
        >
        </div>
        <div class="noora-shell__content">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    <script>
      (function() {
        var sidebarToggle = document.getElementById('noora-shell-sidebar-toggle');
        var sidebar = document.getElementById('noora-shell-sidebar');
        var backdrop = document.getElementById('noora-shell-sidebar-backdrop');

        function closeSidebar() {
          if (sidebar) sidebar.classList.remove('open');
          if (backdrop) backdrop.classList.remove('open');
          if (sidebarToggle) sidebarToggle.setAttribute('aria-expanded', 'false');
        }

        if (sidebarToggle) {
          sidebarToggle.addEventListener('click', function(e) {
            e.stopPropagation();
            var open = sidebar && sidebar.classList.toggle('open');
            if (backdrop) backdrop.classList.toggle('open', !!open);
            sidebarToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
          });
        }

        if (backdrop) backdrop.addEventListener('click', closeSidebar);

        if (sidebar) {
          sidebar.addEventListener('click', function(e) {
            if (e.target.closest('a')) closeSidebar();
          });
        }

        document.addEventListener('keydown', function(e) {
          if (e.key === 'Escape') closeSidebar();
        });
      })();
    </script>
    """
  end

  defp user_avatar_url(user) do
    fallback = gravatar_url(user.email)

    primary =
      cond do
        is_binary(user.avatar_url) and String.starts_with?(user.avatar_url, "avatars/users/") ->
          case Regex.run(~r{^avatars/users/([^/.]+)}, user.avatar_url) do
            [_, user_id] -> "/avatars/users/#{user_id}"
            _ -> nil
          end

        is_binary(user.avatar_url) and user.avatar_url != "" ->
          user.avatar_url

        true ->
          nil
      end

    %{src: primary || fallback, fallback: fallback}
  end

  defp gravatar_url(email) do
    hash =
      :crypto.hash(:md5, String.downcase(String.trim(email)))
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=64&d=identicon"
  end
end
