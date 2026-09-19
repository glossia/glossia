defmodule Babel.MCP.WorkItemSerializer do
  @moduledoc false

  def serialize(work_item) do
    %{
      id: work_item.id,
      area: work_item.area,
      assignee: work_item.assignee,
      due_on: serialize_date(work_item.due_on),
      priority: work_item.priority,
      status: work_item.status,
      summary: work_item.summary
    }
  end

  defp serialize_date(nil), do: nil
  defp serialize_date(due_on), do: Date.to_iso8601(due_on)
end
