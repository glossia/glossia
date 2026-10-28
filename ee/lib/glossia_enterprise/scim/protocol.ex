# Adapted from Tuist's SCIM implementation, Copyright (c) 2025 Tuist GmbH.
# FCL-1.0-MIT; see ee/licenses/TUIST-FCL-1.0-MIT.md.
defmodule GlossiaEnterprise.SCIM.Protocol do
  @moduledoc "SCIM resource encoding and the supported RFC 7644 request subset."
  use GlossiaWeb, :verified_routes

  @user_schema "urn:ietf:params:scim:schemas:core:2.0:User"
  @group_schema "urn:ietf:params:scim:schemas:core:2.0:Group"
  @list_schema "urn:ietf:params:scim:api:messages:2.0:ListResponse"
  @patch_schema "urn:ietf:params:scim:api:messages:2.0:PatchOp"

  def user_schema, do: @user_schema
  def group_schema, do: @group_schema

  def location(type, id) do
    path =
      case type do
        :user -> ~p"/scim/v2/Users/#{id}"
        :group -> ~p"/scim/v2/Groups/#{id}"
      end

    GlossiaWeb.Endpoint.url() |> URI.merge(path) |> URI.to_string()
  end

  def render_user(%{user: user, membership: membership, provisioning: provisioning}) do
    %{
      schemas: [@user_schema],
      id: user.id,
      userName: user.email,
      externalId: provisioning && provisioning.external_id,
      displayName: (provisioning && provisioning.display_name) || user.name || user.email,
      active: not is_nil(membership) and (is_nil(provisioning) or provisioning.active),
      emails: [%{value: user.email, primary: true, type: "work"}],
      roles: if(membership, do: [%{value: membership.role}], else: []),
      meta: %{
        resourceType: "User",
        location: location(:user, user.id),
        created: DateTime.to_iso8601(user.inserted_at),
        lastModified:
          DateTime.to_iso8601(
            if(provisioning, do: provisioning.updated_at, else: user.updated_at)
          )
      }
    }
  end

  def render_group(group) do
    %{
      schemas: [@group_schema],
      id: group.id,
      displayName: group.display_name,
      members:
        Enum.map(
          group.members,
          &%{value: &1.id, display: &1.email, "$ref": location(:user, &1.id)}
        ),
      meta: %{resourceType: "Group", location: location(:group, group.id)}
    }
  end

  def render_list(resources, total, start_index) do
    %{
      schemas: [@list_schema],
      totalResults: total,
      startIndex: start_index,
      itemsPerPage: length(resources),
      Resources: resources
    }
  end

  def send_json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/scim+json")
    |> Plug.Conn.put_resp_header("cache-control", "no-store")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end

  def error(conn, status, detail, type \\ nil) do
    body = %{
      schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
      status: to_string(status),
      detail: detail
    }

    send_json(conn, status, if(type, do: Map.put(body, :scimType, type), else: body))
  end

  def filter(nil), do: {:ok, nil}
  def filter(""), do: {:ok, nil}

  def filter(expression) when is_binary(expression) do
    case Regex.run(~r/^\s*([a-z][a-z0-9]*)\s+eq\s+("(?:[^"\\]|\\.)*")\s*$/i, expression) do
      [_, attribute, encoded] ->
        case Jason.decode(encoded) do
          {:ok, value} when is_binary(value) -> {:ok, {String.downcase(attribute), value}}
          _ -> {:error, :invalid_filter}
        end

      _ ->
        {:error, :invalid_filter}
    end
  end

  def filter(_), do: {:error, :invalid_filter}

  def pagination(params) do
    with {:ok, start} <- integer(params["startIndex"], 1),
         {:ok, count} <- integer(params["count"], 100) do
      {:ok, max(start, 1), min(max(count, 0), 200)}
    end
  end

  defp integer(nil, default), do: {:ok, default}

  defp integer(value, _) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :invalid_value}
    end
  end

  defp integer(_, _), do: {:error, :invalid_value}

  def user_attrs(params, require_name \\ false) do
    with true <- not require_name or Map.has_key?(params, "userName"),
         true <-
           not Map.has_key?(params, "schemas") or @user_schema in List.wrap(params["schemas"]) do
      Enum.reduce_while(
        Map.take(params, ~w(userName displayName externalId active roles)),
        {:ok, %{}},
        fn {key, value}, {:ok, attrs} ->
          case attribute(key, value) do
            {:ok, key, value} -> {:cont, {:ok, Map.put(attrs, key, value)}}
            error -> {:halt, error}
          end
        end
      )
    else
      _ -> {:error, :invalid_value}
    end
  end

  defp attribute("userName", value) when is_binary(value) do
    if byte_size(value) <= 254 and
         Regex.match?(~r/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/, String.trim(value)),
       do: {:ok, :user_name, String.downcase(String.trim(value))},
       else: {:error, :invalid_value}
  end

  defp attribute("displayName", value) when is_binary(value) and byte_size(value) <= 255,
    do: {:ok, :display_name, value}

  defp attribute("externalId", value) when is_binary(value) and byte_size(value) <= 255,
    do: {:ok, :external_id, value}

  defp attribute("active", value) when is_boolean(value), do: {:ok, :active, value}

  defp attribute("roles", [%{"value" => value}]) when value in ["admin", "member", "linguist"],
    do: {:ok, :role, value}

  defp attribute(_, _), do: {:error, :invalid_value}

  def user_patch(params) do
    with {:ok, operations} <- operations(params) do
      Enum.reduce_while(operations, {:ok, %{}}, fn operation, {:ok, attrs} ->
        case user_operation(operation) do
          {:ok, changes} -> {:cont, {:ok, Map.merge(attrs, changes)}}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp user_operation(%{"op" => operation, "value" => value} = params)
       when is_binary(operation) do
    if String.downcase(operation) in ["add", "replace"] do
      case params["path"] do
        nil when is_map(value) ->
          if Enum.all?(
               Map.keys(value),
               &(&1 in ~w(userName displayName externalId active roles))
             ), do: user_attrs(value), else: {:error, :invalid_path}

        path when is_binary(path) ->
          case Enum.find(
                 ~w(userName displayName externalId active roles),
                 &(String.downcase(&1) == String.downcase(path))
               ) do
            nil -> {:error, :invalid_path}
            field -> user_attrs(%{field => value})
          end

        _ ->
          {:error, :invalid_path}
      end
    else
      {:error, :invalid_path}
    end
  end

  defp user_operation(_), do: {:error, :invalid_value}

  def group_patch(params) do
    with {:ok, operations} <- operations(params) do
      Enum.reduce_while(operations, {:ok, []}, fn operation, {:ok, acc} ->
        case group_operation(operation) do
          {:ok, parsed} -> {:cont, {:ok, acc ++ [parsed]}}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp operations(%{"schemas" => schemas, "Operations" => operations})
       when is_list(schemas) and is_list(operations) and length(operations) in 1..100 do
    if @patch_schema in schemas, do: {:ok, operations}, else: {:error, :invalid_value}
  end

  defp operations(_), do: {:error, :invalid_value}

  defp group_operation(%{"op" => op} = params) when is_binary(op) do
    op = String.downcase(op)
    path = params["path"]

    cond do
      op in ["add", "replace", "remove"] and path in [nil, "members"] ->
        values =
          case params["value"] do
            %{"members" => members} -> members
            members -> members
          end

        if is_list(values) and
             Enum.all?(values, &match?(%{"value" => value} when is_binary(value), &1)),
           do: {:ok, {op, Enum.map(values, & &1["value"])}},
           else: {:error, :invalid_value}

      op == "remove" and is_binary(path) ->
        case Regex.run(~r/^members\[value eq "([^"]+)"\]$/i, path) do
          [_, id] -> {:ok, {op, [id]}}
          _ -> {:error, :invalid_path}
        end

      true ->
        {:error, :invalid_path}
    end
  end

  defp group_operation(_), do: {:error, :invalid_value}
end
