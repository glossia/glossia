defmodule Glossia.Support do
  @moduledoc """
  Context for managing support tickets and ticket messages.
  """

  require OpenTelemetry.Tracer, as: Tracer

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

  def get_ticket_by_number!(number, account_id) do
    Repo.one!(
      from t in Ticket,
        where: t.number == ^number and t.account_id == ^account_id,
        preload: [:user, :account, :resolved_by, messages: :user]
    )
  end

  def create_ticket(%Account{} = account, %User{} = user, attrs) do
    Tracer.with_span "glossia.support.create_ticket" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account.id)},
        {"glossia.user.id", to_string(user.id)},
        {"glossia.ticket.type", to_string(attrs["type"] || attrs[:type] || "")}
      ])

      next_number =
        (Repo.one(from t in Ticket, where: t.account_id == ^account.id, select: max(t.number)) ||
           0) + 1

      %Ticket{}
      |> Ticket.changeset(attrs)
      |> Ecto.Changeset.put_change(:account_id, account.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:number, next_number)
      |> Repo.insert()
      |> case do
        {:ok, ticket} = ok ->
          Tracer.set_attributes([{"glossia.ticket.number", ticket.number}])
          ok

        other ->
          other
      end
    end
  end

  def update_ticket_status(%Ticket{} = ticket, status, resolved_by \\ nil) do
    Tracer.with_span "glossia.support.update_ticket_status" do
      Tracer.set_attributes([
        {"glossia.ticket.id", to_string(ticket.id)},
        {"glossia.ticket.status", to_string(status)},
        {"glossia.resolved_by.id",
         if(match?(%User{}, resolved_by), do: to_string(resolved_by.id), else: "")}
      ])

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
  end

  # --- Ticket Messages ---

  def add_message(%Ticket{} = ticket, %User{} = user, attrs, opts \\ []) do
    is_staff = Keyword.get(opts, :is_staff, false)

    Tracer.with_span "glossia.support.add_message" do
      Tracer.set_attributes([
        {"glossia.ticket.id", to_string(ticket.id)},
        {"glossia.user.id", to_string(user.id)},
        {"glossia.ticket_message.is_staff", is_staff}
      ])

      %TicketMessage{}
      |> TicketMessage.changeset(attrs)
      |> Ecto.Changeset.put_change(:ticket_id, ticket.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:is_staff, is_staff)
      |> Repo.insert()
    end
  end

  def change_ticket(attrs \\ %{}) do
    Ticket.changeset(%Ticket{}, attrs)
  end

  def change_message(attrs \\ %{}) do
    TicketMessage.changeset(%TicketMessage{}, attrs)
  end
end
