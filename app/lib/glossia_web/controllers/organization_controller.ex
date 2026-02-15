defmodule GlossiaWeb.OrganizationController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Organizations

  def new(conn, _params) do
    changeset = Accounts.Account.changeset(%Accounts.Account{}, %{})
    render(conn, :new, changeset: changeset, page_title: gettext("New organization"))
  end

  def create(conn, %{"account" => account_params}) do
    user = conn.assigns.current_user

    case Organizations.create_organization(user, account_params) do
      {:ok, %{account: account}} ->
        redirect(conn, to: "/#{account.handle}")

      {:error, :account, changeset, _} ->
        render(conn, :new, changeset: changeset, page_title: gettext("New organization"))

      {:error, _step, _changeset, _} ->
        changeset =
          Accounts.Account.changeset(%Accounts.Account{}, account_params)
          |> Ecto.Changeset.add_error(:handle, "could not create organization")

        render(conn, :new, changeset: changeset, page_title: gettext("New organization"))
    end
  end
end
