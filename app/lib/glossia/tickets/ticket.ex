defmodule Glossia.Tickets.Ticket do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:title, :status, :kind, :inserted_at],
    sortable: [:number, :title, :status, :kind, :inserted_at],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  @kinds ~w(general voice_suggestion glossary_suggestion)

  schema "discussions" do
    field :number, :integer
    field :title, :string
    field :body, :string
    field :status, :string, default: "open"
    field :kind, :string, default: "general"
    field :metadata, :map, default: %{}
    field :closed_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :project, Glossia.Accounts.Project
    belongs_to :user, Glossia.Accounts.User
    belongs_to :closed_by, Glossia.Accounts.User

    has_many :comments, Glossia.Tickets.TicketComment, foreign_key: :discussion_id

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :body, :project_id, :kind, :metadata])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_inclusion(:kind, @kinds)
  end
end
