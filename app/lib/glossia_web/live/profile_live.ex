defmodule GlossiaWeb.ProfileLive do
  use GlossiaWeb, :live_view
  import GlossiaWeb.DashboardComponents

  # ---------------------------------------------------------------------------
  # Mount
  # ---------------------------------------------------------------------------

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # ---------------------------------------------------------------------------
  # Handle params
  # ---------------------------------------------------------------------------

  def handle_params(_params, _uri, socket) do
    socket = apply_action(socket, socket.assigns.live_action)
    {:noreply, socket}
  end

  defp apply_action(socket, :overview) do
    user = socket.assigns.current_user

    form =
      to_form(
        %{
          "name" => user.name || "",
          "bio" => user.bio || "",
          "github_url" => user.github_url || "",
          "x_url" => user.x_url || "",
          "linkedin_url" => user.linkedin_url || "",
          "mastodon_url" => user.mastodon_url || ""
        },
        as: :profile
      )

    gravatar = gravatar_url(user.email)

    assign(socket,
      page_title: gettext("Profile"),
      breadcrumb_label: gettext("Profile"),
      profile_form: form,
      profile_changed?: false,
      user_avatar_url: resolve_avatar_display_url(user.avatar_url, gravatar),
      gravatar_url: gravatar
    )
  end

  defp apply_action(socket, :connected_accounts) do
    user = socket.assigns.current_user
    identities = Glossia.Accounts.list_user_identities(user)

    assign(socket,
      page_title: gettext("Connections"),
      breadcrumb_label: gettext("Connections"),
      identities: identities
    )
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  def handle_event("validate_profile", %{"profile" => params}, socket) do
    user = socket.assigns.current_user

    changed? =
      String.trim(params["name"] || "") != (user.name || "") or
        String.trim(params["bio"] || "") != (user.bio || "") or
        String.trim(params["github_url"] || "") != (user.github_url || "") or
        String.trim(params["x_url"] || "") != (user.x_url || "") or
        String.trim(params["linkedin_url"] || "") != (user.linkedin_url || "") or
        String.trim(params["mastodon_url"] || "") != (user.mastodon_url || "")

    form = to_form(params, as: :profile)
    {:noreply, assign(socket, profile_changed?: changed?, profile_form: form)}
  end

  def handle_event("save_profile", %{"profile" => params}, socket) do
    user = socket.assigns.current_user

    case Glossia.Accounts.update_user_profile(user, params) do
      {:ok, updated_user} ->
        refreshed_user = Glossia.Accounts.get_user(updated_user.id)

        {:noreply,
         socket
         |> assign(:current_user, refreshed_user)
         |> assign(:current_scope, Glossia.Accounts.Scope.for_user(refreshed_user))
         |> put_flash(:info, gettext("Profile updated."))
         |> push_patch(to: ~p"/-/settings/profile")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not update profile."))}
    end
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :overview -> %>
        <.overview_page
          current_user={@current_user}
          profile_form={@profile_form}
          profile_changed?={@profile_changed?}
          user_avatar_url={@user_avatar_url}
          gravatar_url={@gravatar_url}
        />
      <% :connected_accounts -> %>
        <.connected_accounts_page identities={@identities} />
    <% end %>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Profile overview
  # ---------------------------------------------------------------------------

  defp overview_page(assigns) do
    ~H"""
    <div class="profile-page">
      <div class="profile-page-header">
        <h1 class="profile-page-title">{gettext("Profile")}</h1>
        <p class="profile-page-description">
          {gettext("Manage your personal profile and account information.")}
        </p>
      </div>

      <div class="voice-section">
        <div class="voice-section-info">
          <h2>{gettext("Avatar")}</h2>
        </div>
        <div class="voice-card">
          <div class="voice-card-fields">
            <.form
              for={%{}}
              id="profile-avatar-form"
              action={~p"/-/settings/profile/avatar"}
              multipart
            >
              <label
                id="profile-avatar-picker"
                for="profile-avatar-input"
                class="user-avatar-picker"
                phx-hook=".AvatarPicker"
                data-form-id="profile-avatar-form"
                data-input-id="profile-avatar-input"
                data-fallback={@gravatar_url}
              >
                <img
                  src={@user_avatar_url}
                  alt={@current_user.name || @current_user.email}
                  class="user-avatar-img"
                />
              </label>
              <input
                id="profile-avatar-input"
                type="file"
                name="avatar"
                accept=".jpg,.jpeg,.png,.gif,.webp"
                class="user-avatar-file-input-hidden"
              />
            </.form>
          </div>
        </div>
      </div>

      <div class="voice-section-divider"></div>

      <.form
        for={@profile_form}
        id="profile-form"
        phx-submit="save_profile"
        phx-change="validate_profile"
      >
        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("Personal information")}</h2>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <div class="voice-field">
                <label>{gettext("Email")}</label>
                <input
                  type="email"
                  value={@current_user.email}
                  disabled
                  style="opacity: 0.6; cursor: not-allowed;"
                />
                <span class="voice-field-help">
                  {gettext("Email cannot be changed here.")}
                </span>
              </div>
              <div class="voice-field">
                <label for="profile-name">{gettext("Name")}</label>
                <input
                  type="text"
                  id="profile-name"
                  name="profile[name]"
                  value={@profile_form[:name].value}
                  placeholder={gettext("Your display name")}
                />
              </div>
              <div class="voice-field">
                <label for="profile-bio">{gettext("Bio")}</label>
                <textarea
                  id="profile-bio"
                  name="profile[bio]"
                  rows="3"
                  placeholder={gettext("A short description about yourself")}
                >{@profile_form[:bio].value}</textarea>
              </div>
            </div>
          </div>
        </div>

        <div class="voice-section-divider"></div>

        <div class="voice-section">
          <div class="voice-section-info">
            <h2>{gettext("Social links")}</h2>
            <p>{gettext("Add links to your social profiles.")}</p>
          </div>
          <div class="voice-card">
            <div class="voice-card-fields">
              <div class="voice-field">
                <label for="profile-github-url">{gettext("GitHub")}</label>
                <input
                  type="url"
                  id="profile-github-url"
                  name="profile[github_url]"
                  value={@profile_form[:github_url].value}
                  placeholder="https://github.com/username"
                />
              </div>
              <div class="voice-field">
                <label for="profile-x-url">{gettext("X (Twitter)")}</label>
                <input
                  type="url"
                  id="profile-x-url"
                  name="profile[x_url]"
                  value={@profile_form[:x_url].value}
                  placeholder="https://x.com/username"
                />
              </div>
              <div class="voice-field">
                <label for="profile-linkedin-url">{gettext("LinkedIn")}</label>
                <input
                  type="url"
                  id="profile-linkedin-url"
                  name="profile[linkedin_url]"
                  value={@profile_form[:linkedin_url].value}
                  placeholder="https://linkedin.com/in/username"
                />
              </div>
              <div class="voice-field">
                <label for="profile-mastodon-url">{gettext("Mastodon")}</label>
                <input
                  type="url"
                  id="profile-mastodon-url"
                  name="profile[mastodon_url]"
                  value={@profile_form[:mastodon_url].value}
                  placeholder="https://mastodon.social/@username"
                />
              </div>
            </div>
          </div>
        </div>

        <.form_save_bar
          id="profile-save-bar"
          visible={@profile_changed?}
          cancel_path={~p"/-/settings/profile"}
        />
      </.form>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".AvatarPicker">
        export default {
          mounted() {
            const formId = this.el.dataset.formId;
            const inputId = this.el.dataset.inputId;
            const fallback = this.el.dataset.fallback;
            const img = this.el.querySelector("img");
            const input = () => document.getElementById(inputId);
            const form = () => document.getElementById(formId);

            if (img && fallback) {
              const useFallback = () => { if (img.src !== fallback) img.src = fallback; };
              img.addEventListener("error", useFallback);
              if (img.complete && img.naturalWidth === 0) useFallback();
              else img.addEventListener("load", () => { if (img.naturalWidth === 0) useFallback(); });
            }

            this.onInputChange = () => {
              const f = form();
              const i = input();
              if (f && i && i.files.length > 0) f.submit();
            };
            input()?.addEventListener("change", this.onInputChange);

            this.onDragOver = (e) => { e.preventDefault(); this.el.dataset.dragging = "true"; };
            this.onDragLeave = () => { delete this.el.dataset.dragging; };
            this.onDrop = (e) => {
              e.preventDefault();
              delete this.el.dataset.dragging;
              const file = e.dataTransfer?.files?.[0];
              if (!file || !file.type.startsWith("image/")) return;
              const dt = new DataTransfer();
              dt.items.add(file);
              const i = input();
              if (i) { i.files = dt.files; i.dispatchEvent(new Event("change")); }
            };

            this.el.addEventListener("dragover", this.onDragOver);
            this.el.addEventListener("dragleave", this.onDragLeave);
            this.el.addEventListener("drop", this.onDrop);
          },
          destroyed() {
            const input = document.getElementById(this.el.dataset.inputId);
            input?.removeEventListener("change", this.onInputChange);
            this.el.removeEventListener("dragover", this.onDragOver);
            this.el.removeEventListener("dragleave", this.onDragLeave);
            this.el.removeEventListener("drop", this.onDrop);
          }
        }
      </script>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Connected accounts
  # ---------------------------------------------------------------------------

  defp connected_accounts_page(assigns) do
    ~H"""
    <div class="profile-page">
      <div class="profile-page-header">
        <h1 class="profile-page-title">{gettext("Connections")}</h1>
        <p class="profile-page-description">
          {gettext("Manage third-party services connected to your Glossia account.")}
        </p>
      </div>

      <.resource_table id="connections" rows={@identities}>
        <:col :let={identity} label={gettext("Provider")}>
          {String.capitalize(identity.provider)}
        </:col>
        <:col :let={identity} label={gettext("Account")}>
          {identity.provider_uid}
        </:col>
        <:empty>
          <p>
            {gettext("No connections yet. Connect a third-party service by signing in through it.")}
          </p>
        </:empty>
      </.resource_table>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp resolve_avatar_display_url(avatar_url, _fallback)
       when is_binary(avatar_url) and avatar_url != "" do
    case Regex.run(~r{^avatars/users/([^/.]+)}, avatar_url) do
      [_, user_id] -> "/avatars/users/#{user_id}"
      _ -> avatar_url
    end
  end

  defp resolve_avatar_display_url(_avatar_url, fallback), do: fallback

  defp gravatar_url(email) do
    hash =
      :crypto.hash(:md5, String.downcase(String.trim(email)))
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=128&d=identicon"
  end
end
