defmodule GlossiaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use GlossiaWeb, :html

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
    <div class="gl-shell" id="gl-shell" data-sidebar={@data_sidebar}>
      <header class="gl-topbar" id="gl-topbar">
        <div class="gl-topbar-left">
          {render_slot(@topbar_prepend)}
          <a class="gl-topbar-logo" href={if @current_user, do: ~p"/dashboard", else: ~p"/"}>
            <img src={~p"/images/logo-rounded.png"} alt="Glossia" width="20" height="20" />
          </a>
          <nav class="gl-topbar-context" aria-label={gettext("Context")}>
            {render_slot(@topbar_context)}
          </nav>
        </div>
        <div class="gl-topbar-right">
          <%= if @current_user do %>
            <div class="gl-avatar-dropdown">
              <% avatar = user_avatar_url(@current_user) %>
              <button class="gl-avatar-toggle" aria-expanded="false" aria-haspopup="true">
                <img
                  src={avatar.src}
                  alt={@current_user.name || @current_user.email}
                  width="24"
                  height="24"
                  data-fallback={avatar.fallback}
                  onload="if(this.naturalWidth===0){this.src=this.dataset.fallback}"
                  onerror="this.src=this.dataset.fallback"
                />
              </button>
              <ul class="gl-avatar-menu" role="menu">
                {render_slot(@avatar_menu_extra)}
                <li role="none">
                  <a role="menuitem" href={~p"/auth/logout"} data-method="delete">
                    {gettext("Log out")}
                  </a>
                </li>
              </ul>
            </div>
          <% else %>
            <a href={~p"/auth/login"} class="gl-btn gl-btn-primary">{gettext("Sign in")}</a>
          <% end %>
        </div>
      </header>
      {render_slot(@extra_banner)}
      <div class="gl-body">
        <.gl_sidebar :if={@show_sidebar}>
          <:header>{render_slot(@sidebar_header)}</:header>
          {render_slot(@sidebar)}
        </.gl_sidebar>
        <div :if={@show_sidebar} class="gl-sidebar-backdrop" id="gl-sidebar-backdrop"></div>
        <div class="gl-content">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    <script>
      (function() {
        document.addEventListener('click', function(e) {
          var avatarToggle = e.target.closest('.gl-avatar-toggle');
          var avatarDd = document.querySelector('.gl-avatar-dropdown');
          if (avatarToggle && avatarDd) {
            e.stopPropagation();
            avatarDd.classList.toggle('open');
            avatarToggle.setAttribute('aria-expanded', avatarDd.classList.contains('open'));
            return;
          }
          if (avatarDd) {
            avatarDd.classList.remove('open');
            var avatarBtn = avatarDd.querySelector('.gl-avatar-toggle');
            if (avatarBtn) avatarBtn.setAttribute('aria-expanded', 'false');
          }
        });

        document.querySelectorAll('a[data-method="delete"]').forEach(function(link) {
          link.addEventListener('click', function(e) {
            e.preventDefault();
            var form = document.createElement('form');
            form.method = 'POST';
            form.action = link.getAttribute('href');
            var csrf = document.querySelector('meta[name="csrf-token"]');
            if (csrf) {
              var csrfInput = document.createElement('input');
              csrfInput.type = 'hidden';
              csrfInput.name = '_csrf_token';
              csrfInput.value = csrf.getAttribute('content');
              form.appendChild(csrfInput);
            }
            var methodInput = document.createElement('input');
            methodInput.type = 'hidden';
            methodInput.name = '_method';
            methodInput.value = 'delete';
            form.appendChild(methodInput);
            document.body.appendChild(form);
            form.submit();
          });
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
