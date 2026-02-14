defmodule GlossiaWeb.Api.OrganizationApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts

  def create(conn, params) do
    user = conn.assigns[:current_user]

    unless user do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "unauthorized"})
      |> halt()
    end

    handle = params["handle"]
    name = params["name"] || handle

    case Accounts.create_organization(user, %{"handle" => handle, "name" => name}) do
      {:ok, %{account: account, organization: org}} ->
        conn
        |> put_status(:created)
        |> json(%{handle: account.handle, name: org.name, type: "organization"})

      {:error, :account, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})

      {:error, _step, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
