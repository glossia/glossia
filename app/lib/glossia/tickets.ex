defmodule Glossia.Tickets do
  @moduledoc false

  alias Glossia.Discussions

  def list_tickets(account, params \\ %{}), do: Discussions.list_discussions(account, params)
  defdelegate list_tickets(account, project, params), to: Discussions, as: :list_discussions
  def list_all_tickets(params \\ %{}), do: Discussions.list_all_discussions(params)
  defdelegate get_ticket!(id), to: Discussions, as: :get_discussion!
  defdelegate get_ticket(id), to: Discussions, as: :get_discussion
  defdelegate get_ticket!(id, account_id), to: Discussions, as: :get_discussion!

  defdelegate get_ticket_by_number!(number, account_id),
    to: Discussions,
    as: :get_discussion_by_number!

  defdelegate create_ticket(account, user, attrs), to: Discussions, as: :create_discussion
  defdelegate close_ticket(ticket, user), to: Discussions, as: :close_discussion
  defdelegate reopen_ticket(ticket, user), to: Discussions, as: :reopen_discussion
  defdelegate add_comment(ticket, user, attrs), to: Discussions, as: :add_comment
  def change_ticket(attrs \\ %{}), do: Discussions.change_discussion(attrs)
  def change_comment(attrs \\ %{}), do: Discussions.change_comment(attrs)
end
