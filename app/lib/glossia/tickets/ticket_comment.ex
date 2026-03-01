defmodule Glossia.Tickets.TicketComment do
  use Glossia.Schema
  import Ecto.Changeset

  schema "discussion_comments" do
    field :body, :string

    belongs_to :ticket, Glossia.Tickets.Ticket, foreign_key: :discussion_id
    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> validate_required([:body])
    |> validate_length(:body, min: 1)
  end
end
