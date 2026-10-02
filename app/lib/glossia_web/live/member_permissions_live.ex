defmodule GlossiaWeb.MemberPermissionsLive do
  use GlossiaWeb, :live_view
  import GlossiaWeb.DashboardComponents, only: [page_header: 1]
  import Noora.Card
  alias Glossia.{Accounts, MemberPermissions, Organizations}

  def mount(params, _session, socket) do
    organization = Organizations.get_organization_for_account(socket.assigns.account)

    user =
      case Ecto.UUID.cast(params["user_id"]) do
        {:ok, id} -> Accounts.get_user(id)
        :error -> nil
      end

    membership = user && Organizations.get_membership(organization, user)

    unless (Glossia.Roles.has_organization_role?(
              socket.assigns.current_user,
              organization,
              "admin"
            ) and membership) && membership.role != "admin",
           do: raise(Ecto.NoResultsError, queryable: Glossia.Accounts.OrganizationMembership)

    scopes = membership.scopes || legacy_scopes(user, socket.assigns.account)

    {:ok,
     assign(socket,
       organization: organization,
       member: user,
       scopes: scopes,
       groups: MemberPermissions.groups(),
       page_title: gettext("Member permissions"),
       breadcrumb_items: [{gettext("Members"), ~p"/#{socket.assigns.handle}/-/members"}]
     )}
  end

  defp legacy_scopes(user, account) do
    Glossia.Policy.list_rules()
    |> Enum.filter(&Glossia.Authz.authorize?(&1.name, user, account))
    |> Enum.map(&Glossia.Authz.required_scope(&1.name))
    |> Enum.filter(&(&1 in MemberPermissions.available_scopes()))
  end

  def handle_event(event, %{"checked" => checked}, socket) when checked in ["true", "false"] do
    handle_event(event, %{"checked" => checked == "true"}, socket)
  end

  def handle_event("set_scope:" <> scope, %{"checked" => checked}, socket)
      when is_boolean(checked) do
    if scope in MemberPermissions.available_scopes() do
      scopes =
        if checked,
          do: Enum.uniq([scope | socket.assigns.scopes]),
          else: List.delete(socket.assigns.scopes, scope)

      {:noreply, assign(socket, :scopes, scopes)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_group:" <> group, %{"checked" => checked}, socket)
      when is_boolean(checked) do
    case List.keyfind(socket.assigns.groups, group, 0) do
      {_, scopes} ->
        selected = socket.assigns.scopes
        updated = if checked, do: Enum.uniq(selected ++ scopes), else: selected -- scopes
        {:noreply, assign(socket, :scopes, updated)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("save", _, socket) do
    case MemberPermissions.update(
           socket.assigns.organization,
           socket.assigns.current_user,
           socket.assigns.member,
           socket.assigns.scopes
         ) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, gettext("Member permissions saved."))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not save member permissions."))}
    end
  end

  defp group_label("llm_model"), do: gettext("Language models")
  defp group_label("api_credentials"), do: gettext("Access credentials")
  defp group_label(group), do: group |> String.replace("_", " ") |> String.capitalize()

  def render(assigns) do
    ~H"""
    <div id="member-permissions">
      <div data-part="action-buttons">
        <Noora.Button.button
          navigate={~p"/#{@handle}/-/members"}
          variant="secondary"
          size="medium"
          label={gettext("Members")}
        >
          <:icon_left><Noora.Icon.arrow_left /></:icon_left>
        </Noora.Button.button>
        <Noora.Button.button
          type="button"
          size="medium"
          phx-click="save"
          label={gettext("Save permissions")}
        />
      </div>
      <.page_header title={gettext("Member permissions")} description={@member.email} />
      <p>
        {gettext(
          "Select permissions individually or select a whole area. New members start with basic read access."
        )}
      </p>
      <.card title={gettext("Permissions")} icon="lock_password">
        <.card_section data-part="permission-areas">
          <section
            :for={{group, scopes} <- @groups}
            data-part="permission-group"
            aria-labelledby={"permission-area-#{group}"}
          >
            <h3 id={"permission-area-#{group}"}>{group_label(group)}</h3>
            <Noora.Checkbox.checkbox
              id={"permission-group-#{group}-#{Enum.count(scopes, &(&1 in @scopes))}"}
              label={gettext("Select all")}
              checked={Enum.all?(scopes, &(&1 in @scopes))}
              indeterminate={
                Enum.any?(scopes, &(&1 in @scopes)) and not Enum.all?(scopes, &(&1 in @scopes))
              }
              data-default-checked={to_string(Enum.all?(scopes, &(&1 in @scopes)))}
              phx-click={"set_group:#{group}"}
              phx-value-checked={to_string(not Enum.all?(scopes, &(&1 in @scopes)))}
            />
            <div data-part="permissions">
              <Noora.Checkbox.checkbox
                :for={scope <- scopes}
                id={"permission-#{String.replace(scope, ":", "-")}-#{scope in @scopes}"}
                label={scope |> String.split(":") |> List.last() |> String.capitalize()}
                checked={scope in @scopes}
                data-default-checked={to_string(scope in @scopes)}
                phx-click={"set_scope:#{scope}"}
                phx-value-checked={to_string(scope not in @scopes)}
              />
            </div>
          </section>
        </.card_section>
      </.card>
    </div>
    """
  end
end
