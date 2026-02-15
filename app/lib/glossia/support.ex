defmodule Glossia.Support do
  @moduledoc """
  Context for managing support tickets and ticket messages.
  """

  import Ecto.Query

  alias Glossia.Repo
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Support.{Ticket, TicketMessage}

  # --- Tickets ---

  def list_tickets(%Account{} = account, params \\ %{}) do
    query =
      from t in Ticket,
        where: t.account_id == ^account.id,
        preload: [:user]

    Flop.validate_and_run(query, params, for: Ticket)
  end

  def list_all_tickets(params \\ %{}) do
    query =
      from t in Ticket,
        preload: [:user, :account]

    Flop.validate_and_run(query, params, for: Ticket)
  end

  def get_ticket!(id) do
    Repo.one!(
      from t in Ticket,
        where: t.id == ^id,
        preload: [:user, :account, :resolved_by, messages: :user]
    )
  end

  def get_ticket!(id, account_id) do
    Repo.one!(
      from t in Ticket,
        where: t.id == ^id and t.account_id == ^account_id,
        preload: [:user, :account, :resolved_by, messages: :user]
    )
  end

  def create_ticket(%Account{} = account, %User{} = user, attrs) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Ecto.Changeset.put_change(:account_id, account.id)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert()
  end

  def update_ticket_status(%Ticket{} = ticket, status, resolved_by \\ nil) do
    attrs =
      if status in ~w(resolved implemented) and resolved_by do
        %{status: status, resolved_at: DateTime.utc_now(), resolved_by_id: resolved_by.id}
      else
        %{status: status}
      end

    ticket
    |> Ticket.status_changeset(attrs)
    |> Repo.update()
  end

  # --- Ticket Messages ---

  def add_message(%Ticket{} = ticket, %User{} = user, attrs, opts \\ []) do
    is_staff = Keyword.get(opts, :is_staff, false)

    %TicketMessage{}
    |> TicketMessage.changeset(attrs)
    |> Ecto.Changeset.put_change(:ticket_id, ticket.id)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Ecto.Changeset.put_change(:is_staff, is_staff)
    |> Repo.insert()
  end

  def change_ticket(attrs \\ %{}) do
    Ticket.changeset(%Ticket{}, attrs)
  end

  def change_message(attrs \\ %{}) do
    TicketMessage.changeset(%TicketMessage{}, attrs)
  end
end
