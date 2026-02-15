defmodule Glossia.Support.Ticket do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:title, :type, :status],
    sortable: [:number, :title, :status, :inserted_at],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  schema "tickets" do
    field :number, :integer
    field :title, :string
    field :description, :string
    field :type, :string, default: "issue"
    field :status, :string, default: "open"
    field :resolved_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :user, Glossia.Accounts.User
    belongs_to :resolved_by, Glossia.Accounts.User

    has_many :messages, Glossia.Support.TicketMessage

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :description, :type])
    |> validate_required([:title, :description, :type])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_inclusion(:type, ~w(issue request))
  end

  def status_changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:status, :resolved_at, :resolved_by_id])
    |> validate_inclusion(:status, ~w(open in_progress resolved implemented))
  end
end
