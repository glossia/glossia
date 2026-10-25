defmodule Glossia.Push.Prune do
  @moduledoc false
  use Oban.Worker, queue: :push, max_attempts: 1

  @impl Oban.Worker
  def perform(_job), do: Glossia.Push.prune()
end
