defmodule Glossia.MCP.UpdateOrganizationTool do
  @moduledoc "Update an organization's name or visibility."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :name, :string, description: "New display name."
    field :visibility, :string, description: "New visibility (private or public)."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]

      case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
        nil ->
          {:error, Error.execution("Organization '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:org_write, user, account) do
            :ok ->
              org = Accounts.get_organization_for_account(account)
              update_attrs = Map.take(params, ["name", "visibility"])

              case Accounts.update_organization(org, update_attrs) do
                {:ok, org} ->
                  response =
                    Response.tool()
                    |> Response.text(
                      Jason.encode!(%{
                        handle: org.account.handle,
                        name: org.name,
                        type: "organization",
                        visibility: org.account.visibility
                      })
                    )

                  {:reply, response, frame}

                {:error, changeset} ->
                  errors = format_errors(changeset)
                  {:error, Error.execution("Update failed: #{errors}"), frame}
              end

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to update '#{handle}'"), frame}
          end
      end
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join(", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
  end
end
