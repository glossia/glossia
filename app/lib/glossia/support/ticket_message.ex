defmodule Glossia.Support.TicketMessage do
  use Glossia.Schema
  import Ecto.Changeset

  schema "ticket_messages" do
    field :body, :string
    field :is_staff, :boolean, default: false

    belongs_to :ticket, Glossia.Support.Ticket
    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
    |> validate_length(:body, min: 1)
  end
end
