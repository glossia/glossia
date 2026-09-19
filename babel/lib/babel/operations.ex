defmodule Babel.Operations do
  @moduledoc """
  The operational work queue and summary data shown in Babel.
  """

  import Ecto.Query

  alias Babel.Operations.WorkItem
  alias Babel.Repo

  def list_work_items do
    WorkItem
    |> order_by([work_item], asc: work_item.due_on, asc: work_item.inserted_at)
    |> Repo.all()
  end

  def list_work_items(area) do
    WorkItem
    |> where([work_item], work_item.area == ^area)
    |> order_by([work_item], asc: work_item.due_on, asc: work_item.inserted_at)
    |> Repo.all()
  end

  def dashboard do
    work_items = list_work_items()

    %{
      work_items: work_items,
      open_count: Enum.count(work_items, &(&1.status != "Done")),
      blocked_count: Enum.count(work_items, &(&1.status == "Blocked")),
      due_this_week_count: Enum.count(work_items, &due_this_week?(&1.due_on)),
      completed_count: Enum.count(work_items, &(&1.status == "Done"))
    }
  end

  defp due_this_week?(nil), do: false

  defp due_this_week?(due_on) do
    today = Date.utc_today()
    week_end = Date.add(today, 7)

    Date.compare(due_on, today) in [:eq, :gt] and Date.compare(due_on, week_end) in [:eq, :lt]
  end
end
