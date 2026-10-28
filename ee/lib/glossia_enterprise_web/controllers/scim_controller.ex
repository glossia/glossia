# Adapted from Tuist's SCIM controllers, Copyright (c) 2025 Tuist GmbH.
# FCL-1.0-MIT; see ee/licenses/TUIST-FCL-1.0-MIT.md.
defmodule GlossiaEnterpriseWeb.SCIMController do
  use GlossiaWeb, :controller
  alias GlossiaEnterprise.SCIM
  alias GlossiaEnterprise.SCIM.Protocol

  def users(conn, params) do
    with {:ok, filter} <- Protocol.filter(params["filter"]),
         {:ok, start, count} <- Protocol.pagination(params),
         {:ok, page} <- SCIM.list_users(conn.assigns.scim_organization, filter, start, count) do
      resources = Enum.map(page.rows, &Protocol.render_user/1)
      Protocol.send_json(conn, 200, Protocol.render_list(resources, page.total, page.start_index))
    else
      error -> failure(conn, error)
    end
  end

  def user(conn, %{"id" => id}),
    do: respond(conn, SCIM.get_user(conn.assigns.scim_organization, id), :user)

  def create_user(conn, params) do
    with {:ok, attrs} <- Protocol.user_attrs(params, true),
         {:ok, resource} <- SCIM.provision_user(conn.assigns.scim_organization, attrs) do
      conn
      |> put_resp_header("location", Protocol.location(:user, resource.user.id))
      |> Protocol.send_json(201, Protocol.render_user(resource))
    else
      error -> failure(conn, error)
    end
  end

  def replace_user(conn, %{"id" => id} = params) do
    with {:ok, attrs} <- Protocol.user_attrs(params, true) do
      respond(conn, SCIM.update_user(conn.assigns.scim_organization, id, attrs), :user)
    else
      error -> failure(conn, error)
    end
  end

  def patch_user(conn, %{"id" => id} = params) do
    with {:ok, attrs} <- Protocol.user_patch(params) do
      respond(conn, SCIM.update_user(conn.assigns.scim_organization, id, attrs), :user)
    else
      error -> failure(conn, error)
    end
  end

  def delete_user(conn, %{"id" => id}) do
    case SCIM.deactivate_user(conn.assigns.scim_organization, id) do
      {:ok, _} -> send_resp(conn, 204, "")
      error -> failure(conn, error)
    end
  end

  def groups(conn, params) do
    with {:ok, filter} <- Protocol.filter(params["filter"]),
         true <- is_nil(filter) or elem(filter, 0) == "displayname",
         {:ok, start, count} <- Protocol.pagination(params) do
      groups = SCIM.list_groups(conn.assigns.scim_organization)

      groups =
        if filter,
          do:
            Enum.filter(
              groups,
              &(String.downcase(&1.display_name) == String.downcase(elem(filter, 1)))
            ),
          else: groups

      resources =
        groups |> Enum.drop(start - 1) |> Enum.take(count) |> Enum.map(&Protocol.render_group/1)

      Protocol.send_json(conn, 200, Protocol.render_list(resources, length(groups), start))
    else
      false -> failure(conn, {:error, :invalid_filter})
      error -> failure(conn, error)
    end
  end

  def group(conn, %{"id" => id}),
    do: respond(conn, SCIM.get_group(conn.assigns.scim_organization, id), :group)

  def patch_group(conn, %{"id" => id} = params) do
    with {:ok, operations} <- Protocol.group_patch(params) do
      respond(conn, SCIM.patch_group(conn.assigns.scim_organization, id, operations), :group)
    else
      error -> failure(conn, error)
    end
  end

  defp respond(conn, {:ok, resource}, type) do
    body =
      if type == :user, do: Protocol.render_user(resource), else: Protocol.render_group(resource)

    Protocol.send_json(conn, 200, body)
  end

  defp respond(conn, error, _), do: failure(conn, error)

  defp failure(conn, {:error, :not_found}), do: Protocol.error(conn, 404, "Resource not found")

  defp failure(conn, {:error, :email_taken}),
    do:
      Protocol.error(conn, 409, "Email belongs to a user outside this organization", "uniqueness")

  defp failure(conn, {:error, :invalid_filter}),
    do: Protocol.error(conn, 400, "Unsupported filter", "invalidFilter")

  defp failure(conn, {:error, :invalid_path}),
    do: Protocol.error(conn, 400, "Unsupported PATCH operation or path", "invalidPath")

  defp failure(conn, {:error, :mutability}),
    do:
      Protocol.error(
        conn,
        400,
        "userName is immutable; change email through the user's account",
        "mutability"
      )

  defp failure(conn, {:error, :last_admin}),
    do:
      Protocol.error(
        conn,
        409,
        "Cannot remove the last organization administrator",
        "invalidValue"
      )

  defp failure(conn, {:error, %Ecto.Changeset{} = changeset}) do
    if Enum.any?(changeset.errors, fn {_, {_, opts}} -> opts[:constraint] == :unique end),
      do: Protocol.error(conn, 409, "Resource already exists", "uniqueness"),
      else: Protocol.error(conn, 400, "Invalid user attributes", "invalidValue")
  end

  defp failure(conn, _), do: Protocol.error(conn, 400, "Invalid SCIM request", "invalidValue")
end
