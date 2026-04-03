defmodule GlossiaWeb.OrganizationController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Events
  alias Glossia.Organizations

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "organization_create",
         scale: :timer.hours(1),
         limit: 20,
         by: :user,
         format: :text
       ]
       when action in [:create]

  def new(conn, _params) do
    changeset = Accounts.Account.changeset(%Accounts.Account{}, %{})
    render(conn, :new, changeset: changeset, page_title: gettext("New organization"))
  end

  def create(conn, %{"account" => account_params}) do
    user = conn.assigns.current_user

    with :ok <- Glossia.Policy.authorize(:organization_write, user, nil) do
      case Organizations.create_organization(user, account_params) do
        {:ok, %{account: account, organization: org}} ->
          Events.emit("organization.created", account, user,
            resource_type: "organization",
            resource_id: to_string(org.id),
            resource_path: ~p"/#{account.handle}",
            summary: "Created organization \"#{account.handle}\""
          )

          redirect(conn, to: ~p"/#{account.handle}")

        {:error, :account, changeset, _} ->
          render(conn, :new, changeset: changeset, page_title: gettext("New organization"))

        {:error, _step, _changeset, _} ->
          changeset =
            Accounts.Account.changeset(%Accounts.Account{}, account_params)
            |> Ecto.Changeset.add_error(:handle, "could not create organization")

          render(conn, :new, changeset: changeset, page_title: gettext("New organization"))
      end
    else
      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, gettext("You don't have permission to do that."))
        |> redirect(to: ~p"/dashboard")
        |> halt()
    end
  end
end
