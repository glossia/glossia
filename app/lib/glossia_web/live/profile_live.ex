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

  defp apply_action(socket, :preferences) do
    user = socket.assigns.current_user

    assign(socket,
      page_title: gettext("Preferences"),
      breadcrumb_label: gettext("Preferences"),
      selected_locale: user.locale || socket.assigns.locale
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

  def handle_event("select_locale", params, socket) do
    case noora_select_value(params) do
      nil -> {:noreply, socket}
      locale -> {:noreply, assign(socket, :selected_locale, locale)}
    end
  end

  def handle_event("save_locale", _params, socket) do
    case Glossia.Accounts.update_user_locale(
           socket.assigns.current_user,
           socket.assigns.selected_locale
         ) do
      {:ok, updated_user} ->
        # The new language only reaches the layout and the flash once this
        # process renders with it, so apply it before replying.
        Gettext.put_locale(GlossiaWeb.Gettext, updated_user.locale)

        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:locale, updated_user.locale)
         |> put_flash(:info, gettext("Language updated."))
         |> push_navigate(to: ~p"/-/settings/preferences")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not update your language."))}
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
      <% :preferences -> %>
        <.preferences_page selected_locale={@selected_locale} current_user={@current_user} />
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
      <.page_header
        title={gettext("Profile")}
        description={gettext("Manage your personal profile and account information.")}
      />

      <div class="noora-resource-list">
        <Noora.Card.card class="noora-resource-card" title={gettext("Avatar")} icon="user">
          <Noora.Card.card_section class="profile-avatar-card">
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
                <Noora.Avatar.avatar
                  id="profile-avatar"
                  image_href={@user_avatar_url}
                  name={@current_user.name || @current_user.email}
                  size="2xlarge"
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
          </Noora.Card.card_section>
        </Noora.Card.card>

        <.form
          for={@profile_form}
          id="profile-form"
          class="voice-form profile-form"
          phx-submit="save_profile"
          phx-change="validate_profile"
        >
          <Noora.Card.card
            class="noora-resource-card"
            title={gettext("Personal information")}
            icon="user"
          >
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <Noora.TextInput.text_input
                  id="profile-email"
                  name="profile[email]"
                  value={@current_user.email}
                  type="email"
                  label={gettext("Email")}
                  hint={gettext("Email cannot be changed here.")}
                  disabled
                />

                <Noora.TextInput.text_input
                  id="profile-name"
                  name="profile[name]"
                  value={@profile_form[:name].value}
                  label={gettext("Name")}
                  placeholder={gettext("Your display name")}
                />

                <Noora.TextArea.text_area
                  id="profile-bio"
                  name="profile[bio]"
                  value={@profile_form[:bio].value}
                  label={gettext("Bio")}
                  rows={4}
                  max_length={500}
                  show_character_count={false}
                  placeholder={gettext("A short description about yourself")}
                />
              </div>
            </Noora.Card.card_section>
          </Noora.Card.card>

          <Noora.Card.card
            class="noora-resource-card"
            title={gettext("Social links")}
            icon="link_icon"
          >
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <Noora.TextInput.text_input
                  id="profile-github-url"
                  name="profile[github_url]"
                  value={@profile_form[:github_url].value}
                  label={gettext("GitHub")}
                  input_type="url"
                  placeholder="https://github.com/username"
                />

                <Noora.TextInput.text_input
                  id="profile-x-url"
                  name="profile[x_url]"
                  value={@profile_form[:x_url].value}
                  label={gettext("X (Twitter)")}
                  input_type="url"
                  placeholder="https://x.com/username"
                />

                <Noora.TextInput.text_input
                  id="profile-linkedin-url"
                  name="profile[linkedin_url]"
                  value={@profile_form[:linkedin_url].value}
                  label={gettext("LinkedIn")}
                  input_type="url"
                  placeholder="https://linkedin.com/in/username"
                />

                <Noora.TextInput.text_input
                  id="profile-mastodon-url"
                  name="profile[mastodon_url]"
                  value={@profile_form[:mastodon_url].value}
                  label={gettext("Mastodon")}
                  input_type="url"
                  placeholder="https://mastodon.social/@username"
                />
              </div>
            </Noora.Card.card_section>
          </Noora.Card.card>

          <.form_save_bar
            id="profile-save-bar"
            visible={@profile_changed?}
            cancel_path={~p"/-/settings/profile"}
          />
        </.form>
      </div>
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
  # Page: Preferences
  # ---------------------------------------------------------------------------

  defp preferences_page(assigns) do
    ~H"""
    <div class="profile-page">
      <.page_header
        title={gettext("Preferences")}
        description={gettext("Choose how Glossia behaves for your account.")}
      />

      <div class="noora-resource-list">
        <.form for={%{}} id="preferences-form" class="voice-form" phx-submit="save_locale">
          <Noora.Card.card class="noora-resource-card" title={gettext("Language")} icon="language">
            <Noora.Card.card_section class="voice-card">
              <div class="voice-card-fields">
                <Noora.Select.select
                  id="preferences-locale-select"
                  name="locale"
                  label={gettext("Dashboard language")}
                  hint={
                    gettext(
                      "Applies to the dashboard. Anything not translated yet falls back to English."
                    )
                  }
                  value={@selected_locale}
                  on_value_change="select_locale"
                >
                  <:item
                    :for={locale <- Glossia.I18n.locales()}
                    value={locale}
                    label={Glossia.I18n.native_name(locale)}
                  />
                </Noora.Select.select>
              </div>
            </Noora.Card.card_section>
          </Noora.Card.card>

          <.form_save_bar
            id="preferences-save-bar"
            visible={@selected_locale != @current_user.locale}
            cancel_path={~p"/-/settings/preferences"}
          />
        </.form>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Page: Connected accounts
  # ---------------------------------------------------------------------------

  defp connected_accounts_page(assigns) do
    ~H"""
    <div class="profile-page">
      <.page_header
        title={gettext("Connections")}
        description={gettext("Manage third-party services connected to your Glossia account.")}
      />

      <Noora.Card.card_section class="noora-settings-list-card">
        <Noora.Table.table
          id="connections"
          rows={@identities}
          row_key={fn identity -> "connection-#{identity.provider}-#{identity.provider_uid}" end}
        >
          <:col :let={identity} label={gettext("Provider")}>
            <Noora.Table.text_cell icon="link_icon" label={String.capitalize(identity.provider)} />
          </:col>
          <:col :let={identity} label={gettext("Account")}>
            <Noora.Table.tag_cell label={identity.provider_uid} />
          </:col>
          <:empty_state>
            <Noora.Table.table_empty_state>
              <.noora_empty_state
                icon="link_icon"
                title={gettext("No connections yet")}
                subtitle={gettext("Connections will show up here after you sign in with a provider.")}
              />
            </Noora.Table.table_empty_state>
          </:empty_state>
        </Noora.Table.table>
      </Noora.Card.card_section>
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
